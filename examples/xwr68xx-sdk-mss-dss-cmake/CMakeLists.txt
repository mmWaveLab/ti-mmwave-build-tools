cmake_minimum_required(VERSION 3.20)
project(xwr68xx_sdk_mss_dss_cmake NONE)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/../../cmake")
include(TiMmwaveSdkPaths)

set(MMWAVE_SDK_DEVICE "iwr68xx" CACHE STRING "mmWave SDK device")
set(MMWAVE_SDK_DEVICE_TYPE "xwr68xx" CACHE STRING "mmWave SDK device type")

set(SDK_DEMO_DIR "${MMWAVE_SDK_PACKAGES}/ti/demo/xwr68xx/mmw" CACHE PATH "SDK xwr68xx MSS+DSS demo source folder")
set(APP_BUILD_DIR "${CMAKE_BINARY_DIR}/xwr68xx_mmw")
set(OUTPUT_BIN "${APP_BUILD_DIR}/xwr68xx_mmw_demo.bin")

foreach(required_path
    "${SDK_DEMO_DIR}/makefile"
    "${SDK_DEMO_DIR}/mss/mmw_mss.mak"
    "${SDK_DEMO_DIR}/dss/mmw_dss.mak"
    "${MMWAVE_SDK_PACKAGES}/scripts/unix/generateMetaImage.sh")
  if(NOT EXISTS "${required_path}")
    message(FATAL_ERROR "Required SDK path not found: ${required_path}")
  endif()
endforeach()

add_custom_command(
  OUTPUT "${OUTPUT_BIN}"
  COMMAND "${CMAKE_COMMAND}" -E rm -rf "${APP_BUILD_DIR}"
  COMMAND "${CMAKE_COMMAND}" -E copy_directory "${SDK_DEMO_DIR}" "${APP_BUILD_DIR}"
  COMMAND "${CMAKE_COMMAND}" -E env
    "CCS_MAKEFILE_BASED_BUILD=1"
    "MMWAVE_SDK_DEVICE=${MMWAVE_SDK_DEVICE}"
    "MMWAVE_SDK_DEVICE_TYPE=${MMWAVE_SDK_DEVICE_TYPE}"
    "MMWAVE_SDK_TOOLS_INSTALL_PATH=${TI_ROOT}"
    "MMWAVE_SDK_INSTALL_PATH=${MMWAVE_SDK_PACKAGES}"
    "${CMAKE_COMMAND}" -E chdir "${APP_BUILD_DIR}"
    make -f makefile clean
  COMMAND "${CMAKE_COMMAND}" -E env
    "CCS_MAKEFILE_BASED_BUILD=1"
    "MMWAVE_SDK_DEVICE=${MMWAVE_SDK_DEVICE}"
    "MMWAVE_SDK_DEVICE_TYPE=${MMWAVE_SDK_DEVICE_TYPE}"
    "MMWAVE_SDK_TOOLS_INSTALL_PATH=${TI_ROOT}"
    "MMWAVE_SDK_INSTALL_PATH=${MMWAVE_SDK_PACKAGES}"
    "${CMAKE_COMMAND}" -E chdir "${APP_BUILD_DIR}"
    make -f makefile all
  WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
  VERBATIM
  COMMENT "Building TI SDK xwr68xx MSS+DSS demo"
)

add_custom_target(firmware ALL DEPENDS "${OUTPUT_BIN}")

install(FILES "${OUTPUT_BIN}" DESTINATION .)
