#!/bin/bash

# installation script for triqs3 stable branch with clang OpenMPI toolchain with new spack modules

# load modules
MODULES="modules/2.4-20250724 cmake gcc/13.3.0 llvm/19.1.7 openmpi hdf5/mpi boost intel-oneapi-mkl python-mpi fftw"
module purge
module load ${MODULES}

export CC=clang
export CXX=clang++
export CFLAGS="-march=broadwell"
export CXXFLAGS="-stdlib=libc++ -fPIC -Wno-register -march=broadwell"
export FC=gfortran

export BLA_VENDOR=Intel10_64_dyn

# set up flexiblas:
export MKL_INTERFACE_LAYER=GNU,LP64
export MKL_THREADING_LAYER=SEQUENTIAL
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=1
NCORES=12

BUILDINFO=0.2.0_nix2.4_llvm
BUILDDIR=/tmp/coqui_${BUILDINFO}_build
INSTALLDIR=$(pwd)/installation
MODULEDIR=$(git rev-parse --show-toplevel)/modules

WORKDIR=$(pwd)

rm -rf "$BUILDDIR"
mkdir -p $BUILDDIR

export slate_ROOT=${INSTALLDIR}

export PATH=${INSTALLDIR}/bin:$PATH
export CPLUS_INCLUDE_PATH=${INSTALLDIR}/include:$CPLUS_INCLUDE_PATH
export LIBRARY_PATH=${INSTALLDIR}/lib:${INSTALLDIR}/lib64:$LIBRARY_PATH
export LD_LIBRARY_PATH=${INSTALLDIR}/lib:${INSTALLDIR}/lib64:$LD_LIBRARY_PATH
export PYTHONPATH=${INSTALLDIR}/lib/python3.11/site-packages:$PYTHONPATH

log=build_$(date +%Y%m%d%H%M).log
testlog="$(pwd)/${log/.log/_test.log}"
(
    cd ${BUILDDIR}

    module list

    # install SLATE
    cd ${BUILDDIR}
    git clone -b master --depth 1 https://github.com/icl-utk-edu/slate.git slate
    cd slate
    git submodule update --init
    mkdir -p build && cd build
    cmake ../ -Dblas=mkl -DMKL_INTERFACE_FULL=gf_lp64 -DMKL_MPI=openmpi -DMKL_THREADING=sequential -Dgpu_backend=none -Dbuild_tests=no -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}
    make -j$NCORES
    make install

    # install CoQui
    cd ${BUILDDIR}
    git clone -b v0.2.0 --depth 1 https://github.com/AbInitioQHub/coqui.git coqui
    # fetch latest changes
    cd coqui && git pull
    mkdir -p build && cd build
    cmake ../ -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} -DCOQUI_PYTHON_SUPPORT=ON 
    # make / test / install
    make -j$NCORES
    #ctest -j$NCORES &>> ${testlog}
    make install
) &> ${log}

mkdir -p $MODULEDIR/coqui
echo '#%Module' > $MODULEDIR/coqui/$BUILDINFO
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/coqui/$BUILDINFO

cd $WORKDIR
