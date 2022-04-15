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

# set OMP_NUM_THREADS so that times ntasks-per-node is the total number of cores on each node
# Vasp is currently compiled without OpenMP support!
export OMP_NUM_THREADS=1
ulimit -s unlimited

module purge
module load slurm quantum_espresso/7.0_gnu_ompi
######################
# for skylake jobs!!
# comment this line for skylake jobs:
#module load openmpi-opa
#######################

mpirun pw.x < si.scf.in > si.scf.out

#=====END====
