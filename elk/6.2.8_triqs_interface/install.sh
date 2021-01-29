#!/bin/bash
# exit if any of the steps fails
set -e

# installation script for Elk 6.2.8 triqs interface version using GNU OpenMPI toolchain

# load modules
MODULES="gcc/7.4.0 openmpi4/4.0.5 intel/mkl/2019-3 lib/fftw3/3.3.8-openmpi4"

module purge
module load ${MODULES}

BUILDDIR=$(mktemp -d /dev/shm/elk_build_XXXXXXXX)
INSTALLDIR="$(pwd)"

# export Path for linking
export libpath=${BUILDDIR}

log=build_$(date +%Y%m%d%H%M).log
testlog="$(pwd)/${log/.log/_test.log}"

(
    cd ${BUILDDIR}
    
    # list modules
    module list

    # unpack vasp_src
    git clone --branch experimental git@github.com:AlynJ/Elk_interface-TRIQS.git ./

    # copy makefile and include wannier lib
    cp ${INSTALLDIR}/make.inc ${BUILDDIR}/
    
    # build 
    make all 

    # copy binaries
    mkdir -p ${INSTALLDIR}/bin
    cp src/elk ${INSTALLDIR}/bin 
    cp src/eos/eos ${INSTALLDIR}/bin 
    cp src/spacegroup/spacegroup ${INSTALLDIR}/bin 
    cp -r species ${INSTALLDIR}
    
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

# finish up
echo -e "\nReview ${log} and ${testlog}, move the "'"'module'"'" file to the correct location and then run:\n    rm -rf ${BUILDDIR}.\n"

