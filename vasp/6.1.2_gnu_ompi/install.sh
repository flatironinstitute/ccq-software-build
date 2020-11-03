#!/bin/bash

# installation script for Vasp +  wannier90 using GNU OpenMPI toolchain

# load modules
module purge
module load gcc/7.4.0 openmpi4/4.0.5 intel/mkl/2019-3 lib/fftw3/3.3.8-openmpi4

# export Path for linking
export libpath=`pwd`

# first make sure that w90 is compiled and ready
cwd=`pwd`
cd ../../wannier90/3.1_gnu_ompi/
bash install.sh

# go back
cd $cwd

# unpack vasp_src
mkdir vasp_src
tar -xvf vasp.6.1.0.tar.gz -C vasp_src

# copy makefile and include wannier lib
cp makefile.include vasp_src/
cp ../../wannier90/3.1_gnu_ompi/bin/libwannier.a vasp_src/

cd vasp_src

# build vasp std gamma version and non-collinear
make std gam ncl

# copy binaries
mkdir ../bin
cp bin/* ../bin/

# create module file from template and change module path
cd ..
path=`pwd`
echo $path
sed -i "s|REPLACEDIR|$path|g" module

