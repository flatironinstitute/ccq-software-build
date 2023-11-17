#!/bin/bash

# installation script for triqs3 stable branch with clang OpenMPI toolchain with new spack modules

# load modules
MODULES="modules/2.2-20230808 gcc/11.4.0 flexiblas openmpi cmake gmp fftw nfft hdf5/mpi boost/libcpp-1.82.0 intel-oneapi-mkl"
module purge
module load ${MODULES}

export CC=gcc
export CXX=g++
export CFLAGS="-march=broadwell"
export CXXFLAGS="-Wno-register -march=broadwell"
export FC=gfortran

export BLA_VENDOR=Intel10_64_dyn

# set up flexiblas:
export MKL_INTERFACE_LAYER=GNU,LP64
export MKL_THREADING_LAYER=SEQUENTIAL
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=12
NCORES=12

BUILDINFO=nix2.2_gnu
BUILDDIR=/tmp/beyondDFT_${BUILDINFO}_build
INSTALLDIR=$(pwd)/installation
MODULEDIR=$(git rev-parse --show-toplevel)/modules
mkdir -p $BUILDDIR

export TBLIS_ROOT=${INSTALLDIR}
export slate_ROOT=${INSTALLDIR}

export PATH=${INSTALLDIR}/bin:$PATH
export CPLUS_INCLUDE_PATH=${INSTALLDIR}/include:$CPLUS_INCLUDE_PATH
export LIBRARY_PATH=${INSTALLDIR}/lib:${INSTALLDIR}/lib64:$LIBRARY_PATH
export LD_LIBRARY_PATH=${INSTALLDIR}/lib:${INSTALLDIR}/lib64:$LD_LIBRARY_PATH
export PYTHONPATH=${INSTALLDIR}/lib/python3.10/site-packages:$PYTHONPATH

log=build_$(date +%Y%m%d%H%M).log
testlog="$(pwd)/${log/.log/_test.log}"
(
    cd ${BUILDDIR}

    module list

    # install SLATE
    SLVER=slate-2023.08.25
    cd ${BUILDDIR}
    wget https://github.com/icl-utk-edu/slate/releases/download/v2023.08.25/${SLVER}.tar.gz
    tar -xf ${SLVER}.tar.gz
    cd ${SLVER}
    mkdir -p build && cd build
    cmake ../ -Dblas=mkl -DMKL_INTERFACE_FULL=gf_lp64 -DMKL_MPI=openmpi -DMKL_THREADING=sequential -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}
    make -j$NCORES
    make install

    # TBLIS
    git clone -b master --depth 1 git@github.com:devinamatthews/tblis.git tblis
    # fetch latest changes
    cd tblis && git pull
    ./configure --prefix=${INSTALLDIR}
    make -j$NCORES 
    make install

    # install beyondDFT
    cd ${BUILDDIR}
    git clone -b unfold_bz --depth 1 git@github.com:mmorale3/BeyondDFT.git bdft
    # fetch latest changes
    cd bdft && git pull
    mkdir -p build && cd build
    cmake ../ -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} -DENABLE_FFTW=ON -DENABLE_SLATE=ON  -DENABLE_TBLIS=ON -DENABLE_CUTENSOR=OFF -DENABLE_CUDA=OFF
    # make / test / install
    make -j$NCORES
    #ctest -j$NCORES &>> ${testlog}
    make install
) &> ${log}

mkdir -p $MODULEDIR/beyondDFT
# make the template a proper module
echo '#%Module' > $MODULEDIR/beyondDFT/$BUILDINFO
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/beyondDFT/$BUILDINFO

