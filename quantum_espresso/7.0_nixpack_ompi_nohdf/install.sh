#!/bin/bash

# installation script for QE with GNU OpenMPI toolchain

# load modules
MODULES="modules/1.58-20220124 gcc/10 openmpi/4 fftw intel-oneapi-mkl hdf5/1.10.8-mpi git libxc wannier90/3.1_gnu_ompi cmake"
module purge
module load ${MODULES}

export FFLAGS="-O3 -g -march=broadwell"

BUILDINFO=7.0_gnu_ompi_nohdf
BUILDDIR=/dev/shm/qe_${BUILDINFO}_build
mkdir $BUILDDIR
INSTALLDIR="$(pwd)/installation"

NCORES=12

log=build_$(date +%Y%m%d%H%M).log
(
    cd ${BUILDDIR}
    
    module list

    # clone version 6.7 from github
    git clone -b qe-7.0 --depth 1 https://github.com/QEF/q-e.git qe
    cd qe
    
    ./configure -enable-parallel=yes -with-scalapack=yes --with-libxc=yes --with-libxc-prefix=$LIBXC_ROOT -prefix=${INSTALLDIR}

    make -j$NCORES all

    # install it
    make install

    # unfolding code
    cd ${BUILDDIR}
    git clone --depth 1 git clone git@bitbucket.org:bonfus/unfold-x.git 
    cd unfold-x
    sed -i 's+$(QE_ROOT)/clib/clib.a+ +g' src/Makefile
    make QE_ROOT=${BUILDDIR}/qe
    cp bin/* ${INSTALLDIR}/bin/
    
    # Respack
    tar -xf ${INSTALLDIR}/../RESPACK-20200113.tar.gz
    cd RESPACK-20200113
    mkdir build && cd build
    cmake -DCONFIG=gcc -DBLA_VENDOR=Intel10_64lp_seq -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} ../
    make -j$NCORES
    make install

) &> ${log}

mkdir -p ../../modules/quantum_espresso
# make the template a proper module 
echo '#%Module' > ../../modules/quantum_espresso/$BUILDINFO
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> ../../modules/quantum_espresso/$BUILDINFO

