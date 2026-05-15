#!/usr/bin/env bash
set -euo pipefail

TI_ROOT="${TI_ROOT:-/opt/ti}"

required_paths=(
  "$TI_ROOT/mmwave_sdk_03_06_02_00-LTS/packages"
  "$TI_ROOT/mmwave_sdk_03_06_02_00-LTS/packages/scripts/unix/generateMetaImage.sh"
  "$TI_ROOT/mmwave_sdk_03_06_02_00-LTS/firmware/radarss/xwr6xxx_radarss_rprc.bin"
  "$TI_ROOT/ti-cgt-arm_16.9.6.LTS/bin/armcl"
  "$TI_ROOT/ti-cgt-c6000_8.3.3/bin/cl6x"
  "$TI_ROOT/xdctools_3_50_08_24_core/xs"
  "$TI_ROOT/bios_6_73_01_01/packages"
  "$TI_ROOT/dsplib_c64Px_3_4_0_0/packages"
  "$TI_ROOT/dsplib_c674x_3_4_0_0/packages"
  "$TI_ROOT/mathlib_c674x_3_1_2_1/packages"
)

missing=0
for path in "${required_paths[@]}"; do
  if [[ -e "$path" ]]; then
    printf 'ok      %s\n' "$path"
  else
    printf 'missing %s\n' "$path"
    missing=1
  fi
done

if (( missing )); then
  exit 2
fi

"$TI_ROOT/ti-cgt-arm_16.9.6.LTS/bin/armcl" --compiler_revision
"$TI_ROOT/ti-cgt-c6000_8.3.3/bin/cl6x" --compiler_revision
"$TI_ROOT/xdctools_3_50_08_24_core/xs" --version || true
mono --version | head -n 1

printf '\nTI Linux tool mount looks usable at %s\n' "$TI_ROOT"
