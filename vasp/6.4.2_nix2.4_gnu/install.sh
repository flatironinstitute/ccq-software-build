#!/bin/bash

# installation script for VASP + wannier90 using GNU OpenMPI toolchain
# use release 3.1.0 of wannier90 / dev wannier90 branch (that allows MPI) messes up ordering of wannier functions!

MODULES="modules/2.4 gcc openmpi fftw intel-oneapi-mkl hdf5/mpi git wannier90/dev_nix2.4_gnu_ompi"
module purge
module load ${MODULES}

BUILDINFO=6.4.2_nix2.4_gnu
BUILDDIR=/tmp/vasp_${BUILDINFO}_build
INSTALLDIR=$(pwd)
MODULEDIR=$(git rev-parse --show-toplevel)/modules
VASPFILE=vasp.6.4.2

export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=1
export libpath=${BUILDDIR}/${VASPFILE}
NCORES=12

mkdir -p $BUILDDIR

log=build_$(date +%Y%m%d%H%M).log
testlog=$(pwd)/${log/.log/_test.log}
(
    cd ${BUILDDIR}
    module list

    # unpack vasp_src
    tar -xf ${INSTALLDIR}/${VASPFILE}.tgz
    cd ${VASPFILE}

    # copy makefile and include wannier lib
    cp ${INSTALLDIR}/makefile.include .
    cp ${WANNIER90_ROOT}/lib/libwannier_seq.a libwannier.a

    # patch for Vasp CSC
    cd src
    rsync -av ${INSTALLDIR}/vasp_diffs .
    for name in electron.F fileio.F locproj.F mlwf.F; do
        patch $name -p1 -i vasp_diffs/$name
    done
    cd ..

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
echo '#%Module' > $MODULEDIR/vasp/$BUILDINFO
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/vasp/$BUILDINFO
