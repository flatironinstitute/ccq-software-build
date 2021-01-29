#!/bin/bash

# installation script for QE with GNU OpenMPI toolchain

# load modules
MODULES="gcc/7.4.0 openmpi4/4.0.5 intel/mkl/2019-3 lib/hdf5/1.8.21-openmpi4 wannier90/3.1_gnu_ompi/module-rome" 
module purge
module load ${MODULES}

export FFLAGS="-O3 -g -march=broadwell"

BUILDDIR=$(mktemp -d /dev/shm/qe_build_XXXXXXXX)
INSTALLDIR="$(pwd)"

log=build_$(date +%Y%m%d%H%M).log
testlog="$(pwd)/${log/.log/_test.log}"
(
    cd ${BUILDDIR}
    
    module list

    # clone version 6.7 from github
    git clone -b qe-6.7.0 https://github.com/QEF/q-e.git qe
    cd qe

    # scalapack can in rare cases lead to MPI segfaults in MKL routines! If that happens
    # turn off scalapack here and recompile. 
    # these errors can be cured by appropriate settings for parralleziation flags
    ./configure -enable-parallel=yes -with-scalapack=yes -with-hdf5=$HDF5_BASE -prefix=${INSTALLDIR}

    # build all
    make -j 10 all

    # run tests
    cd test-suite
    make run-tests-pw-parallel &> ${testlog}

    # install it
    cd ..
    make install 
) &> ${log}

echo "Last 20 lines of test ouput:"
tail -20 ${testlog}

# make the template a proper module 
echo '#%Module' > module-rome
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> module-rome

# Skylake module
# make the template a proper module 
echo '#%Module' > module-skylake
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g;s|openmpi4/4.0.5|openmpi4/4.0.5-opa|g;s|module-rome|module-skylake|g" < src.module >> module-skylake

# finish up
echo -e "\nReview ${log} and ${testlog}, move the "'"'module'"'" file to the correct location and then run:\n    rm -rf ${BUILDDIR}.\n"
