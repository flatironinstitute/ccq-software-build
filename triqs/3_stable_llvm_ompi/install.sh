#!/bin/bash

# installation script for triqs3 unstable branch with GNU OpenMPI toolchain

# load modules
MODULES="gcc/7.4.0 llvm/11.0.0 intel/mkl/2019-3 openmpi4/4.0.5 python3/3.7.3 python3-mpi4py/3.7.3-openmpi4 lib/boost/1.70-gcc7 cmake/3.19.1 gdb/8.2 valgrind/3.15.0 lib/hdf5/1.8.21-openmpi4 lib/fftw3/3.3.8-openmpi4 lib/NFFT/3.4.0 lib/gmp/6.1.2"
module purge
module load ${MODULES}

export CC=clang
export CXX=clang++
export CFLAGS="-march=broadwell"
export CXXFLAGS="-m64 -stdlib=libc++ -Wno-register -march=broadwell -I${MKLROOT}/include"
export FC=gfortran

mkdir -p /dev/shm/triqs3_stable_build
BUILDDIR="/dev/shm/triqs3_stable_build"
mkdir -p installation/lib/python3.7/site-packages
INSTALLDIR="$(pwd)/installation"

export TRIQS_ROOT=${INSTALLDIR}
export PATH=${INSTALLDIR}/bin:$PATH
export CPLUS_INCLUDE_PATH=${INSTALLDIR}/include:$CPLUS_INCLUDE_PATH
export LIBRARY_PATH=${INSTALLDIR}/lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=${INSTALLDIR}/lib:$LD_LIBRARY_PATH
export PYTHONPATH=${INSTALLDIR}/lib/python3.7/site-packages:$PYTHONPATH
export CMAKE_PREFIX_PATH=${INSTALLDIR}/lib/cmake/triqs:$CMAKE_PREFIX_PATH
export CMAKE_PREFIX_PATH=${INSTALLDIR}/lib/cmake/cpp2py:$CMAKE_PREFIX_PATH

log=build_$(date +%Y%m%d%H%M).log
(
    cd ${BUILDDIR}

    module list
    
    # make sure cython is up to date
    pip3 install --upgrade --target ${INSTALLDIR}/lib/python3.7/site-packages cython pybind11 gast 

    # first install numpy and scipy with MKL libs
    # Numpy
    git clone --branch=v1.20.2 https://github.com/numpy/numpy.git numpy
    cd numpy 
    echo '[mkl]' > site.cfg
    echo 'mkl_libs = mkl_def, mkl_gf_lp64, mkl_core, mkl_sequential' >> site.cfg
    echo 'lapack_libs = mkl_def, mkl_gf_lp64, mkl_core, mkl_sequential' >> site.cfg
    python3 setup.py build -j 10 install --prefix ${INSTALLDIR} 
    
    # Scipy
    # if scipy has a problem using the wrong cython, this is because pythran is installed with the wrong cython!
    # error: wrong number of arguments
    # to solve pip3 uninstall pythran and then install again
    cd ${BUILDDIR}
    git clone --branch=v1.6.3 https://github.com/scipy/scipy.git scipy
    cd scipy 
    echo '[mkl]' > site.cfg
    echo 'mkl_libs = mkl_def, mkl_gf_lp64, mkl_core, mkl_sequential' >> site.cfg
    echo 'lapack_libs = mkl_def, mkl_gf_lp64, mkl_core, mkl_sequential' >> site.cfg
    python3 setup.py build -j 10 install --prefix ${INSTALLDIR}

    # install triqs
    cd ${BUILDDIR}
    git clone -b 3.0.x https://github.com/TRIQS/triqs triqs.src 
    # fetch latest changes
    cd triqs.src && git pull && cd ..
    mkdir -p triqs.build && cd triqs.build
    
    cmake ../triqs.src -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} -DBuild_Deps=Always -DBLA_VENDOR=Intel10_64lp_seq 
    # make / test / install    
    make -j10 
    ctest -j10 
    make install
    ################

    cd ${BUILDDIR}
    # install cthyb
    git clone -b 3.0.x https://github.com/TRIQS/cthyb.git cthyb.src 
    # fetch latest changes
    cd cthyb.src && git pull && cd ..
    mkdir -p cthyb.build && cd cthyb.build

    cmake ../cthyb.src
    # make / test / install    
    make -j10 
    ctest -j10 
    make install 
    ################

    cd ${BUILDDIR}
    # install dfttools
    git clone -b 3.0.x https://github.com/TRIQS/dft_tools.git dft_tools.src 
    # fetch latest changes
    cd dft_tools.src && git pull && cd ..
    mkdir -p dft_tools.build && cd dft_tools.build

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
    mkdir -p maxent.build && cd maxent.build

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
    mkdir -p tprf.build && cd tprf.build

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
    mkdir -p hubbardI.build && cd hubbardI.build

    cmake ../hubbardI.src
    # make / test / install    
    make -j10 
    ctest -j4 
    make install 
    ################
) &> ${log}

# make the template a proper module 
echo '#%Module' > module-rome
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> module-rome

# Skylake module
# make the template a proper module 
echo '#%Module' > module-skylake
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g;s|openmpi4/4.0.5|openmpi4/4.0.5-opa|g" < src.module >> module-skylake
