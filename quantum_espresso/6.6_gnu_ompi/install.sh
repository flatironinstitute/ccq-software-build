#!/bin/bash

# installation script for wannier90 with GNU OpenMPI toolchain

# load modules
module purge
module load gcc/7.4.0 openmpi4/4.0.5 intel/mkl/2019-3 lib/hdf5/1.8.21-openmpi4 

# clone version 6.6 from github
git clone -b qe-6.6 https://github.com/QEF/q-e.git qe

cd qe

./configure -enable-parallel=yes -with-scalapack=yes 

# HDF does not work yet as HDF is not compiled with -enable-fortran2003, and -enable-parallel
#-with-hdf5=$HDF5_BASE

# build all
make all

# change module path
cd ..
path=`pwd`
# clear module files first
rm module
# place magic module string
echo '#%Module' > module
# add module body
cat src.module >> module
# add cwd as root dir
sed -i "s|REPLACEDIR|$path|g" module

