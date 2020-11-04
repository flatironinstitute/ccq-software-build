#!/bin/bash
#SBATCH --job-name="vasp-test-rome"
#SBATCH --time=08:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH --ntasks-per-core=1
#SBATCH --constraint=rome 
#SBATCH --partition=ccq
#SBATCH --output=out.%j
#SBATCH --error=err.%j

#======START=====

export OMP_NUM_THREADS=1
ulimit -s unlimited

mpirun vasp_std

#=====END====
