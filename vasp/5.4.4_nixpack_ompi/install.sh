#!/bin/bash

# installation script for Vasp +  wannier90 using GNU OpenMPI toolchain

# load modules
MODULES="modules/1.58-20220124 gcc/10 openmpi fftw intel-oneapi-mkl wannier90/3.1_nixpack_ompi"
module purge
module load modules-new
module load ${MODULES}

BUILDDIR="/dev/shm/vasp_build_544_nixpack_gnu"
mkdir -p ${BUILDDIR}
INSTALLDIR="$(pwd)"

VASPFILE="vasp_544.tar.gz"

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
    
    cp ${INSTALLDIR}/../../wannier90/3.1_nixpack_ompi/bin/libwannier_seq.a ${BUILDDIR}/
    
    mkdir ${BUILDDIR}/build
    mkdir ${BUILDDIR}/bin
    # build vasp std gamma version and non-collinear
    make std ncl gam

    # copy binaries
    mkdir -p ${INSTALLDIR}/bin
    cp bin/* ${INSTALLDIR}/bin 

) &> ${log}
    
mkdir -p ../../modules/vasp
# make the template a proper module 
echo '#%Module' > ../../modules/vasp/5.4.4_nixpack_ompi
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> ../../modules/vasp/5.4.4_nixpack_ompi


