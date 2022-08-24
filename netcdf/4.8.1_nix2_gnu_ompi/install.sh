#!/bin/bash

# installation script for parallel netcdf+hdf5 with gnu toolchain

# load modules
MODULES="modules/2.0-20220630 gcc/11 openmpi/4 hdf5/mpi"
module purge
module load ${MODULES}

BUILDINFO=4.8.1_nix2_gnu_ompi
BUILDDIR=/tmp/netcdf_${BUILDINFO}_build
mkdir $BUILDDIR

INSTALLDIR="$(pwd)/installation"

MODULEDIR=$(git rev-parse --show-toplevel)/modules

NCORES=12

log=build_$(date +%Y%m%d%H%M).log
(
    cd ${BUILDDIR}
    
    module list

    # download netcdf-c
    wget https://github.com/Unidata/netcdf-c/archive/v4.8.1.tar.gz
    tar -xvf v4.8.1.tar.gz

    # download netcdf-fortran
    wget https://github.com/Unidata/netcdf-fortran/archive/v4.5.3.tar.gz
    tar -xvf v4.5.3.tar.gz

    # compile netcdf-c (must be done first)
    cd netcdf-c-4.8.1
    ./configure CC=mpicc CPPFLAGS="-I${HDF5_BASE}/include" LDFLAGS="-L${HDF5_BASE}/lib" \
        LIBS="-lhdf5_fortran -lhdf5_hl_fortran -lhdf5_hl -lhdf5" \
        --enable-parallel-tests --with-mpiexec=mpirun --prefix=${INSTALLDIR}
    make -j$NCORES
    make check
    make install
    cd ../

    # to be set by module later, just set here for now
    NETCDF_BASE=${INSTALLDIR}
    LD_LIBRARY_PATH=${NETCDF_BASE}/lib:${LD_LIBRARY_PATH}

    # compile netcdf-fortran
    cd netcdf-fortran-4.5.3
    echo
    which mpifort
    echo
    ./configure FC=mpifort CC=mpicc CPPFLAGS="-I${NETCDF_BASE}/include -I${HDF5_BASE}/include" \
        LDFLAGS="-L${NETCDF_BASE}/lib -L${HDF5_BASE}/lib" LIBS="-lhdf5_fortran -lhdf5_hl_fortran -lhdf5_hl -lhdf5" \
        --enable-parallel-tests --prefix=${INSTALLDIR}
    make -j$NCORES
    make check
    make install
) &> ${log}


mkdir -p $MODULEDIR/netcdf
echo '#%Module' > $MODULEDIR/netcdf/$BUILDINFO
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/netcdf/$BUILDINFO
