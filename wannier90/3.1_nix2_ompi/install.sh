#!/bin/bash

# installation script for wannier90 with GNU OpenMPI toolchain

# load modules
MODULES="modules/2.0-20220630 gcc/11 fftw intel-oneapi-mkl python/3.10"
module purge
module load ${MODULES}

BUILDINFO=3.1_nix2_gnu_ompi
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

    git clone -b v3.1.0 --depth=1 https://github.com/wannier-developers/wannier90.git wannier90

    cd wannier90 
    make veryclean
    
    # build seq version of wannier90
    cp ${INSTALLDIR}/../make.inc_seq make.inc
    make -j$NCORES PREFIX=${INSTALLDIR} wannier lib post w90chk2chk
    make PREFIX=${INSTALLDIR} install
    make veryclean

    # cp include mod .o files
    mkdir ${INSTALLDIR}/include
    cp src/obj/* ${INSTALLDIR}/include/
    
) &> ${log}

mkdir -p $MODULEDIR/wannier90
# make the template a proper module 
echo '#%Module' > $MODULEDIR/wannier90/$BUILDINFO
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/wannier90/$BUILDINFO
