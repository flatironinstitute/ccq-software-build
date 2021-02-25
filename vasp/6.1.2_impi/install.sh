#!/bin/bash
# exit if any of the steps fails
set -e

# installation script for Vasp +  wannier90 using GNU OpenMPI toolchain

# load modules
MODULES="intel/compiler/2020-4 intel/mpi/2020-4 intel/mkl/2020-4"

module purge
module load ${MODULES}

BUILDDIR=$(mktemp -d /dev/shm/vasp_build_XXXXXXXX)
INSTALLDIR="$(pwd)"

VASPFILE="vasp.6.1.2_patched"

# export Path for linking
export libpath=${BUILDDIR}/${VASPFILE}

log=build_$(date +%Y%m%d%H%M).log
testlog="$(pwd)/${log/.log/_test.log}"

(
    cd ${BUILDDIR}
    
    # list modules
    module list

    # unpack vasp_src
    tar -xvf ${INSTALLDIR}/${VASPFILE}.tgz
    cd ${VASPFILE}

    # copy makefile and include wannier lib
    cp ${INSTALLDIR}/makefile.include ${BUILDDIR}/${VASPFILE}
    
    #cp ${INSTALLDIR}/../../wannier90/3.1_gnu_ompi/bin/libwannier_seq.a ${BUILDDIR}/${VASPFILE}
    
    # build vasp std gamma version and non-collinear
    make std gam ncl

    export VASP_TESTSUITE_EXE_STD="mpirun -np 12 ${BUILDDIR}/${VASPFILE}/bin/vasp_std"
    export VASP_TESTSUITE_EXE_GAM="mpirun -np 12 ${BUILDDIR}/${VASPFILE}/bin/vasp_gam"
    export VASP_TESTSUITE_EXE_NCL="mpirun -np 12 ${BUILDDIR}/${VASPFILE}/bin/vasp_ncl"
    #make test &> ${testlog}

    # copy binaries
    mkdir -p ${INSTALLDIR}/bin
    cp bin/* ${INSTALLDIR}/bin 

) &> ${log}
    
# make the template a proper module 
echo '#%Module' > module
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> module

# finish up
echo -e "\nReview ${log} and ${testlog}, move the "'"'module'"'" file to the correct location and then run:\n    rm -rf ${BUILDDIR}.\n"

