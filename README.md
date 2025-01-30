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
   - Obtaning the model runtime
6. Configuring and executing output verifications
   - Evaluating the error norm

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
Two simulations are required to scale the runtime with increasing the number of windows.
#### 5.1. Running `VR20km-1km_N01_D700` test case
This simulation is required to complete within 40 minutes. The number of nodes and cores should be adjusted. It is recommended to start with 50 nodes.
```
cd build/test_runs/VR20km-4km_N01_D700

# 1) Use your job script or the provided example scripts in job_scripts/ (executable is 'mpas_atmosphere'.)
# 2) Submit a job (e.g., on a Slurm system):
sbatch job.sh
```
After successful completion of the simulation (48 hours of model time integration), the output log file `log.atmosphere.0000.out` will contain the message `Finished running the atmosphere core`:
```
grep -e 'Finished running' log.atmosphere.0000.out
```
Nothing will be printed if the model is not successfully completed. In this case, open `log.atmosphere.0000.out` or a job log file to check issues.

#### 5.2. Running `QU20km` test case
Running process is the same as 5.1 except that the test directory is `build/test_runs/QU20km`. Keep in mind using the same number of nodes (cores) as in `VR20km-4km_N01_D700`.

#### 5.3. Obtaining the model runtime
Execute the following command after the simulation has completed:
```
cd build/test_runs/VR20km-4km_N01_D700
string=`sed -n '/time integration/p' log.atmosphere.0000.out` && read -ra arr <<< "$string" && echo ${arr[3]}

cd build/test_runs/QU20km
string=`sed -n '/time integration/p' log.atmosphere.0000.out` && read -ra arr <<< "$string" && echo ${arr[3]}
```
This command will return the total runtime in seconds, excluding I/O runtime.

If the model is run using more than 10,000 cores, logs are written in `log.atmosphere.00000.out`:
```
string=`sed -n '/time integration/p' log.atmosphere.00000.out` && read -ra arr <<< "$string" && echo ${arr[3]}
```

### 6. Estimation of runtime & Verification
After obtatining model runtime for two simulations, the number of nodes (cores) with incresing number of windows (i.e., regionally refined regions) can be estimated by scaling from the runtime differences between the two simulations under the linear scaling assumption.
```
cd build/
cmake --build . --target POST_BUILD
cd postprocess

vi estimate.py

# Enter the runtime information of the two simulations and the system configuration
#   refRuntimeVR : runtime of VR20km-4km_N01_D700
#   refRuntimeQU : runtime of QU20km
#   nNodeUsed : the number node used to obtaion those runtime
#   nCoresPerNode : the number of cores per node

# Save and out
python estimate.py
```
Estimated number of nodes (cores) will be printed out based on the information entered. Here we provide the baseline performance on Air Force HPC11 system with the GNU compiler:
```
--------------------------------------------------------------------
Entered runtime using 64 nodes ( 8192 cores )
 - VR20km-1km_N01_D700 = 2399.776 s
 - QU20km              = 2076.7826 s
--------------------------------------------------------------------
To complete the simulation within 40 minutes,

64 nodes ( 8192 cores ) are apporximately required for 1 windows.
73 nodes ( 9344 cores ) are apporximately required for 2 windows.
81 nodes ( 10368 cores ) are apporximately required for 3 windows.
90 nodes ( 11520 cores ) are apporximately required for 4 windows.
98 nodes ( 12544 cores ) are apporximately required for 5 windows.
107 nodes ( 13696 cores ) are apporximately required for 6 windows.
116 nodes ( 14848 cores ) are apporximately required for 7 windows.
124 nodes ( 15872 cores ) are apporximately required for 8 windows.
133 nodes ( 17024 cores ) are apporximately required for 9 windows.
142 nodes ( 18176 cores ) are apporximately required for 10 windows.
--------------------------------------------------------------------
```

The specific numerical results may vary depending on the machine and compiler used. To ensure baseline accuracy, a verification dataset `verif_HPC11_GNU_VR20km-4km_N01_D700_theta_f48h.nc` is provided to compare the model outputs of the target machine with those obtained on the Air Force HPC11 system. The verification process computes the L2 error norm of the three-dimensional potential temperature after 48 forecast hours. The acceptable error threshold would be less than 1.0E-2.
```
cd build
cmake --build . --target VERIFY_BUILD
cd verifications
./verify.exe
```
