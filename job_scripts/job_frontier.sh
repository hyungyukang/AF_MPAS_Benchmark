#!/bin/bash
#SBATCH -A YourProject
#SBATCH -J TEST_MPASA
#SBATCH -o %x-%j.out
#SBATCH -t 0:30:00
#SBATCH -p batch
#SBATCH -q debug
#SBATCH -N 10
#SBATCH --exclusive
##SBATCH --core-spec=8

export OMP_NUM_THREADS=1
srun -n 560 ./mpas_atmosphere
