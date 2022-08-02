#!/bin/bash

# installation script for wannier90 with GNU OpenMPI toolchain

# load modules
MODULES="modules/2.0-20220630 gcc/11 openmpi/4 fftw intel-oneapi-mkl python/3.10"
module purge
module load ${MODULES}

BUILDINFO=3.1_nix2_gnu_ompi
BUILDDIR=/tmp/triqs${BUILDINFO}_build
mkdir -p ${BUILDDIR}
INSTALLDIR="$(pwd)"
MODULEDIR=$(git rev-parse --show-toplevel)/modules

# w90 does not support parrallel build
NCORES=1

log=build_$(date +%Y%m%d%H%M).log
mkdir ${INSTALLDIR}/bin
(
    cd ${BUILDDIR}
    echo ${PWD}
    module list

    # clone version unstable from github
    # 3.1. has some MPI segfault issues
    git clone -b develop --depth=1 https://github.com/wannier-developers/wannier90.git wannier90

    cd wannier90 
    make clean

    # first build seq lib version 
    cp ${INSTALLDIR}/make.inc_seq make.inc
    make -j$NCORES lib
    cp libwannier.a ${INSTALLDIR}/bin/libwannier_seq.a
    rm libwannier.a
    make clean
    
    # build mpi version of wannier90
    cp ${INSTALLDIR}/make.inc_parallel make.inc
    make -j$NCORES wannier lib post w90chk2chk
    
    # copy binaries
    cp postw90.x wannier90.x libwannier.a w90chk2chk.x ${INSTALLDIR}/bin/
) &> ${log}

mkdir -p $MODULEDIR/wannier90
# make the template a proper module 
echo '#%Module' > $MODULEDIR/wannier90/$BUILDINFO
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/wannier90/$BUILDINFO
