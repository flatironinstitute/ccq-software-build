#!/bin/bash
# exit if any of the steps fails

# installation script for Vasp +  wannier90 using GNU OpenMPI toolchain

# load modules
MODULES="modules/1.58-20220124 gcc/10 openmpi/4 fftw intel-oneapi-mkl"
module purge
module load modules-new
module load ${MODULES}

BUILDDIR="/dev/shm/vasp_build_620_nixpack_gnu"
mkdir -p ${BUILDDIR}
INSTALLDIR="$(pwd)"

VASPFILE="vasp.6.2.0"

# export Path for linking
export libpath=${BUILDDIR}/${VASPFILE}

log=build_$(date +%Y%m%d%H%M).log

(
    cd ${BUILDDIR}
    
    # list modules
    module list

    # unpack vasp_src
    tar -xvf ${INSTALLDIR}/${VASPFILE}.tgz
    cd ${VASPFILE}

    # copy makefile and include wannier lib
    cp ${INSTALLDIR}/makefile.include ${BUILDDIR}/${VASPFILE}
    
    cp ${INSTALLDIR}/../../wannier90/3.1_nixpack_ompi/bin/libwannier_seq.a ${BUILDDIR}/${VASPFILE}
    
    # build vasp std gamma version and non-collinear
    make DEPS=1 -j12 std gam ncl

    export VASP_TESTSUITE_EXE_STD="mpirun -np 12 ${BUILDDIR}/${VASPFILE}/bin/vasp_std"
    export VASP_TESTSUITE_EXE_GAM="mpirun -np 12 ${BUILDDIR}/${VASPFILE}/bin/vasp_gam"
    export VASP_TESTSUITE_EXE_NCL="mpirun -np 12 ${BUILDDIR}/${VASPFILE}/bin/vasp_ncl"
    #make test 

    # copy binaries
    mkdir -p ${INSTALLDIR}/bin
    cp bin/* ${INSTALLDIR}/bin 

) &> ${log}
    
mkdir -p ../../modules/vasp
# make the template a proper module 
echo '#%Module' > ../../modules/vasp/6.2.0_nixpack_gnu
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> ../../modules/vasp/6.2.0_nixpack_gnu

