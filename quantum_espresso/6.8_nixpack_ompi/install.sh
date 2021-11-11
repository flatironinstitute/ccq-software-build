#!/bin/bash

# installation script for QE with GNU OpenMPI toolchain

# load modules
MODULES="gcc/10 openmpi cmake hdf5/1.10.7-mpi intel-oneapi-mkl wannier90/3.1_gnu_ompi"
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
    git clone -b qe-6.8 https://github.com/QEF/q-e.git qe
    cd qe

    # scalapack can in rare cases lead to MPI segfaults in MKL routines! If that happens
    # turn off scalapack here and recompile. 
    # these errors can be cured by appropriate settings for parralleziation flags
    ./configure -enable-parallel=yes -with-scalapack=yes -with-hdf5=${HDF5_BASE} -prefix=${INSTALLDIR}

    # build all
    make -j 10 all

    # run tests
    #cd test-suite
    #make run-tests-pw-parallel &> ${testlog}

    # install it
    cd ..
    make install 
) &> ${log}

echo "Last 20 lines of test ouput:"
tail -20 ${testlog}

mkdir -p ../../modules/quantum_espresso
# make the template a proper module 
echo '#%Module' > ../../modules/quantum_espresso/6.8_gnu_ompi
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> ../../modules/quantum_espresso/6.8_gnu_ompi

# finish up
echo -e "\nReview ${log} and ${testlog}, move the "'"'module'"'" file to the correct location and then run:\n    rm -rf ${BUILDDIR}.\n"
