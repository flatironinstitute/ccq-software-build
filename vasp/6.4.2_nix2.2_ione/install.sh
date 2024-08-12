#!/bin/bash

# installation script for Vasp +  wannier90 using GNU OpenMPI toolchain
# use release 3.1.0 of wannier90 / dev wannier90 branch (that allows MPI) messes up ordering of wannier functions! 
#
# load modules
MODULES="modules/2.1.1-20230405 intel-oneapi-compilers intel-oneapi-mkl intel-oneapi-mpi hdf5/mpi git"
module purge
module load ${MODULES}

BUILDDIR=/tmp/vasp_${BUILDINFO}_build

MODULEDIR=$(git rev-parse --show-toplevel)/modules
BUILDINFO=6.4.1_nix2.1_ione
BUILDDIR=/tmp/vasp_${BUILDINFO}_build
mkdir -p ${BUILDDIR}
INSTALLDIR="$(pwd)"
MODULEDIR=$(git rev-parse --show-toplevel)/modules

VASPFILE="vasp.6.4.1"

export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=1
NCORES=12

# export Path for linking
export libpath=${BUILDDIR}/${VASPFILE}

log=build_$(date +%Y%m%d%H%M).log
testlog="$(pwd)/${log/.log/_test.log}"
(
    cd ${BUILDDIR}
    
    # list modules
    module list

    # install wannier90 lib
    git clone -b v3.1.0 https://github.com/wannier-developers/wannier90.git wannier90
    cd wannier90
    cp ${INSTALLDIR}/make.inc make.inc
    make lib
    cp libwannier.a ${INSTALLDIR}/bin/
    cd ${BUILDDIR}

    # unpack vasp_src
    tar -xf ${INSTALLDIR}/${VASPFILE}.tgz
    cd ${VASPFILE}

    # copy makefile and include wannier lib
    cp ${INSTALLDIR}/makefile.include ${BUILDDIR}/${VASPFILE}
    
    cp ${INSTALLDIR}/bin/libwannier.a ${BUILDDIR}/${VASPFILE}/libwannier.a
     

    # build vasp std gamma version and non-collinear
    make DEPS=1 -j$NCORES std gam ncl

    export VASP_TESTSUITE_EXE_STD="mpirun -np $NCORES ${BUILDDIR}/${VASPFILE}/bin/vasp_std"
    export VASP_TESTSUITE_EXE_GAM="mpirun -np $NCORES ${BUILDDIR}/${VASPFILE}/bin/vasp_gam"
    export VASP_TESTSUITE_EXE_NCL="mpirun -np $NCORES ${BUILDDIR}/${VASPFILE}/bin/vasp_ncl"
    
    #make test &>> ${testlog}   

    # copy binaries
    mkdir -p ${INSTALLDIR}/bin
    cp bin/* ${INSTALLDIR}/bin 

) &> ${log}
    
mkdir -p $MODULEDIR/vasp
# make the template a proper module 
echo '#%Module' > $MODULEDIR/vasp/$BUILDINFO
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/vasp/$BUILDINFO

