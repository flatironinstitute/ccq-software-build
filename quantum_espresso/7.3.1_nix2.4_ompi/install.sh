#!/bin/bash

# installation script for QE with GNU OpenMPI toolchain

MODULES="modules/2.4 gcc openmpi fftw intel-oneapi-mkl hdf5/mpi git libxc wannier90/dev_nix2.4_gnu_ompi cmake"
module purge
module load ${MODULES}

export FFLAGS="-O3 -g -march=broadwell"

BUILDINFO=7.3.1_nix2.4_gnu_ompi
BUILDDIR=/tmp/qe_${BUILDINFO}_build
INSTALLDIR=$(pwd)/installation
MODULEDIR=$(git rev-parse --show-toplevel)/modules

export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=1
NCORES=12

mkdir -p $BUILDDIR

log=build_$(date +%Y%m%d%H%M).log
testlog=$(pwd)/${log/.log/_test.log}
(
    cd ${BUILDDIR}
    module list

    git clone -b qe-7.3.1 --depth 1 https://github.com/QEF/q-e.git qe
    cd qe

    # Patch CMakeLists.txt to work with libxc 7.x (CMake rejects major version mismatch)
    sed -i 's/find_package(Libxc 5.1.2/find_package(Libxc/g' CMakeLists.txt

    cmake -S . -B build \
        -DCMAKE_C_COMPILER=mpicc \
        -DCMAKE_Fortran_COMPILER=mpif90 \
        -DCMAKE_VERBOSE_MAKEFILE=ON \
        -DBLA_VENDOR=Intel10_64lp_seq \
        -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} \
        -DQE_ENABLE_HDF5=ON \
        -DQE_ENABLE_LIBXC=ON \
        -DQE_ENABLE_SCALAPACK=ON \
        -DQE_ENABLE_OPENMP=ON \
        -DQE_WANNIER90_INTERNAL=OFF \
        -DWANNIER90_ROOT=${WANNIER90_ROOT}

    cmake --build build -j$NCORES
    ctest --test-dir build -j$NCORES &>> ${testlog}
    cmake --install build
    cp build/bin/* ${INSTALLDIR}/bin/
) &> ${log}

mkdir -p $MODULEDIR/quantum_espresso
echo '#%Module' > $MODULEDIR/quantum_espresso/$BUILDINFO
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/quantum_espresso/$BUILDINFO
