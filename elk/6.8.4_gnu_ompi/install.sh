#!/bin/bash
# exit if any of the steps fails
set -e

# installation script for Vasp +  wannier90 using GNU OpenMPI toolchain

# load modules
MODULES="gcc/7.4.0 openmpi4/4.0.5 intel/mkl/2019-3 lib/fftw3/3.3.8-openmpi4 wannier90/3.1_gnu_ompi/module-rome"

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
    tar -xvf ${INSTALLDIR}/elk-6.8.4.tgz

    # copy makefile and include wannier lib
    cp ${INSTALLDIR}/make.inc ${BUILDDIR}/elk-6.8.4/
    cp ${INSTALLDIR}/../../wannier90/3.1_gnu_ompi/bin/libwannier.a ${BUILDDIR}/elk-6.8.4/src/
    
    cd elk-6.8.4 

    # build vasp std gamma version and non-collinear
    make all 

    # run tests
    make test &> ${testlog}
    make test-mpi &> ${testlog}

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

