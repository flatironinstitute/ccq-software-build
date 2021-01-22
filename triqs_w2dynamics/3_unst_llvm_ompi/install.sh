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

log=build_$(date +%Y%m%d%H%M).log
(
    cd ${BUILDDIR}
    
    # install ForkTPS
    cd ${BUILDDIR}
    git clone -b unstable git@github.com:TRIQS/w2dynamics_interface.git w2dynamics_interface.src
    # fetch latest changes
    cd w2dynamics_interface.src && git pull && cd ..
    mkdir -p w2dynamics_interface.build && cd w2dynamics_interface.build

    cmake ../w2dynamics_interface.src
    # make / test / install   
    # only make in serial! 
    make 
    #only 3 tests atm
    ctest -j3 
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

