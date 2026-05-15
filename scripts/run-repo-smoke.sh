#!/usr/bin/env bash
set -euo pipefail

repo="${1:-/work/ti-mmwave-build-tools}"
TI_ROOT="${TI_ROOT:-/home/kj/ti}"
build_dir="${repo}/build-linux-smoke"
app_root="${APP_ROOT:-}"

if [[ ! -d "$repo/.git" ]]; then
  git clone --depth 1 https://github.com/mmWaveLab/ti-mmwave-build-tools.git "$repo"
fi

check-ti-linux

if [[ -n "$app_root" ]]; then
  source_dir="$repo/examples/breath-rate-6843aop"
  app_arg=(-DAPP_ROOT="$app_root")
else
  source_dir="/tmp/ti-mmwave-tool-discovery-smoke"
  mkdir -p "$source_dir"
  cat >"$source_dir/CMakeLists.txt" <<EOF
cmake_minimum_required(VERSION 3.20)
project(ti_mmwave_linux_tool_discovery_smoke NONE)
list(APPEND CMAKE_MODULE_PATH "$repo/cmake")
include(TiMmwaveSdk)
include(devices/xwr68xx)
include(boards/iwr6843aop)
ti_mmwave_find_tools()
EOF
  app_arg=()
fi

cmake -S "$source_dir" -B "$build_dir" -G Ninja \
  -DTI_ROOT="$TI_ROOT" \
  -DMMWAVE_SDK_ROOT="$TI_ROOT/mmwave_sdk_03_06_02_00-LTS" \
  -DMMWAVE_SDK_PACKAGES="$TI_ROOT/mmwave_sdk_03_06_02_00-LTS/packages" \
  -DR4F_CODEGEN_ROOT="$TI_ROOT/ti-cgt-arm_16.9.6.LTS" \
  -DC674_CODEGEN_ROOT="$TI_ROOT/ti-cgt-c6000_8.3.3" \
  -DXDC_ROOT="$TI_ROOT/xdctools_3_50_08_24_core" \
  -DBIOS_ROOT="$TI_ROOT/bios_6_73_01_01" \
  -DDSPLIB_C64PX_ROOT="$TI_ROOT/dsplib_c64Px_3_4_0_0" \
  -DMATHLIB_C674X_ROOT="$TI_ROOT/mathlib_c674x_3_1_2_1" \
  -DR4F_CC="$TI_ROOT/ti-cgt-arm_16.9.6.LTS/bin/armcl" \
  -DC674_CC="$TI_ROOT/ti-cgt-c6000_8.3.3/bin/cl6x" \
  -DXS_EXE="$TI_ROOT/xdctools_3_50_08_24_core/xs" \
  -DGENERATE_METAIMAGE="$TI_ROOT/mmwave_sdk_03_06_02_00-LTS/packages/scripts/unix/generateMetaImage.sh" \
  "${app_arg[@]}"

cmake --build "$build_dir" --target help >/tmp/ti-mmwave-build-tools-targets.txt
cat /tmp/ti-mmwave-build-tools-targets.txt

if [[ -n "$app_root" ]]; then
  printf '\nCMake Linux example configure completed: %s\n' "$build_dir"
else
  printf '\nCMake Linux tool-discovery smoke completed: %s\n' "$build_dir"
  printf 'Set APP_ROOT=/path/to/breath-rate-6843aop to run the full example configure.\n'
fi
