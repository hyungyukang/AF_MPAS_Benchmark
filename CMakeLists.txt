cmake_minimum_required(VERSION 3.15)
project(MPAS_Project LANGUAGES C CXX Fortran)

list(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules)

# Enable CMake's verbose output (useful for debugging)
set(CMAKE_VERBOSE_MAKEFILE ON)

# Set default build type to Release if not specified
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()


# Define paths
set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}")
set(PIO_DIR "${CMAKE_SOURCE_DIR}/external/ParallelIO")
set(MPAS_DIR "${CMAKE_SOURCE_DIR}/external/MPAS-Model")
#set(NetCDF_DIR "/path/to/netcdf") # Set to the NetCDF installation path
#set(PNetCDF_DIR "/path/to/parallel-netcdf") # Set to the Parallel-NetCDF installation path
set(FCutil_PATH "${CMAKE_SOURCE_DIR}/external/CMake_Fortran_utils") # Set to the FCutil module path
set(GENF90_PATH "${CMAKE_SOURCE_DIR}/external/ParallelIO/scripts") # Set to the FCutil module path
set(PIO_BUILD_DIR "${CMAKE_BINARY_DIR}/PIO_build")

# Find required libraries
find_package(NetCDF REQUIRED)
find_package(PnetCDF REQUIRED)

# Ensure submodules are initialized and updated
#if(NOT EXISTS "${PIO_DIR}/CMakeLists.txt" OR NOT EXISTS "${MPAS_DIR}/CMakeLists.txt")
#  message(FATAL_ERROR "Submodules are not initialized. Run 'git submodule update --init --recursive'")
#endif()

# Pass CMake arguments to PIO
set(USER_CMAKE_MODULE_PATH ${FCutil_PATH} CACHE STRING "Path to user CMake module")
set(GENF90_PATH ${GENF90_PATH} CACHE STRING "Path to user CMake module")
set(NetCDF_PATH ${NetCDF_DIR} CACHE STRING "Path to NetCDF library")

set(PIO_PREFIX "${CMAKE_BINARY_DIR}/PIO_build/install")

# Add custom target for building PIO with arguments
add_custom_target(PIO_BUILD ALL
  COMMAND ${CMAKE_COMMAND} -S ${PIO_DIR} -B ${PIO_BUILD_DIR}
          #-DNetCDF_PATH=${NetCDF_PATH}
          #-DPnetCDF_PATH=${NetCDF_PATH}
          -DCMAKE_INSTALL_PREFIX=${PIO_PREFIX}
          -DUSER_CMAKE_MODULE_PATH=${USER_CMAKE_MODULE_PATH}
          -DGENF90_PATH=${GENF90_PATH}
          -DPIO_ENABLE_TIMING=OFF
  COMMAND ${CMAKE_COMMAND} --build ${PIO_BUILD_DIR}
  COMMAND cd ${PIO_BUILD_DIR} && make install
)

# Add CMake arguments for MPAS
set(MPAS_BUILD_DIR "${CMAKE_BINARY_DIR}/MPAS_build")
add_custom_target(MPAS_BUILD ALL
  COMMAND ${CMAKE_COMMAND} -S ${MPAS_DIR} -B ${MPAS_BUILD_DIR}
          -DPIO_PREFIX=${PIO_PREFIX}
          #-DNetCDF_PATH=${NetCDF_PATH}
          #-DFETCHCONTENT_SOURCE_DIR_MPAS_DATA=${MPAS_DIR}/src/core_atmosphere
          #-DFETCHCONTENT_UPDATES_DISCONNECTED=ON
  COMMAND ${CMAKE_COMMAND} --build ${MPAS_BUILD_DIR}
)

add_dependencies(MPAS_BUILD PIO_BUILD)

# Add post-build message
message(STATUS "Configuration complete:'")
message(STATUS "  1) Build ParallelIO first with 'cmake --build . --target PIO_BUILD'")
message(STATUS "  2) Build MPAS-Model with       'cmake --build . --target MPAS_BUILD'")
