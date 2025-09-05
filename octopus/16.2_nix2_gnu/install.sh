#!/bin/bash

# installation script for octopus with gnu/openmpi toolchain
# need to be able to load the netcdf module
MODULEDIR=$(git rev-parse --show-toplevel)/modules
module use --append ${MODULEDIR}

# load modules
MODULES="modules/2.4-20250724 ninja cmake gcc openblas openmpi fftw gsl cgal boost mpfr scalapack flexiblas"
module --force purge
module load ${MODULES}

BUILDINFO=16.2_nix2_gnu
BUILDDIR=/tmp/octopus_${BUILDINFO}_build
mkdir $BUILDDIR

INSTALLDIR="$(pwd)/install"

NCORES=12

log=build_$(date +%Y%m%d%H%M).log
(
    cd ${BUILDDIR}
    
    module list

    wget https://octopus-code.org/download/16.2/octopus-16.2.tar.xz

    tar -xvf octopus-16.2.tar.xz

    cd octopus-16.2

    cmake -B build --fresh -G Ninja \
      -DOCTOPUS_MPI=On \
      -DOCTOPUS_OpenMP=On \
      -DOCTOPUS_ScaLAPACK=On \
      -DOCTOPUS_UNIT_TESTS=Off \
      -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" \
      -DCMAKE_C_FLAGS="-O3 -g" \
      -DCMAKE_CXX_FLAGS="-O3 -g" \
      -DCMAKE_Fortran_FLAGS="-O3 -fno-var-tracking-assignments -g" \
      -DCMAKE_REQUIRE_FIND_PACKAGE_CGAL=On \
      -DCMAKE_DISABLE_FIND_PACKAGE_ELPA=On \
      -DCMAKE_BUILD_TYPE="RelWithDebInfo"

    cmake --build build -j
    cmake --install build

) &> ${log}

mkdir -p $MODULEDIR/octopus
echo '#%Module' > $MODULEDIR/octopus/$BUILDINFO
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/octopus/$BUILDINFO
