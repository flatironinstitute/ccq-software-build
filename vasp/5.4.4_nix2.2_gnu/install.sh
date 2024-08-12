#!/bin/bash

# installation script for Vasp +  wannier90 using GNU OpenMPI toolchain

# load modules
MODULES="modules/2.2-20230808 gcc/11.4.0 openmpi/4 fftw intel-oneapi-mkl git wannier90/dev_nix2.2_gnu_ompi"
module purge
module load ${MODULES}

MODULEDIR=$(git rev-parse --show-toplevel)/modules
BUILDINFO=5.4.4_nix2.2_gnu
BUILDDIR=/tmp/vasp_${BUILDINFO}_build
mkdir -p ${BUILDDIR}
INSTALLDIR="$(pwd)"
MODULEDIR=$(git rev-parse --show-toplevel)/modules

VASPFILE="vasp_544.tar.gz"

NCORES=12

# export Path for linking
export libpath=${BUILDDIR}

log=build_$(date +%Y%m%d%H%M).log

(
    cd ${BUILDDIR}

    # list modules
    module list

    # unpack vasp_src
    tar -xvf ${INSTALLDIR}/${VASPFILE}

    # copy makefile and include wannier lib
    cp ${INSTALLDIR}/makefile.include ${BUILDDIR}/

    cp ${WANNIER90_ROOT}/lib/libwannier_seq.a ${BUILDDIR}/

    mkdir ${BUILDDIR}/build
    mkdir ${BUILDDIR}/bin
    # build vasp std gamma version and non-collinear
    make std ncl gam

    # copy binaries
    mkdir -p ${INSTALLDIR}/bin
    cp bin/* ${INSTALLDIR}/bin

) &> ${log}

mkdir -p $MODULEDIR/vasp
# make the template a proper module
echo '#%Module' > $MODULEDIR/vasp/$BUILDINFO
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/vasp/$BUILDINFO
