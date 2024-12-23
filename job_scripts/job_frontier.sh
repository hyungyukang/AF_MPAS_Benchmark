#!/bin/bash
#SBATCH -A YourProject
#SBATCH -J TEST_MPASA
#SBATCH -N 20
#SBATCH -t 1:00:00
#SBATCH -p batch
#SBATCH --exclusive
##SBATCH --core-spec=8

srun -n 1120 ./mpas_atmosphere
