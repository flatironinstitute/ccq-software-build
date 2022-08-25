#!/bin/bash

# installation script for abinit with gnu/openmpi toolchain and parallel netcdf

# load modules
MODULES="modules/2.0-20220630 gcc/11 openmpi/4 hdf5/mpi netcdf/4.8.1_nix2_gnu_ompi intel-oneapi-mkl libxc wannier90/3.1_nix2_gnu_ompi"
module --force purge
module load ${MODULES}

BUILDINFO=9.6.2_nix2_gnu_ompi
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

    wget https://www.abinit.org/sites/default/files/packages/abinit-9.6.2.tar.gz
    tar -xvf abinit-9.6.2.tar.gz

    cd abinit-9.6.2

    cp ${CODEDIR}/${AC_FILE} ./
    # module h5cc doesn't have -showconfig or -show
    # seems those are dependent on how hdf5 was built
    # see https://github.com/spack/spack/issues/27000 and https://github.com/HDFGroup/hdf5/issues/1814
    cp ${CODEDIR}/configure.diff ./
    patch configure -i configure.diff

    INSTALLDIR=$INSTALLDIR ./configure --with-config-file=${AC_FILE}

    make -j8
    make check
    make install
) &> ${log}

mkdir -p $MODULEDIR/abinit
echo '#%Module' > $MODULEDIR/abinit/$BUILDINFO
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/abinit/$BUILDINFO
