cmake_minimum_required(VERSION 3.20)
project(breath_rate_6843aop_external NONE)

set(BUILD_TOOLS_DIR "${CMAKE_CURRENT_LIST_DIR}/../.." CACHE PATH "Path to ti-mmwave-build-tools")
set(APP_ROOT "" CACHE PATH "Path to the breath-rate-6843aop firmware folder")
if(NOT APP_ROOT)
    message(FATAL_ERROR "Pass -DAPP_ROOT=<path-to-firmware/6843/breath-rate-6843aop>")
endif()

list(APPEND CMAKE_MODULE_PATH "${BUILD_TOOLS_DIR}/cmake")
include(TiMmwaveSdk)
include(devices/xwr68xx)
include(boards/iwr6843aop)

ti_mmwave_find_tools()

set(MSS_SOURCES
    "${APP_ROOT}/antenna_geometry.c"
    "${APP_ROOT}/breath_rate.c"
    "${APP_ROOT}/data_path.c"
    "${APP_ROOT}/main.c"
    "${APP_ROOT}/mmwdemo_adcconfig.c"
    "${APP_ROOT}/mmwdemo_flash.c"
    "${APP_ROOT}/mmwdemo_monitor.c"
    "${APP_ROOT}/mmwdemo_rfparser.c"
    "${APP_ROOT}/mmw_cli.c"
    "${APP_ROOT}/mmw_lvds_stream.c"
    "${APP_ROOT}/objectdetection.c"
)

set(MSS_IMAGE "${CMAKE_BINARY_DIR}/mss/breath_rate_6843aop_mss.xer4f")
ti_mmwave_add_mss_image(
    TARGET breath_mss
    OUTPUT "${MSS_IMAGE}"
    CONFIG "${APP_ROOT}/mmw.cfg"
    LINKER "${APP_ROOT}/mss_mmw_linker.cmd"
    SOURCES ${MSS_SOURCES}
    INCLUDES "${APP_ROOT}"
)

ti_mmwave_add_metaimage(
    TARGET firmware_bin
    OUTPUT "${CMAKE_BINARY_DIR}/breath_rate_6843aop.bin"
    MSS_IMAGE "${MSS_IMAGE}"
    DSS_IMAGE "NULL"
    DEPENDS breath_mss
)
