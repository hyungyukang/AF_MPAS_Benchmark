# AF_MPAS_Benchmark

## MPAS-Atmosphere benchmark suite

### Descriptions
- A performance benchmark suite for MPAS-Atmosphere using test runs with real-world configurations.
- A CMake-based framework developed on top of the MPAS-Model and PIO CMake infrastructure.
- Incorporates MPAS-Model (v8.2.2) and ParallelIO (v2.6.3) as external submodules.
- Enables verification of test run outputs to ensure baseline accuracy.
  
### Required libraries
- NetCDF
- Parallel-NetCDF

### Summary of process
1. Loading required modules
2. Downloading input files (~22GB)
3. Compiling ParallelIO
4. Compiling MPAS-Atmosphere
5. Configuring and running test simulations
6. Configuring and executing output verifications

## Instructions

### 1. Loading required modules
The exact commands may vary depending on the machine configuration.
```
module load cray-hdf5-parallel
module load cray-netcdf-hdf5parallel
module load cray-parallel-netcdf
```
### 2. Cloning the repository & updating submodules
```
git clone git@github.com:hyungyukang/AF_MPAS_Benchmark.git
cd AF_MPAS_Benchmark
git submodule update --init --recursive
```
### 3. Downloading input & verification files (~22GB)
```
cd AF_MPAS_Benchmark/
wget -O mpas_model_inputs.tar.gz https://www.dropbox.com/scl/fi/4falmkqwl4nm9axus4z3m/mpas_model_inputs.tar.gz?rlkey=v298tn81avykhi82ze7p35mlw\&st=n6stai3m\&dl=1

# Decompress option 1) Using 'tar', but this process may take a longer time.
tar -xf mpas_model_inputs.tar.gz

# Decompress option 2) If the system has 'pigz', this command can accelerate the decompression process.
tar -I pigz -xf mpas_model_inputs.tar.gz
```
### 4. Compiling ParallelIO and MPAS-Atmosphere and configuring test runs
```
mkdir build
cd build
cmake ../
cmake --build .
```
#### 4.1. Optional: Compiling components separately
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
### 5. Running simualtions
Two test cases must be executed to assess the runtime scaling with an increasing number of regional refinement windows.
#### 5.1. Running `VR20km-1km_N01_D700` test case
This simulation must complete within 40 minutes. The number of nodes and cores should be adjusted accordingly. A starting point of 50 nodes is recommended.
```
cd build/test_runs/VR20km-4km_N01_D700

# 1) Use your job script or the example scripts in 'job_scripts/' (executable: 'mpas_atmosphere'.)
# 2) Submit the job (e.g., on a Slurm system):
sbatch job.sh
```
Upon successful completion of the simulation (48 hours of model time integration), the output log file `log.atmosphere.0000.out` should contain the message `Finished running the atmosphere core`:
```
grep -e 'Finished running' log.atmosphere.0000.out
```
If no output is returned, the model has not completed successfully. In this case, inspect `log.atmosphere.0000.out` or the job log file for error diagnostics.

#### 5.2. Running `QU20km` test case
The execution procedure is identical to that of Section 5.1, except that the test directory is `build/test_runs/QU20km`. The number of nodes and cores should be the same as those used for `VR20km-4km_N01_D700`.

#### 5.3. Obtaining the model runtime
After completing the simulations, execute the following command to retrieve the total runtime in seconds (excluding I/O operations):
```
cd build/test_runs/VR20km-4km_N01_D700
string=`sed -n '/time integration/p' log.atmosphere.0000.out` && read -ra arr <<< "$string" && echo ${arr[3]}

cd build/test_runs/QU20km
string=`sed -n '/time integration/p' log.atmosphere.0000.out` && read -ra arr <<< "$string" && echo ${arr[3]}
```
For simulations utilizing more than 10,000 cores, the log file name is `log.atmosphere.00000.out`.

### 6. Estimation of runtime & Verification

#### 6.1. Estimating runtime
After obtatining the runtime for both test cases, the number of nodes (cores) required for an incresing number of windows (i.e., regionally refined regions) can be estimated under a linear scaling assumption.
```
cd build/
cmake --build . --target POST_BUILD
cd postprocess

vi estimate.py
```
Edit `estimate.py` to input the runtime values and system configuration:
- refRuntimeVR : runtime of VR20km-4km_N01_D700
- refRuntimeQU : runtime of QU20km
- nNodeUsed : the number node used to obtaion those runtime
- nCoresPerNode : the number of cores per node

Save and exit, then excute:
```
python estimate.py
```
The estimated node/core requirements will be displayed. The following baseline performance is provided for reference, based on the Air Force HPC11 system with the GNU compiler:
```
--------------------------------------------------------------------
Runtime measured using 64 nodes ( 8192 cores )
 - VR20km-1km_N01_D700 = 2399.776 s
 - QU20km              = 2076.7826 s
--------------------------------------------------------------------
Estimated requirements to complete 48 h forecast within 40 minutes:

64 nodes ( 8192 cores ) for 1 windows.
73 nodes ( 9344 cores ) for 2 windows.
81 nodes ( 10368 cores ) for 3 windows.
90 nodes ( 11520 cores ) for 4 windows.
98 nodes ( 12544 cores ) for 5 windows.
107 nodes ( 13696 cores ) for 6 windows.
116 nodes ( 14848 cores ) for 7 windows.
124 nodes ( 15872 cores ) for 8 windows.
133 nodes ( 17024 cores ) for 9 windows.
142 nodes ( 18176 cores ) for 10 windows.
--------------------------------------------------------------------
```
#### 6.2. Verification of baseline accuracy
The numerical results may vary depending on the system architecture and compiler. To ensure baseline accuracy, a verification dataset `verif_HPC11_GNU_VR20km-4km_N01_D700_theta_f48h.nc` is provided to compare the model outputs of the target machine with those obtained on the Air Force HPC11 system. The verification process computes the L2 error norm of the three-dimensional potential temperature after 48 forecast hours. The acceptable error threshold is < 1.0E-2.
```
cd build
cmake --build . --target VERIFY_BUILD
cd verifications
./verify.exe
```
