#!/bin/bash

# installation script for itensor and FTPS building on top of triqs

# load modules
MODULES="triqs/3_unst_llvm_ompi/module-rome"
module purge
module load ${MODULES}

export CC=clang
export CXX=clang++
export CXXFLAGS="-stdlib=libc++ -Wno-register"
export FC=gfortran


mkdir -p /dev/shm/triqs3_unstable_build
BUILDDIR="/dev/shm/triqs3_unstable_build"
mkdir -p installation
INSTALLDIR="$(pwd)/installation"

export ITENSOR_ROOT=${INSTALLDIR}
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=12

log=build_$(date +%Y%m%d%H%M).log
(
    cd ${BUILDDIR}
    
    module list

    # install itensor
    git clone -b v3 https://github.com/ITensor/ITensor.git itensor
    # fetch latest changes
    cd itensor && git pull && make clean
    cp ${INSTALLDIR}/../options.mk.itensor ./options.mk
    make -j10
    # copying Itensor libs to triqs lib dir
    cp -r lib itensor ${INSTALLDIR}/
    ################

    # install ForkTPS
    cd ${BUILDDIR}
    git clone -b unstable git@github.com:TRIQS/forktps.git forktps.src
    # fetch latest changes
    cd forktps.src && git pull && cd ..
    mkdir -p forktps.build && cd forktps.build

    cmake ../forktps.src
    # make / test / install    
    make -j10 
    make test
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

