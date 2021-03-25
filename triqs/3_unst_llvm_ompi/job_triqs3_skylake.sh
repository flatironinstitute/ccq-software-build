#!/bin/bash
#SBATCH --job-name="triqs3-test-skylake"
#SBATCH --time=02:00:00
#SBATCH --nodes=3
#SBATCH --ntasks-per-node=40
#SBATCH --constraint=skylake 
#SBATCH --partition=ccq
#SBATCH --exclusive
#SBATCH --output=out.%j
#SBATCH --error=err.%j

#======START=====

# set OMP_NUM_THREADS so that times ntasks-per-node is the total number of cores on each node
export OMP_NUM_THREADS=1

module purge
module load slurm triqs/3_unst_llvm_ompi/module-skylake

# with map by socket a maximum of number of cores per physical cores are spawned! This is cores per node/2
# if more threads are needed switch socket -> node
mpirun --map-by node:pe=$OMP_NUM_THREADS python3 run_dmft.py

#=====END====
