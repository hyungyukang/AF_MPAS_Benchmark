#!/bin/bash
#SBATCH -A YourProject
#SBATCH -J TEST_MPASA
#SBATCH -N 64
#SBATCH -t 1:00:00
#SBATCH --cluster-constraint=blue
#SBATCH --exclusive

srun -n 8192 ./mpas_atmosphere
