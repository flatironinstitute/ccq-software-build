#!/bin/bash

# installation script for triqs3 unstable branch with sanitizer support (nix2.4 modules)

MODULES="modules/2.4 gcc flexiblas openmpi cmake gmp fftw nfft hdf5/mpi boost python/3.12 python-mpi/3.12 intel-oneapi-mkl llvm/19 eigen mpfr"
module purge
module load ${MODULES}

export CC=clang CXX=clang++ FC=gfortran
export CFLAGS="-march=broadwell"
export CXXFLAGS="-stdlib=libc++ -Wno-register -march=broadwell"
export CTEST_OUTPUT_ON_FAILURE=1
export BLA_VENDOR=FlexiBLAS

# MKL/FlexiBLAS setup
export MKL_INTERFACE_LAYER=GNU,LP64
export MKL_THREADING_LAYER=SEQUENTIAL
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=12
export NEVANLINNA_NUM_THREADS=4
NCORES=12

BUILDINFO=3_unst_nix2.4_llvm_san
BUILDDIR=/tmp/triqs${BUILDINFO}_build
INSTALLDIR=$(pwd)/installation
MODULEDIR=$(git rev-parse --show-toplevel)/modules

rm -rf $BUILDDIR
mkdir -p $BUILDDIR $INSTALLDIR/lib/python3.12/site-packages

# cmake policy CMP0144: unset PYTHON_ROOT for venv compatibility
unset PYTHON_ROOT

export TRIQS_ROOT=${INSTALLDIR}
export PATH=${INSTALLDIR}/bin:$PATH
export CPLUS_INCLUDE_PATH=${INSTALLDIR}/include:$CPLUS_INCLUDE_PATH
export LIBRARY_PATH=${INSTALLDIR}/lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=${INSTALLDIR}/lib:$LD_LIBRARY_PATH
export PYTHONPATH=${INSTALLDIR}/lib/python3.12/site-packages:$PYTHONPATH
export CMAKE_PREFIX_PATH=${INSTALLDIR}/lib/cmake/triqs:${INSTALLDIR}/lib/cmake/cpp2py:$CMAKE_PREFIX_PATH

log=build_$(date +%Y%m%d%H%M).log
testlog=$(pwd)/${log/.log/_test.log}
exec 3>&1
(
    cd ${BUILDDIR}
    module list

    echo "[$(date +%H:%M:%S)] Building clair..." >&3
    git clone -b unstable --depth 1 https://github.com/flatironinstitute/clair.git clair.src
    CXXFLAGS="--gcc-toolchain=${GCC_ROOT}" cmake -S clair.src -B clair.build -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}
    cmake --build clair.build -j$NCORES
    ctest --test-dir clair.build -j$NCORES &>> ${testlog}
    cmake --install clair.build
    source ${INSTALLDIR}/share/clair/clairvars.sh

    echo "[$(date +%H:%M:%S)] Building triqs..." >&3
    git clone -b unstable --depth 1 https://github.com/TRIQS/triqs triqs.src
    cmake -S triqs.src -B triqs.build -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} -DCMAKE_BUILD_TYPE=RelWithDebInfo -DASAN=ON -DUBSAN=ON
    cmake --build triqs.build -j$NCORES
    cmake --install triqs.build

    echo "[$(date +%H:%M:%S)] Building cthyb..." >&3
    git clone -b unstable --depth 1 https://github.com/TRIQS/cthyb.git cthyb.src
    cmake -S cthyb.src -B cthyb.build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DASAN=ON -DUBSAN=ON
    cmake --build cthyb.build -j$NCORES
    cmake --install cthyb.build

    echo "[$(date +%H:%M:%S)] Building dft_tools..." >&3
    git clone -b unstable --depth 1 https://github.com/TRIQS/dft_tools.git dft_tools.src
    cmake -S dft_tools.src -B dft_tools.build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DASAN=ON -DUBSAN=ON
    cmake --build dft_tools.build -j$NCORES
    ctest --test-dir dft_tools.build -j$NCORES
    cmake --install dft_tools.build

    echo "[$(date +%H:%M:%S)] Build complete." >&3
) &> ${log}
exec 3>&-

mkdir -p $MODULEDIR/triqs
echo '#%Module' > $MODULEDIR/triqs/$BUILDINFO
LLVMSYM=$(which llvm-symbolizer)
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g;s|REPLACELLVMDIR|${LLVMSYM}|g" < src.module >> $MODULEDIR/triqs/$BUILDINFO
