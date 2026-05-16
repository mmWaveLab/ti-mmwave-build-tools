cmake_minimum_required(VERSION 3.20)
project(ti_mmwave_build_tools_smoke NONE)

enable_testing()

find_program(BASH_EXE bash REQUIRED)
find_package(Python3 REQUIRED COMPONENTS Interpreter)

add_test(
  NAME validate_starter_demos
  COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_LIST_DIR}/scripts/validate-starter-demos.py"
)

add_test(
  NAME list_starter_profiles
  COMMAND "${BASH_EXE}" "${CMAKE_CURRENT_LIST_DIR}/scripts/create-mmwave-app.sh" --list-profiles
)
