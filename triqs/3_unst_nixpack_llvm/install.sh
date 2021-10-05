#!/bin/bash

# installation script for triqs3 unstable branch with clang OpenMPI toolchain with new spack modules

# load modules
MODULES="gcc/11.2.0 llvm/12.0.1 flexiblas openmpi cmake gmp fftw nfft hdf5 boost/1.77.0-libcpp python/3.9.6 python-mpi/3.9.6-mpi intel-oneapi-mkl/2021.3.0"
module purge
module load modules-new
module load ${MODULES}

export CC=clang
export CXX=clang++
export CFLAGS="-march=broadwell"
export CXXFLAGS="-stdlib=libc++ -Wno-register -march=broadwell" 
export FC=gfortran

# set up flexiblas:
export MKL_INTERFACE_LAYER=GNU,LP64
export MKL_THREADING_LAYER=GNU

mkdir -p /dev/shm/triqs3_unstable_ione_build
BUILDDIR="/dev/shm/triqs3_unstable_ione_build"
mkdir -p installation/lib/python3.9/site-packages
INSTALLDIR="$(pwd)/installation"

export TRIQS_ROOT=${INSTALLDIR}
export PATH=${INSTALLDIR}/bin:$PATH
export CPLUS_INCLUDE_PATH=${INSTALLDIR}/include:$CPLUS_INCLUDE_PATH
export LIBRARY_PATH=${INSTALLDIR}/lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=${INSTALLDIR}/lib:$LD_LIBRARY_PATH
export PYTHONPATH=${INSTALLDIR}/lib/python3.9/site-packages:$PYTHONPATH
export CMAKE_PREFIX_PATH=${INSTALLDIR}/lib/cmake/triqs:$CMAKE_PREFIX_PATH
export CMAKE_PREFIX_PATH=${INSTALLDIR}/lib/cmake/cpp2py:$CMAKE_PREFIX_PATH

log=build_$(date +%Y%m%d%H%M).log
(
    cd ${BUILDDIR}

    module list
    
    # install triqs
    cd ${BUILDDIR}
    git clone -b unstable https://github.com/TRIQS/triqs triqs.src 
    # fetch latest changes
    cd triqs.src && git pull && cd ..
    rm -rf triqs.build && mkdir -p triqs.build && cd triqs.build
    
    cmake ../triqs.src -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} -DBuild_Deps=Always -DBLA_VENDOR=FlexiBLAS
    # make / test / install    
    make -j10 
    ctest -j10 
    make install
    ################

    cd ${BUILDDIR}
    # install cthyb
    git clone -b unstable git@github.com:TRIQS/cthyb.git cthyb.src 
    # fetch latest changes
    cd cthyb.src && git pull && cd ..
    rm -rf cthyb.build && mkdir -p cthyb.build && cd cthyb.build

    cmake ../cthyb.src
    # make / test / install    
    make -j10 
    ctest -j10 
    make install 
    #################

    cd ${BUILDDIR}
    # install dfttools
    git clone -b unstable https://github.com/TRIQS/dft_tools.git dft_tools.src 
    # fetch latest changes
    cd dft_tools.src && git pull && cd ..
    rm -rf dft_tools.build && mkdir -p dft_tools.build && cd dft_tools.build

    cmake ../dft_tools.src
    # make / test / install    
    make -j10 
    ctest -j10 
    make install
    ################
    
    cd ${BUILDDIR}
    # install maxent
    git clone -b unstable https://github.com/TRIQS/maxent.git maxent.src 
    # fetch latest changes
    cd maxent.src && git pull && cd ..
    rm -rf maxent.build && mkdir -p maxent.build && cd maxent.build

    cmake ../maxent.src
    # make / test / install    
    make -j10 
    make test
    make install
    ################

    cd ${BUILDDIR}
    # install TPRF
    git clone -b unstable https://github.com/TRIQS/tprf.git tprf.src 
    # fetch latest changes
    cd tprf.src && git pull && cd ..
    rm -rf tprf.build && mkdir -p tprf.build && cd tprf.build

    cmake ../tprf.src
    # make / test / install    
    make -j10 
    ctest -j10 
    make install
    ################

    cd ${BUILDDIR}
    # install hubbardI
    git clone -b unstable https://github.com/TRIQS/hubbardI.git hubbardI.src 
    # fetch latest changes
    cd hubbardI.src && git pull && cd ..
    rm -rf hubbardI.build && mkdir -p hubbardI.build && cd hubbardI.build

    cmake ../hubbardI.src
    # make / test / install    
    make -j10 
    ctest -j4 
    make install 
    ################
    
    #cd ${BUILDDIR}
    # install solid_dmft
    git clone -b unstable https://github.com/flatironinstitute/solid_dmft.git solid_dmft.src 
    # fetch latest changes
    cd solid_dmft.src && git pull && cd ..
    rm -rf solid_dmft.build && mkdir -p solid_dmft.build && cd solid_dmft.build

    cmake ../solid_dmft.src
    # make / test / install    
    make 
    make test 
    make install 
    ################
) &> ${log}

# make the template a proper module 
echo '#%Module' > module
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> module

