#!/bin/bash

NAME="qmcpack"
VERSION="3.11.0"
NVER=${NAME}-${VERSION}
URL="git@github.com:QMCPACK/qmcpack.git"
MODULES="gcc/7.4.0 openmpi4/4.0.5 intel/mkl/2020-4 lib/hdf5/1.8.21-openmpi4 lib/boost/1.70-gcc7 python3/3.7.3 cmake/3.19.1 cuda/10.1.243_418.87.00 nccl/2.4.2-cuda-10.1"

# load modules
module purge
module load ${MODULES}

# build in burst buffer
BUILDDIR=$(mktemp -d /dev/shm/${NAME}_build_XXXXXXXX)
# copy binaries back
INSTALLDIR="$(pwd)"

# log build and test outputs
log=build_$(date +%Y%m%d%H%M).log
testlog="$(pwd)/${log/.log/_test.log}"

# QMCPACK code path
buildtype=gpu_comp

# build and test
(
  date
  cd ${BUILDDIR}
  module list
  git clone -b v$VERSION $URL $NVER
  cd $NVER

  export HDF5_ROOT=$HDF5_BASE
  export BOOST_ROOT=$BOOST_BASE
  export CUDA_HOME=$CUDA_BASE
  export NCCL_HOME=$NCCL_BASE

  mkdir $buildtype
  cd $buildtype
  cmake -D CMAKE_C_COMPILER=mpicc -D CMAKE_CXX_COMPILER=mpicxx \
   -D BUILD_AFQMC=1 -D QMC_COMPLEX=1 -D QMC_MIXED_PRECISION=1 \
   -D ENABLE_CUDA=1 -D CUDA_ARCH="sm_70" -D BUILD_AFQMC_WITH_NCCL=1 \
   -D QMC_INCLUDE="${CUDA_HOME}/include;${NCCL_HOME}/include" \
   -D QMC_EXTRA_LIBS="-L${CUDA_HOME}/lib64 -Wl,-rpath,${CUDA_HOME} -lcusolver -lcurand -lcusparse -lcublas -lcudart -L${NCCL_HOME}/lib -lnccl -Wl,-rpath=${NCCL_HOME}/lib" \
   -D ENABLE_TIMERS=1 -D BUILD_LMYENGINE_INTERFACE=0 \
   ..
  make -j 16
  ctest -R unit &> ${testlog}
  cd ..
  date
) &> ${log}

tail -20 ${testlog}

# install just one binary
if [ ! -d bin ]; then
  mkdir bin
fi
rsync -az ${BUILDDIR}/$NVER/$buildtype/bin/* bin/$buildtype
(
  cd bin
  ln -s $buildtype/qmcpack qmcpack_$buildtype
)

# make the template a proper module 
fmod=gpu
echo '#%Module' > $fmod
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $fmod
sed -i "s|REPLACE_NAME|${NAME}|" $fmod
sed -i "s|REPLACE_VERSION|${VERSION}|" $fmod

# manual finish up
echo -e "\nReview ${log} and ${testlog}, move ${fmod} to the correct location and then run:\n    rm -rf ${BUILDDIR}\n"
