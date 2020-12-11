#!/bin/bash
#SBATCH --job-name="elk"
#SBATCH --time=2:00:00
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=2
#SBATCH --exclusive
#SBATCH --partition=ccq
#SBATCH --constraint=rome
#SBATCH --output=out.%j
#SBATCH --error=err.%j

#======START=====

export OMP_NUM_THREADS=64
export OMP_STACKSIZE=256M
ulimit -s unlimited

module purge
module load slurm elk/6.8.4_gnu_ompi/module-rome

mpirun elk elk.in

#=====END====
