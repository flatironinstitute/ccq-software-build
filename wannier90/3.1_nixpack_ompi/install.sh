#!/bin/bash

# installation script for wannier90 with GNU OpenMPI toolchain

# load modules
MODULES="gcc/10.2.0 openmpi fftw intel-oneapi-mkl/2021.3.0"
module purge
module load modules-new
module load ${MODULES}

BUILDDIR="/dev/shm/w90_build_31_nixpack_ompi"
mkdir -p ${BUILDDIR}
INSTALLDIR="$(pwd)"

log=build_$(date +%Y%m%d%H%M).log
mkdir ${INSTALLDIR}/bin
(
    cd ${BUILDDIR}
    echo ${PWD}
    module list

    # clone version 3.1. from github
    git clone -b develop https://github.com/wannier-developers/wannier90.git wannier90

    cd wannier90 
    make clean

    # first build seq lib version 
    cp ${INSTALLDIR}/make.inc_seq make.inc
    make -j8 lib
    cp libwannier.a ${INSTALLDIR}/bin/libwannier_seq.a
    rm libwannier.a
    make clean
    
    # build mpi version of wannier90
    cp ${INSTALLDIR}/make.inc_parallel make.inc
    make -j8 wannier lib post w90chk2chk
    
    # copy binaries
    cp postw90.x wannier90.x libwannier.a w90chk2chk.x ${INSTALLDIR}/bin/
) &> ${log}

mkdir -p ../../modules/wannier90
# make the template a proper module 
echo '#%Module' > ../../modules/wannier90/3.1_nixpack_ompi
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> ../../modules/wannier90/3.1_nixpack_ompi

