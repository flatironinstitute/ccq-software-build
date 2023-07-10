#!/bin/bash

# installation script for wannier90 with GNU OpenMPI toolchain

# load modules
MODULES="modules/2.1.1-20230405 gcc/11.3.0 openmpi/4 fftw intel-oneapi-mkl python/3.10"
module purge
module load ${MODULES}

BUILDINFO=dev_nix2.1_gnu_ompi
BUILDDIR=/tmp/wannier90_${BUILDINFO}_build
mkdir -p ${BUILDDIR}
INSTALLDIR="$(pwd)/installation"
MODULEDIR=$(git rev-parse --show-toplevel)/modules

# w90 does not support parrallel build
NCORES=1

mkdir $INSTALLDIR
log=build_$(date +%Y%m%d%H%M).log
(
    cd ${BUILDDIR}
    echo ${PWD}
    module list

    # clone version unstable from github
    # 3.1. has some MPI segfault issues
    git clone -b develop --depth=1 https://github.com/wannier-developers/wannier90.git wannier90

    cd wannier90 
    make veryclean
    
    # build mpi version of wannier90
    cp ${INSTALLDIR}/../make.inc_parallel make.inc
    make -j$NCORES PREFIX=${INSTALLDIR} wannier lib post w90chk2chk
    make PREFIX=${INSTALLDIR} install
    make veryclean

    # build seq lib version 
    cp ${INSTALLDIR}/../make.inc_seq make.inc
    make -j$NCORES lib
    cp libwannier.a ${INSTALLDIR}/lib/libwannier_seq.a

    # cp include mod .o files
    mkdir ${INSTALLDIR}/include
    cp src/obj/* ${INSTALLDIR}/include/
    
) &> ${log}

mkdir -p $MODULEDIR/wannier90
# make the template a proper module 
echo '#%Module' > $MODULEDIR/wannier90/$BUILDINFO
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/wannier90/$BUILDINFO
