#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/lib.sh"
load_machine_env
require_host_ti_root

devices_file="${DEVICES_FILE:-$repo_dir/config/devices.tsv}"
build_root="${BUILD_ROOT:-$repo_dir/build}/device-validation"
artifact_root="${ARTIFACT_DIR:-$repo_dir/artifacts}/device-validation"
report_dir="${REPORT_DIR:-$repo_dir/reports}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
report="$report_dir/device-validation-$timestamp.md"

mkdir -p "$build_root" "$artifact_root" "$report_dir"

printf '# TI mmWave Device Validation\n\n' >"$report"
printf '%s\n' "- Timestamp UTC: \`$timestamp\`" >>"$report"
printf '%s\n' "- Docker image: \`$IMAGE\`" >>"$report"
printf '%s\n\n' "- Host TI root: \`$HOST_TI_ROOT\`" >>"$report"
printf '| Device ID | SDK Device | Result | Seconds | Firmware Outputs |\n' >>"$report"
printf '|---|---|---:|---:|---|\n' >>"$report"

overall=0

while IFS=$'\t' read -r id sdk_demo sdk_device label; do
  [[ -z "${id:-}" || "$id" == \#* ]] && continue

  src="$HOST_TI_ROOT/mmwave_sdk_03_06_02_00-LTS/packages/$sdk_demo"
  work_dir="$build_root/$id"
  artifact_dir="$artifact_root/$id"
  log="$report_dir/device-validation-$id-$timestamp.log"
  time_file="$(mktemp)"

  rm -rf "$work_dir" "$artifact_dir"
  mkdir -p "$work_dir" "$artifact_dir"

  if [[ ! -f "$src/makefile" ]]; then
    printf '| `%s` | `%s` | FAIL | 0 | missing makefile: `%s` |\n' "$id" "$sdk_device" "$src/makefile" >>"$report"
    overall=1
    continue
  fi

  cp -a "$src"/. "$work_dir"/

  set +e
  /usr/bin/time -f '%e' -o "$time_file" \
    docker run --rm \
      --user "$(id -u):$(id -g)" \
      -e HOME=/tmp \
      -v "$HOST_TI_ROOT:$CONTAINER_TI_ROOT:ro" \
      -v "$work_dir":/work/mmw \
      "$IMAGE" \
      bash -lc 'source /usr/local/bin/ti-sdk-env && cd /work/mmw && make -f makefile clean CCS_MAKEFILE_BASED_BUILD=1 MMWAVE_SDK_DEVICE="$0" MMWAVE_SDK_TOOLS_INSTALL_PATH=/home/kj/ti MMWAVE_SDK_INSTALL_PATH=/home/kj/ti/mmwave_sdk_03_06_02_00-LTS/packages && make -f makefile all CCS_MAKEFILE_BASED_BUILD=1 MMWAVE_SDK_DEVICE="$0" MMWAVE_SDK_TOOLS_INSTALL_PATH=/home/kj/ti MMWAVE_SDK_INSTALL_PATH=/home/kj/ti/mmwave_sdk_03_06_02_00-LTS/packages' \
      "$sdk_device" >"$log" 2>&1
  rc=$?
  set -e

  seconds="$(cat "$time_file" 2>/dev/null || printf '0')"

  if (( rc == 0 )); then
    mapfile -t bins < <(find "$work_dir" -maxdepth 1 -type f -name '*.bin' ! -name '*secure*' | sort)
    if (( ${#bins[@]} == 0 )); then
      printf '| `%s` | `%s` | FAIL | `%s` | build succeeded but no `.bin` found, log `%s` |\n' "$id" "$sdk_device" "$seconds" "$log" >>"$report"
      overall=1
      continue
    fi

    outputs=()
    for bin in "${bins[@]}"; do
      cp "$bin" "$artifact_dir/"
      hash="$(sha256sum "$artifact_dir/$(basename "$bin")" | awk '{print $1}')"
      outputs+=("$(basename "$bin") ($hash)")
    done
    printf '| `%s` | `%s` | PASS | `%s` | %s |\n' "$id" "$sdk_device" "$seconds" "$(IFS=', '; echo "${outputs[*]}")" >>"$report"
  else
    reason="$(tail -n 20 "$log" | tr '\n' ' ' | sed 's/|/ /g' | cut -c 1-240)"
    printf '| `%s` | `%s` | FAIL | `%s` | `%s`; log `%s` |\n' "$id" "$sdk_device" "$seconds" "$reason" "$log" >>"$report"
    overall=1
  fi
done <"$devices_file"

printf '\nReport: %s\n' "$report"
exit "$overall"
