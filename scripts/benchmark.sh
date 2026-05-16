#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/lib.sh"
load_machine_env

report_dir="${REPORT_DIR:-$repo_dir/reports}"
artifact_dir="${ARTIFACT_DIR:-$repo_dir/artifacts}"
mkdir -p "$report_dir" "$artifact_dir"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
report="$report_dir/benchmark-$timestamp.md"

docker_log="$(mktemp)"
native_log="$(mktemp)"
docker_time_file="$(mktemp)"
native_time_file="$(mktemp)"
cleanup() {
  rm -f "$docker_log" "$native_log" "$docker_time_file" "$native_time_file"
}
trap cleanup EXIT

measure_command() {
  local time_file="$1"
  local log_file="$2"
  shift 2
  local start
  local end
  local rc

  start="$(date +%s)"
  set +e
  "$@" >"$log_file" 2>&1
  rc=$?
  set -e
  end="$(date +%s)"
  printf '%s\n' "$((end - start))" >"$time_file"
  return "$rc"
}

printf '# TI mmWave Docker Benchmark\n\n' >"$report"
printf '%s\n' "- Timestamp UTC: \`$timestamp\`" >>"$report"
printf '%s\n\n' "- Host: \`$(hostname)\`" >>"$report"

printf '## Docker CMake+Ninja\n\n' >>"$report"
if ! measure_command "$docker_time_file" "$docker_log" "$repo_dir/scripts/cmake-build-xwr68xx-sdk-demo.sh"; then
  cat "$docker_log" >>"$report"
  printf '\nResult: `FAIL`, Docker CMake+Ninja build failed.\n' >>"$report"
  printf '%s\n' "$report"
  exit 2
fi
docker_time="$(cat "$docker_time_file")"
cat "$docker_log" >>"$report"
printf '\nDocker elapsed seconds: `%s`\n\n' "$docker_time" >>"$report"

printf '## Native CMake+Ninja\n\n' >>"$report"
if ! measure_command "$native_time_file" "$native_log" "$repo_dir/scripts/native-cmake-build-xwr68xx-sdk-demo.sh"; then
  cat "$native_log" >>"$report"
  printf '\nResult: `FAIL`, native CMake+Ninja build failed.\n' >>"$report"
  printf '%s\n' "$report"
  exit 2
fi
native_time="$(cat "$native_time_file")"
cat "$native_log" >>"$report"
printf '\nNative elapsed seconds: `%s`\n\n' "$native_time" >>"$report"

docker_bin="$artifact_dir/xwr68xx_mmw_demo.docker.bin"
native_bin="$artifact_dir/xwr68xx_mmw_demo.native.bin"

printf '## Artifact Check\n\n' >>"$report"
sha256sum "$docker_bin" "$native_bin" >>"$report"
if cmp -s "$docker_bin" "$native_bin"; then
  printf '\nResult: `PASS`, Docker and native artifacts are identical.\n' >>"$report"
else
  printf '\nResult: `FAIL`, Docker and native artifacts differ.\n' >>"$report"
  exit 2
fi

printf '%s\n' "$report"
