#!/bin/bash
#SBATCH --job-name="triqs3-test"
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH --constraint=rome 
#SBATCH --partition=ccq
#SBATCH --exclusive
#SBATCH --output=out.%j
#SBATCH --error=err.%j

#======START=====

# set OMP_NUM_THREADS so that times ntasks-per-node is the total number of cores on each node
export OMP_NUM_THREADS=1

module purge
module load slurm 
module load triqs/3_unst_llvm_ompi
######################
# for skylake jobs!!
# comment this line for skylake jobs:
#module load openmpi-opa
#######################

# with map by socket a maximum of number of cores per physical cores are spawned! This is cores per node/2
# if more threads are needed switch socket -> node
mpirun --map-by socket:pe=$OMP_NUM_THREADS python3 run_dmft.py  

#=====END====
