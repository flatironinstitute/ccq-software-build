#!/bin/bash
#SBATCH --job-name="triqs3-test-rome"
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH --ntasks-per-core=1
#SBATCH --constraint=rome 
#SBATCH --partition=ccq
#SBATCH --exclusive
#SBATCH --output=out.%j
#SBATCH --error=err.%j

#======START=====

export OMP_NUM_THREADS=1

module purge
module load slurm triqs/3_unst_llvm_ompi/module

mpirun python3 run_dmft.py  

#=====END====
