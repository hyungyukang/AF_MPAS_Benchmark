cmake_minimum_required(VERSION 3.20)
project(MPAS_Project LANGUAGES C CXX Fortran)

list(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules)

# Enable CMake's verbose output (useful for debugging)
set(CMAKE_VERBOSE_MAKEFILE ON)

# Set default build type to Release if not specified
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

##############
# Define paths
##############
set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}")
set(PIO_DIR "${CMAKE_SOURCE_DIR}/external/ParallelIO")
set(MPAS_DIR "${CMAKE_SOURCE_DIR}/external/MPAS-Model")
#set(NetCDF_DIR "/path/to/netcdf") # Set to the NetCDF installation path
#set(PNetCDF_DIR "/path/to/parallel-netcdf") # Set to the Parallel-NetCDF installation path
set(FCutil_PATH "${CMAKE_SOURCE_DIR}/external/CMake_Fortran_utils") # Set to the FCutil module path
set(GENF90_PATH "${CMAKE_SOURCE_DIR}/external/ParallelIO/scripts") # Set to the FCutil module path
set(PIO_BUILD_DIR "${CMAKE_BINARY_DIR}/PIO_build")


#########################
# Find required libraries
#########################
find_package(NetCDF REQUIRED)
find_package(PnetCDF REQUIRED)


###############################################
# Ensure submodules are initialized and updated
###############################################
if(NOT EXISTS "${PIO_DIR}/CMakeLists.txt" OR NOT EXISTS "${MPAS_DIR}/CMakeLists.txt")
  message(FATAL_ERROR "***** Submodules are not initialized. Run 'git submodule update --init --recursive' *****")
endif()


#############################
# Pass CMake arguments to PIO
#############################
set(USER_CMAKE_MODULE_PATH ${FCutil_PATH} CACHE STRING "Path to user CMake module")
set(GENF90_PATH ${GENF90_PATH} CACHE STRING "Path to user CMake module")
set(NetCDF_PATH ${NetCDF_DIR} CACHE STRING "Path to NetCDF library")
set(PIO_PREFIX "${CMAKE_BINARY_DIR}/PIO_build/install")


###################################################
# Compiler flags - User can modify
###################################################
if(${CMAKE_C_COMPILER_ID} STREQUAL "Clang" OR ${CMAKE_C_COMPILER_ID} STREQUAL "CLANG")
  set(CFLAGS "-O3 -h noacc")
  set(CXXFLAGS "-O3 -h noacc")
  set(FFLAGS "-O3 -h byteswapio -ef -f free -h noacc -em -M1077 -hipa0 -hzero")
elseif(${CMAKE_C_COMPILER_ID} STREQUAL "Gnu" OR ${CMAKE_C_COMPILER_ID} STREQUAL "GNU")
  set(CFLAGS "-O3 -m64")
  set(CXXFLAGS "-O3 -m64")
  set(FFLAGS "-O3 -m64 -ffree-line-length-none -fconvert=big-endian -ffree-form")
else()
  set(CFLAGS " ")
  set(CXXFLAGS " ")
  set(FFLAGS " ")
endif()
message(STATUS "***** Fortran flags used for this compilation: ${FFLAGS}")


###################################################
# Add custom target for building PIO with arguments
###################################################
add_custom_target(PIO_BUILD ALL
  COMMAND ${CMAKE_COMMAND} -S ${PIO_DIR} -B ${PIO_BUILD_DIR}
                          #-DNetCDF_PATH=${NetCDF_PATH}
                          #-DPnetCDF_PATH=${NetCDF_PATH}
                          -DCMAKE_INSTALL_PREFIX=${PIO_PREFIX}
                          -DUSER_CMAKE_MODULE_PATH=${USER_CMAKE_MODULE_PATH}
                          -DGENF90_PATH=${GENF90_PATH}
                          -DPIO_ENABLE_TIMING=OFF
                          -DCMAKE_C_FLAGS=${CFLAGS}
                          -DCMAKE_CXX_FLAGS=${CXXFLAGS}
                          -DCMAKE_Fortran_FLAGS=${FFLAGS}
  COMMAND ${CMAKE_COMMAND} --build ${PIO_BUILD_DIR}
  COMMAND cd ${PIO_BUILD_DIR} && make install
)


##############################
# Add CMake arguments for MPAS
##############################
set(MPAS_BUILD_DIR "${CMAKE_BINARY_DIR}/MPAS_build")
add_custom_target(MPAS_BUILD ALL
  COMMAND ${CMAKE_COMMAND} -S ${MPAS_DIR} -B ${MPAS_BUILD_DIR}
                           -DPIO_PREFIX=${PIO_PREFIX}
                           -DCMAKE_C_FLAGS=${CFLAGS}
                           -DCMAKE_CXX_FLAGS=${CXXFLAGS}
                           -DCMAKE_Fortran_FLAGS=${FFLAGS}
                          #-DNetCDF_PATH=${NetCDF_PATH}
                          #-DFETCHCONTENT_SOURCE_DIR_MPAS_DATA=${MPAS_DIR}/src/core_atmosphere
                          #-DFETCHCONTENT_UPDATES_DISCONNECTED=ON
  COMMAND ${CMAKE_COMMAND} --build ${MPAS_BUILD_DIR}
)
add_dependencies(MPAS_BUILD PIO_BUILD)


#########################################################
# Add custom target for building TEST runs with arguments
#########################################################
set(TEST_BUILD_DIR "${CMAKE_BINARY_DIR}/test_runs")
add_custom_target(TEST_BUILD ALL
  COMMAND ${CMAKE_COMMAND} -E echo "***** Setting up test runs *****"
  COMMAND ${CMAKE_COMMAND} -DMPAS_DIR=${MPAS_DIR}
                           -DMPAS_BUILD_DIR=${MPAS_BUILD_DIR}
                           -DTEST_BUILD_DIR=${TEST_BUILD_DIR}
                           -DSOURCE_DIR=${CMAKE_SOURCE_DIR}
                           -DBINARY_DIR=${CMAKE_BINARY_DIR}
                           -P ${CMAKE_SOURCE_DIR}/CreateTest.cmake
)
add_dependencies(TEST_BUILD MPAS_BUILD)

######################################################
# Add custom target for building VERIFY with arguments
######################################################
set(VERIFY_BUILD_DIR "${CMAKE_BINARY_DIR}/verifications")
if (EXISTS "${TEST_BUILD_DIR}/VR20km-4km_N05_D500/outputs/history.2021-08-27_00.00.00.nc")
   add_custom_target(VERIFY_BUILD
     COMMAND mkdir -p ${VERIFY_BUILD_DIR}
     COMMAND ${CMAKE_Fortran_COMPILER}
             -o  ${VERIFY_BUILD_DIR}/verify.exe
             -O2 ${CMAKE_SOURCE_DIR}/verifications/verify.f90 -lnetcdf
     COMMAND ln -fs ${TEST_BUILD_DIR}/VR20km-4km_N05_D500/outputs/history.2021-08-27_00.00.00.nc ${VERIFY_BUILD_DIR}
     COMMAND ln -fs ${CMAKE_SOURCE_DIR}/mpas_model_inputs/verif_HPC11_GNU_VR20km-4km_N05_D500_theta_f06h.nc ${VERIFY_BUILD_DIR}
   )
else()
   add_custom_target(VERIFY_BUILD
     COMMAND ""
     COMMENT "***** ERROR: MPAS-A output '${TEST_BUILD_DIR}/VR20km-4km_N05_D500/outputs/history.2021-08-27_00.00.00.nc' does not exist.
       *****        Check the model run status in '${TEST_BUILD_DIR}/VR20km-4km_N05_D500/log.atmosphere.0000.out' "
   )
endif()


########################
# Add post-build message
########################
message(STATUS "***** Configuration completed: *****")
message(STATUS "      - Build ParallelIO & MPAS-Model & Test runs with 'cmake --build . '")
message(STATUS "      ")
message(STATUS "      - If you want to build separately,")
message(STATUS "        1) Build ParallelIO first with 'cmake --build . --target PIO_BUILD'")
message(STATUS "        2) Build MPAS-Model with       'cmake --build . --target MPAS_BUILD'")
message(STATUS "        3) Set test runs with          'cmake --build . --target TEST_BUILD'")
message(STATUS "        4) Build verification with     'cmake --build . --target VERIFY_BUILD'")
