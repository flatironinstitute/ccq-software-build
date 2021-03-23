#!/bin/bash
#SBATCH --job-name="vasp"
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH --ntasks-per-core=1
#SBATCH --constraint=rome 
#SBATCH --partition=gen
#SBATCH --output=out.%j
#SBATCH --error=err.%j

#======START=====

export OMP_NUM_THREADS=1
ulimit -s unlimited

module purge
module load slurm vasp/6.1.2_gnu_ompi/module-rome

mpirun vasp_std

#=====END====
