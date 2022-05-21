#!/bin/bash
# exit if any of the steps fails

# installation script for Vasp +  wannier90 using GNU OpenMPI toolchain

# load modules
MODULES="modules/1.58-20220124 gcc/10 openmpi/4 fftw intel-oneapi-mkl hdf5/1.10.8-mpi"
module purge
module load modules-new
module load ${MODULES}

BUILDDIR="/dev/shm/vasp_build_630_nixpack_gnu"
mkdir -p ${BUILDDIR}
INSTALLDIR="$(pwd)"
MODULEDIR=$(git rev-parse --show-toplevel)/modules

VASPFILE="vasp.6.3.0"

export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=1
NCORES=12

# export Path for linking
export libpath=${BUILDDIR}/${VASPFILE}

log=build_$(date +%Y%m%d%H%M).log

(
    cd ${BUILDDIR}
    
    # list modules
    module list

    # unpack vasp_src
    tar -xf ${INSTALLDIR}/${VASPFILE}.tgz
    cd ${VASPFILE}

    # copy makefile and include wannier lib
    cp ${INSTALLDIR}/makefile.include ${BUILDDIR}/${VASPFILE}
    
    cp ${INSTALLDIR}/../../wannier90/3.1_nixpack_ompi/bin/libwannier_seq.a ${BUILDDIR}/${VASPFILE}
     
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
    #make test 

    # copy binaries
    mkdir -p ${INSTALLDIR}/bin
    cp bin/* ${INSTALLDIR}/bin 

) &> ${log}
    
mkdir -p $MODULEDIR/vasp
# make the template a proper module 
echo '#%Module' > $MODULEDIR/vasp/6.3.0_gnu
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/vasp/6.3.0_gnu

