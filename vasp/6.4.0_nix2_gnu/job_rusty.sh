#!/bin/bash
#SBATCH --job-name="lno-scf"
#SBATCH --time=4:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --ntasks-per-core=1
#SBATCH --partition=ccq
#SBATCH --constraint=rome
#SBATCH --output=out.%j
#SBATCH --error=err.%j

#======START=====

module purge
module load slurm
module load vasp/6.4.0_nix2_gnu

export OMP_NUM_THREADS=4
ulimit -s unlimited

VASP="mpirun --map-by socket:pe=$OMP_NUM_THREADS vasp_std" 

$VASP

#=====END====
