#!/bin/bash

# installation script for wannier90 with GNU OpenMPI toolchain

# load modules
MODULES="gcc/7.4.0 openmpi4/4.0.5 intel/mkl/2019-3 lib/fftw3/3.3.8-openmpi4" 
module purge
module load ${MODULES}

BUILDDIR=$(mktemp -d /dev/shm/w90_build_XXXXXXXX)
INSTALLDIR="$(pwd)"

log=build_$(date +%Y%m%d%H%M).log
testlog="$(pwd)/${log/.log/_test.log}"
(
    cd ${BUILDDIR}
    module list

    # clone version 3.1. from github
    git clone -b v3.1.0 https://github.com/wannier-developers/wannier90.git wannier90

    cp ${INSTALLDIR}/make.inc wannier90/

    cd wannier90

    # build wannier90
    make -j 8 wannier lib post w90chk2chk
    
    # run tests
    make tests &> ${testlog}

    # copy binaries
    mkdir ${INSTALLDIR}/bin
    cp postw90.x wannier90.x libwannier.a w90chk2chk.x ${INSTALLDIR}/bin/
) &> ${log}

echo "Last 20 lines of test ouput:"
tail -20 ${testlog}

# make the template a proper module 
echo '#%Module' > module-rome
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> module-rome

# Skylake module
# make the template a proper module 
echo '#%Module' > module-skylake
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g;s|openmpi4/4.0.5|openmpi4/4.0.5-opa|g" < src.module >> module-skylake


# finish up
echo -e "\nReview ${log} and ${testlog}, move the "'"'module'"'" file to the correct location and then run:\n    rm -rf ${BUILDDIR}.\n"


