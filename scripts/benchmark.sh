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

printf '# TI mmWave Docker Benchmark\n\n' >"$report"
printf '%s\n' "- Timestamp UTC: \`$timestamp\`" >>"$report"
printf '%s\n\n' "- Host: \`$(hostname)\`" >>"$report"

printf '## Docker CMake+Ninja\n\n' >>"$report"
/usr/bin/time -f '%e' -o "$docker_time_file" \
  "$repo_dir/scripts/cmake-build-xwr68xx-sdk-demo.sh" >"$docker_log" 2>&1
docker_time="$(cat "$docker_time_file")"
cat "$docker_log" >>"$report"
printf '\nDocker elapsed seconds: `%s`\n\n' "$docker_time" >>"$report"

printf '## Native CMake+Ninja\n\n' >>"$report"
/usr/bin/time -f '%e' -o "$native_time_file" \
  "$repo_dir/scripts/native-cmake-build-xwr68xx-sdk-demo.sh" >"$native_log" 2>&1
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
