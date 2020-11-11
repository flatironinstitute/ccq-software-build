#!/bin/bash

# installation script for wannier90 with GNU OpenMPI toolchain

# load modules
module purge
module load gcc/7.4.0 openmpi4/4.0.5 intel/mkl/2019-3 lib/fftw3/3.3.8-openmpi4

# clone version 3.1. from github
git clone -b v3.1.0 https://github.com/wannier-developers/wannier90.git wannier90


cp make.inc wannier90/

cd wannier90

# check modules
module list

# build wannier90
make -j 4 wannier lib post

# copy binaries
mkdir ../bin
cp postw90.x wannier90.x libwannier.a ../bin/

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

