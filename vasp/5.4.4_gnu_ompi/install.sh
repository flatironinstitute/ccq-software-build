#!/bin/bash
# exit if any of the steps fails
set -e

# installation script for Vasp +  wannier90 using GNU OpenMPI toolchain

# load modules
MODULES="gcc/7.4.0 openmpi4/4.0.5 intel/mkl/2019-3 lib/fftw3/3.3.8-openmpi4 wannier90/3.1_gnu_ompi/module-rome"

module purge
module load ${MODULES}

BUILDDIR=$(mktemp -d /dev/shm/vasp_build_XXXXXXXX)
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
    
    cp ${INSTALLDIR}/../../wannier90/3.1_gnu_ompi/bin/libwannier_seq.a ${BUILDDIR}/
    
    mkdir ${BUILDDIR}/build
    mkdir ${BUILDDIR}/bin
    # build vasp std gamma version and non-collinear
    make std gam ncl

    # copy binaries
    mkdir -p ${INSTALLDIR}/bin
    cp bin/* ${INSTALLDIR}/bin 

) &> ${log}
    
# make the template a proper module 
echo '#%Module' > module-rome
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> module-rome

# Skylake module
# make the template a proper module 
echo '#%Module' > module-skylake
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g;s|openmpi4/4.0.5|openmpi4/4.0.5-opa|g;s|module-rome|module-skylake|g" < src.module >> module-skylake


