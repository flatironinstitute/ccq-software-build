#!/bin/bash

# installation script for triqs3 stable branch with clang OpenMPI toolchain with new spack modules

# load modules
MODULES="modules/2.3-20240529 gcc flexiblas openmpi cmake gmp fftw nfft hdf5/mpi boost/libcpp-1.84.0 python/3.11 python-mpi/3.11 intel-oneapi-mkl llvm/16 eigen mpfr"
module purge
module load ${MODULES}

export CC=clang
export CXX=clang++
export CFLAGS="-march=broadwell"
export CXXFLAGS="-stdlib=libc++ -Wno-register -march=broadwell"
export FC=gfortran
export CTEST_OUTPUT_ON_FAILURE=1

export BLA_VENDOR=FlexiBLAS

# set up flexiblas:
export MKL_INTERFACE_LAYER=GNU,LP64
export MKL_THREADING_LAYER=SEQUENTIAL
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=12
export NEVANLINNA_NUM_THREADS=4
NCORES=20

BUILDINFO=3_unst_nix2.3_llvm
BUILDDIR=/tmp/triqs${BUILDINFO}_build
INSTALLDIR=$(pwd)/installation
MODULEDIR=$(git rev-parse --show-toplevel)/modules
mkdir -p $BUILDDIR
mkdir -p $INSTALLDIR/lib/python3.11/site-packages

# in case you are using a python virtual environment set it now here
#source /mnt/home/ahampel/py_venv/311/bin/activate
# to have cmake pick up the virtual environment, unset PYTHON_ROOT
# see cmake --help-policy CMP0144
unset PYTHON_ROOT

export ITENSOR_ROOT=${INSTALLDIR}
export TRIQS_ROOT=${INSTALLDIR}
export PATH=${INSTALLDIR}/bin:$PATH
export CPLUS_INCLUDE_PATH=${INSTALLDIR}/include:$CPLUS_INCLUDE_PATH
export LIBRARY_PATH=${INSTALLDIR}/lib:${INSTALLDIR}/lib64:$LIBRARY_PATH
export LD_LIBRARY_PATH=${INSTALLDIR}/lib:${INSTALLDIR}/lib64:$LD_LIBRARY_PATH
export PYTHONPATH=${INSTALLDIR}/lib/python3.11/site-packages:$PYTHONPATH
export CMAKE_PREFIX_PATH=${INSTALLDIR}/lib/cmake/triqs:$CMAKE_PREFIX_PATH
export CMAKE_PREFIX_PATH=${INSTALLDIR}/lib/cmake/cpp2py:$CMAKE_PREFIX_PATH

log=build_$(date +%Y%m%d%H%M).log
testlog="$(pwd)/${log/.log/_test.log}"
(
    cd ${BUILDDIR}

    module list

    # install triqs
    cd ${BUILDDIR}
    git clone -b unstable --depth 1 https://github.com/TRIQS/triqs triqs.src
    # fetch latest changes
    cd triqs.src && git pull && cd ..
    rm -rf triqs.build && mkdir -p triqs.build && cd triqs.build

    cmake ../triqs.src -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} -DBuild_Deps=Always
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install
    #################

    cd ${BUILDDIR}
    # install cthyb
    git clone -b unstable --depth 1 https://github.com/TRIQS/cthyb cthyb.src
    # fetch latest changes
    cd cthyb.src && git pull && cd ..
    rm -rf cthyb.build && mkdir -p cthyb.build && cd cthyb.build

    cmake ../cthyb.src
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install
    #################

    cd ${BUILDDIR}
    # install ctint
    git clone -b unstable --depth 1 git@github.com:TRIQS/ctint.git ctint.src
    # fetch latest changes
    cd ctint.src && git pull && cd ..
    rm -rf ctint.build && mkdir -p ctint.build && cd ctint.build

    cmake ../ctint.src
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install

    ##################

    cd ${BUILDDIR}
    # install ctseg
    git clone -b unstable --depth 1 git@github.com:TRIQS/ctseg.git ctseg.src
    # fetch latest changes
    cd ctseg.src && git pull && cd ..
    rm -rf ctseg.build && mkdir -p ctseg.build && cd ctseg.build

    cmake ../ctseg.src
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install

    #################

    cd ${BUILDDIR}
    # install w2dynamics interface
    git clone -b 3.2.x --depth 1 git@github.com:TRIQS/w2dynamics_interface.git w2dyn.src
    # fetch latest changes
    cd w2dyn.src && git pull && cd ..
    rm -rf w2dyn.build && mkdir -p w2dyn.build && cd w2dyn.build

    cmake ../w2dyn.src
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install

    #################
    cd ${BUILDDIR}
    # install dfttools
    git clone -b unstable --depth 1 https://github.com/TRIQS/dft_tools.git dft_tools.src
    # fetch latest changes
    cd dft_tools.src && git pull && cd ..
    rm -rf dft_tools.build && mkdir -p dft_tools.build && cd dft_tools.build

    cmake ../dft_tools.src
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install
    ################

    cd ${BUILDDIR}
    # install maxent
    git clone -b unstable --depth 1 https://github.com/TRIQS/maxent.git maxent.src
    # fetch latest changes
    cd maxent.src && git pull && cd ..
    rm -rf maxent.build && mkdir -p maxent.build && cd maxent.build

    cmake ../maxent.src
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install
    ################

    cd ${BUILDDIR}
    # install Nevanlinna
    git clone -b unstable --depth 1 https://github.com/TRIQS/Nevanlinna.git Nevanlinna.src
    # fetch latest changes
    cd Nevanlinna.src && git pull && cd ..
    rm -rf Nevanlinna.build && mkdir -p Nevanlinna.build && cd Nevanlinna.build

    cmake ../Nevanlinna.src
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install

    ################
    cd ${BUILDDIR}
    # install TPRF
    git clone -b unstable --depth 1 https://github.com/TRIQS/tprf.git tprf.src
    # fetch latest changes
    cd tprf.src && git pull && cd ..
    rm -rf tprf.build && mkdir -p tprf.build && cd tprf.build

    cmake ../tprf.src
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install
    ################

    cd ${BUILDDIR}
    # install hubbardI
    git clone -b unstable --depth 1 https://github.com/TRIQS/hubbardI.git hubbardI.src
    # fetch latest changes
    cd hubbardI.src && git pull && cd ..
    rm -rf hubbardI.build && mkdir -p hubbardI.build && cd hubbardI.build

    cmake ../hubbardI.src
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install
    ################

    cd ${BUILDDIR}
    # install Hartree Fock
    git clone -b unstable --depth 1 https://github.com/triqs/hartree_fock.git hartree_fock.src
    # fetch latest changes
    cd hartree_fock.src && git pull && cd ..
    rm -rf hartree_fock.build && mkdir -p hartree_fock.build && cd hartree_fock.build

    cmake ../hartree_fock.src
    # make / test / install
    make
    make test &>> ${testlog}
    make install
    ################

    # install ForkTPS
    cd ${BUILDDIR}
    git clone -b unstable --depth 1 git@github.com:TRIQS/forktps.git forktps.src
    # fetch latest changes
    cd forktps.src && git pull && cd ..
    mkdir -p forktps.build && cd forktps.build

    cmake ../forktps.src -DBLAS_LIBRARIES="-L${FLEXIBLAS_ROOT}/libi64 -lflexiblas -lpthread" -Dgpu_backend=none
    # make / test / install
    make -j$NCORES
    # tests leverage MPI / OpenMP
    make test &>> ${testlog}
    make install
    ################

    # install solid_dmft
    cd ${BUILDDIR}
    git clone -b unstable --depth 1 https://github.com/flatironinstitute/solid_dmft.git solid_dmft.src
    # fetch latest changes
    cd solid_dmft.src && git pull && cd ..
    rm -rf solid_dmft.build && mkdir -p solid_dmft.build && cd solid_dmft.build

    cmake ../solid_dmft.src -DMPIEXEC_MAX_NUMPROCS=4 -DTest_GW_embedding=ON
    # make / test / install
    make -j$NCORES
    # tests leverage MPI:
    ctest -j4 &>> ${testlog}
    make install
    ################

) &> ${log}

mkdir -p $MODULEDIR/triqs
# make the template a proper module
echo '#%Module' > $MODULEDIR/triqs/$BUILDINFO
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/triqs/$BUILDINFO

