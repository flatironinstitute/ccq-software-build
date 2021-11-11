#!/bin/bash

# installation script for QE with GNU OpenMPI toolchain

# load modules
MODULES="gcc/10 openmpi cmake hdf5/1.10.7-mpi intel-oneapi-mkl wannier90/3.1_gnu_ompi git libxc"
module purge
module load ${MODULES}

export FFLAGS="-O3 -g -march=broadwell"

BUILDDIR='/dev/shm/qe_build_nixpack_ompi'
mkdir $BUILDDIR
INSTALLDIR="$(pwd)/installation"

log=build_$(date +%Y%m%d%H%M).log
(
    cd ${BUILDDIR}
    
    module list

    # clone version 6.7 from github
    git clone -b qe-6.8 https://github.com/QEF/q-e.git qe
    cd qe
    
    mkdir -p build && cd build
    
    cmake -D CMAKE_C_COMPILER=mpicc -D CMAKE_Fortran_COMPILER=mpif90 \
        -D CMAKE_VERBOSE_MAKEFILE=ON \
        -D BLA_VENDOR=Intel10_64lp_seq \
        -D CMAKE_INSTALL_PREFIX=${INSTALLDIR} \
        -D QE_ENABLE_HDF5=ON \
        -D QE_ENABLE_LIBXC=ON \ 
        -D QE_ENABLE_SCALAPACK=ON \
        ../

# build all
    make -j 12 all

    # run tests
    ctest -j12

    # install it
    cd ..
    make install 
) &> ${log}

mkdir -p ../../modules/quantum_espresso
# make the template a proper module 
echo '#%Module' > ../../modules/quantum_espresso/6.8_gnu_ompi
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> ../../modules/quantum_espresso/6.8_gnu_ompi

