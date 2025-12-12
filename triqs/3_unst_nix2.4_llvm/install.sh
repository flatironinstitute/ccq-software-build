#!/bin/bash

# installation script for triqs3 unstable branch with clang OpenMPI toolchain (nix2.4 modules)

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
NCORES=20

BUILDINFO=3_unst_nix2.4_llvm
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
export LIBRARY_PATH=${INSTALLDIR}/lib:${INSTALLDIR}/lib64:$LIBRARY_PATH
export LD_LIBRARY_PATH=${INSTALLDIR}/lib:${INSTALLDIR}/lib64:$LD_LIBRARY_PATH
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
    cmake -S triqs.src -B triqs.build -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}
    cmake --build triqs.build -j$NCORES
    ctest --test-dir triqs.build -j$NCORES &>> ${testlog}
    cmake --install triqs.build

    echo "[$(date +%H:%M:%S)] Building cthyb..." >&3
    git clone -b unstable --depth 1 https://github.com/TRIQS/cthyb cthyb.src
    cmake -S cthyb.src -B cthyb.build
    cmake --build cthyb.build -j$NCORES
    ctest --test-dir cthyb.build -j$NCORES &>> ${testlog}
    cmake --install cthyb.build

    echo "[$(date +%H:%M:%S)] Building ctint..." >&3
    git clone -b unstable --depth 1 git@github.com:TRIQS/ctint.git ctint.src
    cmake -S ctint.src -B ctint.build
    cmake --build ctint.build -j$NCORES
    ctest --test-dir ctint.build -j$NCORES &>> ${testlog}
    cmake --install ctint.build

    echo "[$(date +%H:%M:%S)] Building ctseg..." >&3
    git clone -b unstable --depth 1 git@github.com:TRIQS/ctseg.git ctseg.src
    cmake -S ctseg.src -B ctseg.build
    cmake --build ctseg.build -j$NCORES
    ctest --test-dir ctseg.build -j$NCORES &>> ${testlog}
    cmake --install ctseg.build

    echo "[$(date +%H:%M:%S)] Building w2dynamics_interface..." >&3
    git clone -b unstable --depth 1 git@github.com:TRIQS/w2dynamics_interface.git w2dyn.src
    cmake -S w2dyn.src -B w2dyn.build
    cmake --build w2dyn.build -j$NCORES
    ctest --test-dir w2dyn.build -j$NCORES &>> ${testlog}
    cmake --install w2dyn.build

    echo "[$(date +%H:%M:%S)] Building dft_tools..." >&3
    git clone -b unstable --depth 1 https://github.com/TRIQS/dft_tools.git dft_tools.src
    cmake -S dft_tools.src -B dft_tools.build
    cmake --build dft_tools.build -j$NCORES
    ctest --test-dir dft_tools.build -j$NCORES &>> ${testlog}
    cmake --install dft_tools.build

    echo "[$(date +%H:%M:%S)] Building maxent..." >&3
    git clone -b unstable --depth 1 https://github.com/TRIQS/maxent.git maxent.src
    cmake -S maxent.src -B maxent.build
    cmake --build maxent.build -j$NCORES
    ctest --test-dir maxent.build -j$NCORES &>> ${testlog}
    cmake --install maxent.build

    echo "[$(date +%H:%M:%S)] Building Nevanlinna..." >&3
    git clone -b unstable --depth 1 https://github.com/TRIQS/Nevanlinna.git Nevanlinna.src
    cmake -S Nevanlinna.src -B Nevanlinna.build
    cmake --build Nevanlinna.build -j$NCORES
    ctest --test-dir Nevanlinna.build -j$NCORES &>> ${testlog}
    cmake --install Nevanlinna.build

    echo "[$(date +%H:%M:%S)] Building tprf..." >&3
    git clone -b unstable --depth 1 https://github.com/TRIQS/tprf.git tprf.src
    cmake -S tprf.src -B tprf.build
    cmake --build tprf.build -j$NCORES
    ctest --test-dir tprf.build -j$NCORES &>> ${testlog}
    cmake --install tprf.build

    echo "[$(date +%H:%M:%S)] Building hubbardI..." >&3
    git clone -b unstable --depth 1 https://github.com/TRIQS/hubbardI.git hubbardI.src
    cmake -S hubbardI.src -B hubbardI.build
    cmake --build hubbardI.build -j$NCORES
    ctest --test-dir hubbardI.build -j$NCORES &>> ${testlog}
    cmake --install hubbardI.build

    echo "[$(date +%H:%M:%S)] Building hartree_fock..." >&3
    git clone -b unstable --depth 1 https://github.com/triqs/hartree_fock.git hartree_fock.src
    cmake -S hartree_fock.src -B hartree_fock.build
    cmake --build hartree_fock.build
    ctest --test-dir hartree_fock.build &>> ${testlog}
    cmake --install hartree_fock.build

    echo "[$(date +%H:%M:%S)] Building forktps..." >&3
    git clone -b unstable --depth 1 git@github.com:TRIQS/forktps.git forktps.src
    cmake -S forktps.src -B forktps.build -DBLAS_LIBRARIES="-L${FLEXIBLAS_ROOT}/libi64 -lflexiblas -lpthread" -Dgpu_backend=none
    cmake --build forktps.build -j$NCORES
    ctest --test-dir forktps.build &>> ${testlog}
    cmake --install forktps.build

    echo "[$(date +%H:%M:%S)] Building solid_dmft..." >&3
    git clone -b unstable --depth 1 https://github.com/flatironinstitute/solid_dmft.git solid_dmft.src
    cmake -S solid_dmft.src -B solid_dmft.build -DMPIEXEC_MAX_NUMPROCS=4 -DTest_GW_embedding=OFF
    cmake --build solid_dmft.build -j$NCORES
    ctest --test-dir solid_dmft.build -j4 &>> ${testlog}
    cmake --install solid_dmft.build

    echo "[$(date +%H:%M:%S)] Building modest..." >&3
    git clone -b unstable --depth 1 https://github.com/TRIQS/modest.git modest.src
    cmake -S modest.src -B modest.build
    cmake --build modest.build -j$NCORES
    ctest --test-dir modest.build -j$NCORES &>> ${testlog}
    cmake --install modest.build

    echo "[$(date +%H:%M:%S)] Build complete." >&3
) &> ${log}
exec 3>&-

mkdir -p $MODULEDIR/triqs
echo '#%Module' > $MODULEDIR/triqs/$BUILDINFO
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/triqs/$BUILDINFO
