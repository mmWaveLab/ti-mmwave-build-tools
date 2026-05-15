cmake_minimum_required(VERSION 3.20)
project(ti_mmwave_docker_sdk_tests NONE)

enable_testing()

set(TI_ROOT "$ENV{TI_ROOT}" CACHE PATH "TI SDK/tool root")
if(NOT TI_ROOT)
  set(TI_ROOT "/opt/ti" CACHE PATH "TI SDK/tool root" FORCE)
endif()

add_test(
  NAME configure_xwr68xx_mss_dss
  COMMAND "${CMAKE_COMMAND}"
    -S "${CMAKE_CURRENT_LIST_DIR}/examples/xwr68xx-sdk-mss-dss-cmake"
    -B "${CMAKE_CURRENT_BINARY_DIR}/configure_xwr68xx_mss_dss"
    -G Ninja
    -DTI_ROOT=${TI_ROOT}
)

add_test(
  NAME build_xwr68xx_mss_dss
  COMMAND "${CMAKE_COMMAND}"
    --build "${CMAKE_CURRENT_BINARY_DIR}/configure_xwr68xx_mss_dss"
    --target firmware
)

set_tests_properties(build_xwr68xx_mss_dss PROPERTIES DEPENDS configure_xwr68xx_mss_dss)
