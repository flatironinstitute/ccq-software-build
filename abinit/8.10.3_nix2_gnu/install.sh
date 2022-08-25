#!/bin/bash

# installation script for abinit with gnu/openmpi toolchain and parallel netcdf

# load modules
MODULES="modules/2.0-20220630 gcc/7.5.0 openmpi/4 intel-oneapi-mkl hdf5/mpi netcdf/4.8.1_nix2_gnu_ompi_gcc7.5.0"
module --force purge
module load ${MODULES}

BUILDINFO=8.10.3_nix2_gnu_ompi
BUILDDIR=/tmp/abinit_${BUILDINFO}_build
mkdir $BUILDDIR

INSTALLDIR="$(pwd)/installation"

MODULEDIR=$(git rev-parse --show-toplevel)/modules

NCORES=12

CODEDIR="$(pwd)"
AC_FILE="ompi4_gnu.ac"


log=build_$(date +%Y%m%d%H%M).log
(
    cd ${BUILDDIR}
    
    module list

    wget https://www.abinit.org/sites/default/files/packages/abinit-8.10.3.tar.gz
    tar -xvf abinit-8.10.3.tar.gz

    cp ${CODEDIR}/${AC_FILE} abinit-8.10.3/

    cd abinit-8.10.3

    INSTALLDIR=$INSTALLDIR ./configure --with-config-file=${AC_FILE}

    make -j8
    make check
    make install
) &> ${log}

mkdir -p $MODULEDIR/abinit
echo '#%Module' > $MODULEDIR/abinit/$BUILDINFO
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/abinit/$BUILDINFO
