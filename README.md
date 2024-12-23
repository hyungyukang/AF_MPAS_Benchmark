# AF_MPAS_Benchmark

## MPAS-Atmosphere benchmark suite

### Descriptions
- A performance benchmark suite for MPAS-Atmosphere using test runs with real-world configurations.
- A CMake-based framework developed on top of the MPAS-Model and PIO CMake infrastructure.
- Incorporates MPAS-Model and ParallelIO as external submodules.
- Enables verification of test run outputs to ensure accuracy.
  
### Required libraries
- NetCDF
- Parallel-NetCDF

### Summary of process
1. Loading required modules
2. Compiling ParallelIO
3. Compiling MPAS-Atmosphere
4. Downloading input files (>20GB)
5. Configuring and running test simulations
   - Obtaning the model runtime
6. Configuring and executing output verifications
   - Evaluating the error norm

## Quick start

### 1. Loading required modules
The exact commands may vary depending on the machine configuration.
```
module load cray-netcdf-hdf5parallel
module load cray-parallel-netcdf
```
### 2. Cloning the repository & updating submodules
```
git clone git@github.com:hyungyukang/AF_MPAS_Benchmark.git
cd AF_MPAS_Benchmark
git submodule update --init --recursive
```
### 3. Compiling ParallelIO and MPAS-Atmosphere and configuring test runs
```
mkdir build
cd build
cmake ../
cmake --build .
```
#### 3.1. Optional: Compiling components separately
```
mkdir build
cmake ../

# Building ParallelIO
cmake --build . --target PIO_BUILD

# Building MPAS-Atmosphere
cmake --build . --target MPAS_BUILD

# Setting test runs
cmake --build . --target TEST_BUILD
```
### 4. Downloading input & verification files (~23GB)
```
cd AF_MPAS_Benchmark/
wget -O mpas_model_inputs.tar.xz https://www.dropbox.com/scl/fi/oqc6wubvplje52iiivzug/mpas_model_inputs.tar.gz?rlkey=vg7naqooopcrq8vm6qo2pkyy0\&st=tt363ciq\&dl=1
# Decompress - this process may take a long time.
tar -xJf mpas_model_inputs.tar.xz
```
### 5. Running simualtions
```
cd build/test_runs/VR20km-4km_N05_D500

# 1) Use your job script or the provided example scripts in job_scripts/
# 2) Submit a job (e.g., on a Slurm system):  
sbatch job.sh
```
After successful completion of the simulation (6 hours of model time integration), the output log file `log.atmosphere.0000.out` will contain the message `Finished running the atmosphere core`:
```
grep -e 'Finished running' log.atmosphere.0000.out
```
#### 5.1. Obtaining the model runtime
Execute the following command after the simulation has completed:
```
cd build/test_runs/VR20km-4km_N05_D500
string=`sed -n '/time integration/p' log.atmosphere.0000.out` && read -ra arr <<< "$string" && echo ${arr[3]}
```
This command will return the total runtime in seconds, excluding I/O runtime.


### 6. Verification
Digits can be different for each machine and compiler. To ensure least accuracy, we provide a verification set that compares model outputs of the machine with that of Air Force HPC11 machine. The verification code computes L2 error norm of theta (three-dimensional potential temperature) at 6 fourcase hour. The acceptable error range should be less than 1.0E-5.
The specific numerical results may vary depending on the machine and compiler used. To ensure baseline accuracy, a verification dataset `verif_HPC11_GNU_VR20km-4km_N05_D500_theta_f06h.nc` is provided to compare the model outputs of the target machine with those obtained on the Air Force HPC11 system. The verification process computes the L2 error norm of the three-dimensional potential temperature after six forecast hours. The acceptable error threshold would be less than 1.0E-5.
```
cd build
cmake --build . --target VERIFY_BUILD
cd verifications
./verify.exe
```
