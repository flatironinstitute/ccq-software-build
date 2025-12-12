#!/bin/bash

# installation script for wannier90 with GNU OpenMPI toolchain

MODULES="modules/2.4 gcc openmpi fftw intel-oneapi-mkl python/3.12"
module purge
module load ${MODULES}

BUILDINFO=dev_nix2.4_gnu_ompi
BUILDDIR=/tmp/wannier90_${BUILDINFO}_build
INSTALLDIR=$(pwd)/installation
MODULEDIR=$(git rev-parse --show-toplevel)/modules

# w90 does not support parallel build
NCORES=1

mkdir -p $BUILDDIR $INSTALLDIR

log=build_$(date +%Y%m%d%H%M).log
(
    cd ${BUILDDIR}
    module list

    # clone develop branch pinned to specific commit (3.1 has MPI segfault issues)
    git clone -b develop --depth 1 https://github.com/wannier-developers/wannier90.git wannier90
    cd wannier90
    git checkout 3cdb8031ba921cc54d543a5043ab45c466c767b9

    # build mpi version of wannier90
    cp ${INSTALLDIR}/../make.inc_parallel make.inc
    make -j$NCORES PREFIX=${INSTALLDIR} wannier lib post w90chk2chk
    make PREFIX=${INSTALLDIR} install
    make veryclean

    # build seq lib version
    cp ${INSTALLDIR}/../make.inc_seq make.inc
    make -j$NCORES lib
    cp libwannier.a ${INSTALLDIR}/lib/libwannier_seq.a

    # copy include mod .o files
    mkdir -p ${INSTALLDIR}/include
    cp src/obj/* ${INSTALLDIR}/include/
) &> ${log}

mkdir -p $MODULEDIR/wannier90
echo '#%Module' > $MODULEDIR/wannier90/$BUILDINFO
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/wannier90/$BUILDINFO
