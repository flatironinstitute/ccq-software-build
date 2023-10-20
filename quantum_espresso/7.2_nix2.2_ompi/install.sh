#!/bin/bash

# installation script for QE with GNU OpenMPI toolchain

# load modules
MODULES="modules/2.2-20230808 gcc/11.4.0 openmpi/4 fftw intel-oneapi-mkl hdf5/mpi git libxc wannier90/dev_nix2.2_gnu_ompi cmake"
module purge
module load ${MODULES}

export FFLAGS="-O3 -g -march=broadwell"

BUILDINFO=7.2_nix2.2_gnu_ompi
BUILDDIR=/tmp/qe_${BUILDINFO}_build
mkdir $BUILDDIR

INSTALLDIR=$(pwd)/installation

MODULEDIR=$(git rev-parse --show-toplevel)/modules

NCORES=12
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=1

log=build_$(date +%Y%m%d%H%M).log
testlog="$(pwd)/${log/.log/_test.log}"
(
    cd ${BUILDDIR}
    
    module list

    # clone from github
    git clone -b qe-7.2 --depth 1 https://github.com/QEF/q-e.git qe
    cd qe
    
    mkdir -p build && cd build
    
    cmake -D CMAKE_C_COMPILER=mpicc -D CMAKE_Fortran_COMPILER=mpif90 \
        -D CMAKE_VERBOSE_MAKEFILE=ON \
        -D BLA_VENDOR=Intel10_64lp_seq \
        -D CMAKE_INSTALL_PREFIX=${INSTALLDIR} \
        -D QE_ENABLE_HDF5=ON \
        -D QE_ENABLE_LIBXC=ON \
        -D QE_ENABLE_SCALAPACK=ON \
        -D QE_ENABLE_OPENMP=ON \
        -D QE_WANNIER90_INTERNAL=OFF \
        -D WANNIER90_ROOT=${WANNIER90_ROOT} \
        ../

# build all
    make -j$NCORES all

    # run tests
    ctest -j$NCORES &>> ${testlog}

    # install it
    make install
    cp bin/* ${INSTALLDIR}/bin/
) &> ${log}

mkdir -p $MODULEDIR/quantum_espresso
# make the template a proper module
echo '#%Module' > $MODULEDIR/quantum_espresso/$BUILDINFO
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/quantum_espresso/$BUILDINFO
