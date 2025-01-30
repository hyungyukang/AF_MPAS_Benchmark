#!/bin/bash
#SBATCH -A YourProject
#SBATCH -J TEST_MPASA
#SBATCH -N 60
#SBATCH -t 1:00:00
#SBATCH -p batch
#SBATCH --exclusive
##SBATCH --core-spec=8

srun -n 3360 ./mpas_atmosphere
