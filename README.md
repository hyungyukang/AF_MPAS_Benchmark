# AF_MPAS_Benchmark

## MPAS-Atmosphere benchmark suite

### Collection of MPAS-Model and required libraries as external submodules

### Required libraries
- NetCDF
- Parallel-NetCDF


## Quick start
### Load required modules (can be different for each machine)
```
module load cray-netcdf
module load cray-parallel-netcdf
```
### Installation
```
git clone git@github.com:hyungyukang/AF_MPAS_Benchmark.git
cd AF_MPAS_Benchmark
git submodule update --init --recursive

mkdir build
cmake ../
cmake --build .
```
