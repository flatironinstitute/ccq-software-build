#!/bin/bash

# installation script for Vasp +  wannier90 using GNU OpenMPI toolchain
# use release 3.1.0 of wannier90 / dev wannier90 branch (that allows MPI) messes up ordering of wannier functions! 
#
# load modules
MODULES="modules/2.1.1-20230405 gcc/11.3.0 openmpi/4 fftw intel-oneapi-mkl hdf5/mpi git wannier90/dev_nix2.1_gnu_ompi"
module purge
module load ${MODULES}

BUILDDIR=/tmp/vasp_${BUILDINFO}_build

MODULEDIR=$(git rev-parse --show-toplevel)/modules
BUILDINFO=6.4.1_nix2.1_gnu
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

    # unpack vasp_src
    tar -xf ${INSTALLDIR}/${VASPFILE}.tgz
    cd ${VASPFILE}

    # copy makefile and include wannier lib
    cp ${INSTALLDIR}/makefile.include ${BUILDDIR}/${VASPFILE}
    
    cp ${WANNIER90_ROOT}/lib/libwannier.a ${BUILDDIR}/${VASPFILE}
     
    # patch for Vasp CSC
    cd src
    rsync -av ${INSTALLDIR}/vasp_csc_patch ${BUILDDIR}/${VASPFILE}
    for name in electron.F fileio.F locproj.F mlwf.F; do patch $name -p1 -i ../vasp_csc_patch/$name.diff; done
    cd ${BUILDDIR}/${VASPFILE}

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

