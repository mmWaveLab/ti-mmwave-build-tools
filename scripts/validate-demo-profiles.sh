#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/lib.sh"
profiles_file="${DEMO_PROFILES_FILE:-$repo_dir/config/demo-profiles.tsv}"
image="${SDK_FULL_IMAGE:-meowpas/ti-mmwave-sdk:03.06.02}"
work_dir="${PROFILE_VALIDATION_WORK:-$repo_dir/build/demo-profile-validation}"
artifact_root="${ARTIFACT_DIR:-$repo_dir/artifacts}/demo-profile-validation"
report_dir="${REPORT_DIR:-$repo_dir/reports}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
report="$report_dir/demo-profile-validation-$timestamp.md"
profiles_filter="${DEMO_PROFILES:-}"
jobs="${PROFILE_VALIDATION_JOBS:-all}"
jobs_label="$jobs"

require_docker
mkdir -p "$work_dir" "$artifact_root" "$report_dir"

case "$jobs" in
  all)
    jobs=9999
    ;;
  auto)
    jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '1')"
    jobs_label="auto:$jobs"
    ;;
  *)
    if [[ ! "$jobs" =~ ^[0-9]+$ || "$jobs" -lt 1 ]]; then
      printf 'PROFILE_VALIDATION_JOBS must be all, auto, or a positive integer, got: %s\n' "$jobs" >&2
      exit 2
    fi
    ;;
esac

docker run --rm \
  -v "$work_dir":/work \
  "$image" \
  bash -lc 'rm -rf /work/*'

docker run --rm "$image" check-ti-linux

printf '# Demo Profile SHA-256 Validation\n\n' >"$report"
printf '%s\n' "- Timestamp UTC: \`$timestamp\`" >>"$report"
printf '%s\n' "- SDK-full image: \`$image\`" >>"$report"
printf '%s\n' "- Profile manifest: \`$profiles_file\`" >>"$report"
printf '%s\n' "- Parallel profile jobs: \`$jobs_label\`" >>"$report"
printf '%s\n\n' "- Work directory: \`$work_dir\`" >>"$report"
printf '%s\n\n' "- Result rule: SDK-backed starter profiles expose flashable \`.bin\` images and require matching direct/fork SHA-256." >>"$report"
printf '| Profile | Direct SDK SHA-256 | Fork CMake SHA-256 | Result | Output |\n' >>"$report"
printf '|---|---|---|---:|---|\n' >>"$report"

profile_enabled() {
  local candidate="$1"
  [[ -z "$profiles_filter" ]] && return 0
  local selected
  for selected in $profiles_filter; do
    [[ "$selected" == "$candidate" ]] && return 0
  done
  return 1
}

build_direct() {
  local profile="$1"
  local source_rel="$2"
  local sdk_device="$3"
  local device_template="$4"
  local output_bin="$5"
  local build_target="$6"
  local clean_target="$7"
  local make_vars="$8"

  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -v "$work_dir":/work \
    -w /work \
    "$image" \
    bash -lc '
      set -euo pipefail
      profile="$1"
      source_rel="$2"
      sdk_device="$3"
      device_template="$4"
      output_bin="$5"
      build_target="$6"
      clean_target="$7"
      make_vars="$8"
      src="/opt/ti/mmwave_sdk_03_06_02_00-LTS/packages/$source_rel"
      dst="/work/direct-$profile"
      extra_args=()
      if [[ "$make_vars" != "-" && -n "$make_vars" ]]; then
        extra_args+=("$make_vars")
      fi
      rm -rf "$dst"
      cp -a "$src" "$dst"
      cd "$dst"
      make -f makefile "$clean_target" \
        CCS_MAKEFILE_BASED_BUILD=1 \
        MMWAVE_SDK_DEVICE="$sdk_device" \
        MMWAVE_SDK_DEVICE_TYPE="$device_template" \
        MMWAVE_SDK_TOOLS_INSTALL_PATH=/opt/ti \
        MMWAVE_SDK_INSTALL_PATH=/opt/ti/mmwave_sdk_03_06_02_00-LTS/packages \
        "${extra_args[@]}"
      make -f makefile "$build_target" \
        CCS_MAKEFILE_BASED_BUILD=1 \
        MMWAVE_SDK_DEVICE="$sdk_device" \
        MMWAVE_SDK_DEVICE_TYPE="$device_template" \
        MMWAVE_SDK_TOOLS_INSTALL_PATH=/opt/ti \
        MMWAVE_SDK_INSTALL_PATH=/opt/ti/mmwave_sdk_03_06_02_00-LTS/packages \
        "${extra_args[@]}"
      if [[ ! -f "$output_bin" && "$output_bin" == *.bin ]]; then
        case "$device_template" in
          xwr18xx)
            shmem_alloc="0x00000008"
            radarss="/opt/ti/mmwave_sdk_03_06_02_00-LTS/firmware/radarss/xwr18xx_radarss_rprc.bin"
            ;;
          *)
            shmem_alloc="0x00000006"
            radarss="/opt/ti/mmwave_sdk_03_06_02_00-LTS/firmware/radarss/xwr6xxx_radarss_rprc.bin"
            ;;
        esac
        mss_out="${output_bin%.bin}_mss.xer4f"
        test -f "$mss_out"
        MMWAVE_SDK_INSTALL_PATH=/opt/ti/mmwave_sdk_03_06_02_00-LTS/packages \
          /opt/ti/mmwave_sdk_03_06_02_00-LTS/packages/scripts/unix/generateMetaImage.sh "$output_bin" "$shmem_alloc" "$mss_out" "$radarss" NULL
      fi
      test -f "$output_bin"
      sha256sum "$output_bin" > "/work/direct-$profile.sha256"
    ' _ "$profile" "$source_rel" "$sdk_device" "$device_template" "$output_bin" "$build_target" "$clean_target" "$make_vars"
}

build_fork() {
  local profile="$1"
  local output_bin="$2"

  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -v "$repo_dir":/repo:ro \
    -v "$work_dir":/work \
    -w /work \
    "$image" \
    /repo/scripts/create-mmwave-app.sh "fork-$profile" --profile "$profile" --image "$image"

  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -v "$repo_dir":/repo:ro \
    -v "$work_dir/fork-$profile":/work/app \
    -w /work/app \
    "$image" \
    bash -lc '
      set -euo pipefail
      output_bin="$1"
      cmake -S . -B build -G Ninja -DTI_MMWAVE_TOOLS_ROOT=/repo -DTI_ROOT=/opt/ti
      cmake --build build --target firmware
      test -f "build/app/$output_bin"
      sha256sum "build/app/$output_bin" > "/work/app/fork.sha256"
    ' _ "$output_bin"
}

validate_one_profile() {
  local profile="$1"
  local board="$2"
  local core_mode="$3"
  local source_kind="$4"
  local source_rel="$5"
  local sdk_device_type="$6"
  local sdk_device="$7"
  local output_bin="$8"
  local build_entry_kind="$9"
  local build_entry="${10}"
  local clean_target="${11}"
  local make_vars="${12}"
  local status="${13}"
  local cores="${14}"
  local artifact_dir="$artifact_root/$profile"
  local direct_log="$report_dir/demo-profile-direct-$profile-$timestamp.log"
  local fork_log="$report_dir/demo-profile-fork-$profile-$timestamp.log"
  local result_file="$work_dir/result-$profile.tsv"
  local failure_file="$work_dir/failure-$profile.md"
  local direct_rc=0
  local fork_rc=0
  local direct_sha
  local fork_sha
  local result

  rm -rf "$artifact_dir"
  mkdir -p "$artifact_dir"

  if [[ "$source_kind" != "sdk-make" || "$status" != "validated" ]]; then
    printf '%s\t%s\t%s\t%s\t%s\n' "$profile" "SKIPPED" "SKIPPED" "SKIP" "$output_bin" >"$result_file"
    return 0
  fi

  if [[ "$build_entry_kind" != "make-target" ]]; then
    printf 'Profile %s is sdk-make but does not expose a make target: %s:%s\n' "$profile" "$build_entry_kind" "$build_entry" >"$direct_log"
    {
      printf '\n## Failure: `%s`\n\n' "$profile"
      printf -- '- Direct log: `%s`\n' "$direct_log"
      printf -- '- Reason: SDK make profiles must use `make-target` build entries.\n'
    } >"$failure_file"
    printf '%s\t%s\t%s\t%s\t%s\n' "$profile" "FAILED" "FAILED" "FAIL" "$output_bin" >"$result_file"
    return 0
  fi

  build_direct "$profile" "$source_rel" "$sdk_device" "$sdk_device_type" "$output_bin" "$build_entry" "$clean_target" "$make_vars" >"$direct_log" 2>&1 || direct_rc=$?
  if (( direct_rc == 0 )); then
    cp "$work_dir/direct-$profile/$output_bin" "$artifact_dir/direct-$output_bin"
    direct_sha="$(awk '{print $1}' "$work_dir/direct-$profile.sha256")"
  else
    direct_sha="FAILED"
  fi

  build_fork "$profile" "$output_bin" >"$fork_log" 2>&1 || fork_rc=$?
  if (( fork_rc == 0 )); then
    cp "$work_dir/fork-$profile/build/app/$output_bin" "$artifact_dir/fork-$output_bin"
    fork_sha="$(awk '{print $1}' "$work_dir/fork-$profile/fork.sha256")"
  else
    fork_sha="FAILED"
  fi

  if (( direct_rc == 0 && fork_rc == 0 )) && [[ "$direct_sha" == "$fork_sha" ]]; then
    result="PASS"
  else
    result="FAIL"
  fi

  printf '%s\t%s\t%s\t%s\t%s\n' "$profile" "$direct_sha" "$fork_sha" "$result" "$output_bin" >"$result_file"

  if [[ "$result" != "PASS" ]]; then
    {
      printf '\n## Failure: `%s`\n\n' "$profile"
      printf -- '- Direct log: `%s`\n' "$direct_log"
      printf -- '- Fork log: `%s`\n' "$fork_log"
    } >"$failure_file"
  else
    rm -f "$failure_file"
  fi
}

overall=0
running=0
pids=()
profiles=()

wait_for_slot() {
  local pid
  local idx
  while (( running >= jobs )); do
    pid="${pids[0]}"
    wait "$pid" || overall=1
    pids=("${pids[@]:1}")
    running=$((running - 1))
  done
}

while IFS=$'\t' read -r profile board core_mode source_kind source_rel sdk_device_type sdk_device output_bin cores build_entry_kind build_entry clean_target make_vars config_profiles status summary; do
  [[ -z "${profile:-}" || "$profile" == \#* ]] && continue
  profile_enabled "$profile" || continue

  wait_for_slot
  profiles+=("$profile")
  validate_one_profile "$profile" "$board" "$core_mode" "$source_kind" "$source_rel" "$sdk_device_type" "$sdk_device" "$output_bin" "$build_entry_kind" "$build_entry" "$clean_target" "$make_vars" "$status" "$cores" &
  pids+=("$!")
  running=$((running + 1))
done < "$profiles_file"

for pid in "${pids[@]}"; do
  wait "$pid" || overall=1
done

for profile in "${profiles[@]}"; do
  result_file="$work_dir/result-$profile.tsv"
  if [[ ! -f "$result_file" ]]; then
    printf '| `%s` | `FAILED` | `FAILED` | FAIL | `missing result file` |\n' "$profile" >>"$report"
    overall=1
    continue
  fi
  IFS=$'\t' read -r profile_result direct_sha fork_sha result output_bin < "$result_file"
  printf '| `%s` | `%s` | `%s` | %s | `%s` |\n' \
    "$profile_result" "$direct_sha" "$fork_sha" "$result" "$output_bin" >>"$report"
  if [[ "$result" != "PASS" && "$result" != "SKIP" ]]; then
    overall=1
    cat "$work_dir/failure-$profile.md" >>"$report"
  fi
done

printf '\nReport: %s\n' "$report"
exit "$overall"
