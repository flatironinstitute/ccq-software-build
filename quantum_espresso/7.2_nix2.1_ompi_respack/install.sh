#!/bin/bash

# installation script for QE with GNU OpenMPI toolchain

# load modules
MODULES="modules/2.1.1-20230405 gcc/10 openmpi/4 python/3.10 fftw intel-oneapi-mkl hdf5/mpi git libxc wannier90/dev_nix2.1_gnu_ompi"
module purge
module load ${MODULES}

export FFLAGS="-O3 -g -march=broadwell -fallow-argument-mismatch"

BUILDINFO=7.2_nix2.1_gnu_ompi_respack
BUILDDIR=/tmp/qe_${BUILDINFO}_build
mkdir $BUILDDIR

INSTALLDIR=$(pwd)/installation

MODULEDIR=$(git rev-parse --show-toplevel)/modules

# it seems that QE with configure has problems correctly resolving dependencies so stick to NCORES=1 for now
NCORES=4
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=1

#python interpreter header for wan2respack
PYTHON='#!'$(which python3)

log=build_$(date +%Y%m%d%H%M).log
testlog="$(pwd)/${log/.log/_test.log}"
(
    cd ${BUILDDIR}
    
    module list

    # clone version 7.1 from github
    git clone -b qe-7.2 --depth 1 https://github.com/QEF/q-e.git qe
    cd qe
    
    ./configure -enable-parallel=yes -with-scalapack=yes --with-libxc=yes --with-libxc-prefix=$LIBXC_ROOT -prefix=${INSTALLDIR}

    make -j$NCORES all
    make install
    rm ${INSTALLDIR}/bin/wannier90.x

    # unfolding code
    cd ${BUILDDIR}
    git clone --depth 1 https://bitbucket.org/bonfus/unfold-x.git 
    cd unfold-x
    sed -i 's+$(QE_ROOT)/FFTXlib/libqefft.a+$(QE_ROOT)/FFTXlib/src/libqefft.a +g' src/Makefile
    make QE_ROOT=${BUILDDIR}/qe
    cp bin/* ${INSTALLDIR}/bin/
    
    # Respack
    cd ${BUILDDIR}
    tar -xf ${INSTALLDIR}/../RESPACK-20200113.tar.gz
    cd RESPACK-20200113
    mkdir build && cd build
    cmake -DCONFIG=gcc -DBLA_VENDOR=Intel10_64lp_seq -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} ../
    make -j$NCORES
    make install

    # wan2respack
    cd ${BUILDDIR}
    git clone --depth 1 git@github.com:respack-dev/wan2respack.git wan2respack
    cd wan2respack
    # copy custom config file for cmake
    cp ${INSTALLDIR}/../wan2respack.cmake ${BUILDDIR}/wan2respack/config/gcc.cmake
    # add shebang to all *.py files
    sed -i "1s|^|$PYTHON \n|" util/wan2respack/*.py 
    mkdir build && cd build
    cmake ../ -DCONFIG=gcc -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}
    make
    make install

) &> ${log}

mkdir -p $MODULEDIR/quantum_espresso
# make the template a proper module
echo '#%Module' > $MODULEDIR/quantum_espresso/$BUILDINFO
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/quantum_espresso/$BUILDINFO

