#!/bin/bash
# exit if any of the steps fails
set -e

# installation script for Vasp +  wannier90 using GNU OpenMPI toolchain

# load modules
MODULES="gcc/7.4.0 openmpi4/4.0.5 intel/mkl/2019-3 lib/fftw3/3.3.8-openmpi4 wannier90/3.1_gnu_ompi/module"

module purge
module load ${MODULES}

BUILDDIR=$(mktemp -d /dev/shm/vasp_build_XXXXXXXX)
INSTALLDIR="$(pwd)"

# export Path for linking
export libpath=${BUILDDIR}

log=build_$(date +%Y%m%d%H%M).log

(
    cd ${BUILDDIR}
    
    # list modules
    module list

    # unpack vasp_src
    tar -xvf ${INSTALLDIR}/vasp.6.1.0.tar.gz

    # copy makefile and include wannier lib
    cp ${INSTALLDIR}/makefile.include ${BUILDDIR}
    
    cp ${INSTALLDIR}/../../wannier90/3.1_gnu_ompi/bin/libwannier.a ${BUILDDIR}
    
    # build vasp std gamma version and non-collinear
    make std gam ncl

    # copy binaries
    mkdir ${INSTALLDIR}/bin
    cp bin/* ${INSTALLDIR}/bin 

) &> ${log}
    
# make the template a proper module 
echo '#%Module' > module
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> module

# finish up
echo -e "\nReview ${log} and ${testlog}, move the "'"'module'"'" file to the correct location and then run:\n    rm -rf ${BUILDDIR}.\n"

