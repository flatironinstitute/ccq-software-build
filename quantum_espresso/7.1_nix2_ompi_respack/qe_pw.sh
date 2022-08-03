#!/bin/bash
#SBATCH --job-name="ortho-GX"
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH --ntasks-per-core=1
#SBATCH --partition=ccq
#SBATCH --constraint=rome
#SBATCH --output=out.%j
#SBATCH --error=err.%j

#======START=====

export OMP_NUM_THREADS=1
ulimit -s unlimited

module load slurm
module load quantum_espresso/7.1_nix2_gnu_ompi_respack

# QE scf step
mpirun pw.x -pd .true. -nk 8 < lno.bnd.in > lno.bnd.out 

mpirun -n 32 unfold.x -pd .true. < lno.unfold.in > lno.unfold.out

#=====END====
