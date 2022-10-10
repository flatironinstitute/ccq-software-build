#!/bin/bash

# installation script for abinit with gnu/openmpi toolchain and parallel netcdf

# load modules
MODULES="modules/2.0-20220630 gcc/11 openmpi/4 openblas/threaded-0.3.20 hdf5/mpi netcdf/4.8.1_nix2_gnu_ompi fftw/mpi libxc"
module --force purge
module load ${MODULES}

BUILDINFO=12.0_nix2_gnu
BUILDDIR=/tmp/octopus_${BUILDINFO}_build
mkdir $BUILDDIR

INSTALLDIR="$(pwd)/installation"

MODULEDIR=$(git rev-parse --show-toplevel)/modules

NCORES=12

log=build_$(date +%Y%m%d%H%M).log
(
    cd ${BUILDDIR}
    
    module list
    wget --content-disposition https://octopus-code.org/down.php?file=12.0/octopus-12.0.tar.gz
    tar -xvf octopus-12.0.tar.gz

    cd octopus-12.0

    export LDFLAGS="-L$OPENBLAS_BASE/lib -lopenblas -lm -lpthread -lgfortran -lm -lpthread -lgfortran"
    export CFLAGS="-I$OPENBLAS_ROOT/include"
    export FCFLAGS="-I$OPENBLAS_ROOT/include"
    export CC=mpicc
    export CXX=mpicxx
    export FC=mpifort
    ./configure --prefix="$INSTALLDIR" --with-libxc-prefix="$LIBXC_BASE" --with-netcdf-prefix="$NETCDF_BASE" --with-fftw-prefix="$FFTW_BASE" --enable-mpi --with-blas=yes --with-lapack=yes --with-blacs=yes --with-scalapack=yes

    make -j$NCORES
    make check-short
    make install
) &> ${log}

mkdir -p $MODULEDIR/octopus
echo '#%Module' > $MODULEDIR/octopus/$BUILDINFO
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/octopus/$BUILDINFO
