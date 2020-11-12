#!/bin/bash
#SBATCH --job-name="qe-test-rome"
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

module load quantum_espresso/6.6_gnu_ompi/module

mpirun pw.x < si.scf.in > si.scf.out

#=====END====
