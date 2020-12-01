#!/bin/bash

# installation script for wannier90 with GNU OpenMPI toolchain

# load modules
MODULES="gcc/7.4.0 openmpi4/4.0.5 intel/mkl/2019-3 lib/hdf5/1.8.21-openmpi4 wannier90/3.1_gnu_ompi/module" 
module purge
module load ${MODULES}

BUILDDIR=$(mktemp -d /dev/shm/qe_build_XXXXXXXX)
INSTALLDIR="$(pwd)"

log=build_$(date +%Y%m%d%H%M).log
testlog="$(pwd)/${log/.log/_test.log}"
(
    cd ${BUILDDIR}
    
    module list

    # clone version 6.6 from github
    git clone -b qe-6.6 https://github.com/QEF/q-e.git qe
    cd qe
    
    ./configure -enable-parallel=yes -with-scalapack=yes -prefix=${INSTALLDIR}

    # HDF does not work yet as HDF is not compiled with -enable-fortran2003, and -enable-parallel
    #-with-hdf5=$HDF5_BASE

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
echo '#%Module' > module
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> module

# finish up
echo -e "\nReview ${log} and ${testlog}, move the "'"'module'"'" file to the correct location and then run:\n    rm -rf ${BUILDDIR}.\n"
