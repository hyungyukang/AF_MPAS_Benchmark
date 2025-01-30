########################################
# CMake script file creating test runs #
########################################

########################################
# 1) Check MP_THOMPSON lookup tables

set(MPAS_PHYS_DIR ${MPAS_DIR}/src/core_atmosphere/physics/physics_wrf/files)

if(EXISTS ${MPAS_PHYS_DIR}/MP_THOMPSON_QRacrQG_DATA.DBL)
  message("***** MPAS-A MP_THOMPSON tables exists in ${MPAS_PHYS_DIR}. ***** ")
  message("      - Skip running ${MPAS_BUILD_DIR}/bin/mpas_atmosphere_build_tables")
  message("      - ***IMPORTANT*** If the compiler has been changed, run this again")
  message("                        and copy *.DBL files to ${MPAS_PHYS_DIR}")
  message("        1) Run ${MPAS_BUILD_DIR}/bin/mpas_atmosphere_build_tables")
  message("        2) mv *.DBL ${MPAS_PHYS_DIR}")
else()
  message("***** MPAS-A MP_THOMPSON tables don't exist in ${MPAS_PHYS_DIR}. ***** ")
  message("      - Running ${MPAS_BUILD_DIR}/bin/mpas_atmosphere_build_tables")

  if(EXISTS ${BINARY_DIR}/MP_THOMPSON_QRacrQG_DATA.DBL)
     execute_process( COMMAND sh -c "rm ${BINARY_DIR}/*.DBL" )
  endif()

  execute_process( COMMAND ${MPAS_BUILD_DIR}/bin/mpas_atmosphere_build_tables )
  execute_process( COMMAND mkdir -p ${MPAS_PHYS_DIR} )
  execute_process( COMMAND sh -c "mv ${BINARY_DIR}/*.DBL ${MPAS_PHYS_DIR}/" )
endif()

########################################
# 2) Create test runs

set(TEST_QU_DIR ${TEST_BUILD_DIR}/QU20km)
set(TEST_VR_DIR ${TEST_BUILD_DIR}/VR20km-4km_N01_D700)

if(EXISTS ${MPAS_BUILD_DIR}/bin/mpas_atmosphere)
  message("***** Setting up test runs *****")

  # If TEST_runs directory was created before, backup as an old version with timestamp
  if(EXISTS ${TEST_BUILD_DIR})
    execute_process( COMMAND sh -c "mv ${TEST_BUILD_DIR} ${TEST_BUILD_DIR}_old_$(date +%Y%m%d)")
  endif()

  # Link & copy required lookup tables, and model executable
  execute_process( COMMAND mkdir -p ${TEST_BUILD_DIR}/temp1 )
  execute_process( COMMAND sh -c "ln -fs ${MPAS_BUILD_DIR}/_deps/mpas_data-src/atmosphere/physics_wrf/files/* ${TEST_BUILD_DIR}/temp1/" )
  execute_process( COMMAND sh -c "ln -fs ${MPAS_DIR}/src/core_atmosphere/physics/physics_wrf/files/* ${TEST_BUILD_DIR}/temp1/" )
  execute_process( COMMAND ln -fs ${SOURCE_DIR}/mpas_model_inputs/graph_partitions ${TEST_BUILD_DIR}/temp1/ )
  execute_process( COMMAND ln -fs ${MPAS_BUILD_DIR}/bin/mpas_atmosphere ${TEST_BUILD_DIR}/temp1/ )
  execute_process( COMMAND cp ${SOURCE_DIR}/mpas_model_inputs/stream_list.atmosphere.output ${TEST_BUILD_DIR}/temp1/ )

  execute_process( COMMAND mv ${TEST_BUILD_DIR}/temp1 ${TEST_QU_DIR} )
  execute_process( COMMAND cp -rf ${TEST_QU_DIR} ${TEST_VR_DIR} )

  # Link the initial condition file and copy namelist and stream files : QU20km
  execute_process( COMMAND ln -fs ${SOURCE_DIR}/mpas_model_inputs/init_2021082700_era5_QU20km.nc ${TEST_QU_DIR}/ )
  execute_process( COMMAND cp ${SOURCE_DIR}/mpas_model_inputs/namelist.atmosphere_QU20km ${TEST_QU_DIR}/namelist.atmosphere )
  execute_process( COMMAND cp ${SOURCE_DIR}/mpas_model_inputs/streams.atmosphere_QU20km ${TEST_QU_DIR}/streams.atmosphere )

  # Link the initial condition file and copy namelist and stream files : VR20km-4km_N01_D700
  execute_process( COMMAND ln -fs ${SOURCE_DIR}/mpas_model_inputs/init_2021082700_era5_VR20km-4km_N01_D700.nc ${TEST_VR_DIR}/ )
  execute_process( COMMAND cp ${SOURCE_DIR}/mpas_model_inputs/namelist.atmosphere_VR20km-4km_N01_D700 ${TEST_VR_DIR}/namelist.atmosphere )
  execute_process( COMMAND cp ${SOURCE_DIR}/mpas_model_inputs/streams.atmosphere_VR20km-4km_N01_D700 ${TEST_VR_DIR}/streams.atmosphere )

else()
  message("***** MPAS-A build is incompleted. Check MPAS-A build. *****")
endif()
