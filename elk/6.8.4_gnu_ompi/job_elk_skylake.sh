#!/bin/bash
#SBATCH --job-name="elk"
#SBATCH --time=2:00:00
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --exclusive
#SBATCH --partition=ccq
#SBATCH --constraint=skylake
#SBATCH --output=out.%j
#SBATCH --error=err.%j

#======START=====

export OMP_NUM_THREADS=40
export OMP_STACKSIZE=256M
ulimit -s unlimited

module purge
module load slurm elk/6.8.4_gnu_ompi/module-skylake

mpirun elk elk.in

#=====END====
