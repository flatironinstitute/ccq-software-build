#!/bin/bash
#SBATCH --job-name="triqs3-test-skylake"
#SBATCH --time=02:00:00
#SBATCH --nodes=3
#SBATCH --ntasks-per-node=40
#SBATCH --ntasks-per-core=1
#SBATCH --constraint=skylake 
#SBATCH --partition=ccq
#SBATCH --exclusive
#SBATCH --output=out.%j
#SBATCH --error=err.%j

#======START=====

export OMP_NUM_THREADS=1

module purge
module load slurm triqs/3_unst_llvm_ompi/module-skylake

mpirun python3 run_dmft.py  

#=====END====
