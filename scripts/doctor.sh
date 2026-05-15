#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/lib.sh"
load_machine_env

status=0

check_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'ok      command %s -> %s\n' "$cmd" "$(command -v "$cmd")"
  else
    printf 'missing command %s\n' "$cmd"
    status=1
  fi
}

check_path() {
  local path="$1"
  if [[ -e "$path" ]]; then
    printf 'ok      %s\n' "$path"
  else
    printf 'missing %s\n' "$path"
    status=1
  fi
}

printf 'TI mmWave Docker SDK doctor\n'
printf 'repo: %s\n' "$repo_dir"
printf 'image: %s\n' "$IMAGE"
printf 'host TI root: %s\n' "$HOST_TI_ROOT"
printf 'container TI root: %s\n\n' "$CONTAINER_TI_ROOT"

check_cmd docker
check_cmd cmake
check_cmd ninja
check_cmd make

printf '\nSDK paths\n'
check_path "$HOST_TI_ROOT/mmwave_sdk_03_06_02_00-LTS/packages"
check_path "$HOST_TI_ROOT/mmwave_sdk_03_06_02_00-LTS/packages/scripts/unix/generateMetaImage.sh"
check_path "$HOST_TI_ROOT/mmwave_sdk_03_06_02_00-LTS/firmware/radarss/xwr6xxx_radarss_rprc.bin"
check_path "$HOST_TI_ROOT/ti-cgt-arm_16.9.6.LTS/bin/armcl"
check_path "$HOST_TI_ROOT/ti-cgt-c6000_8.3.3/bin/cl6x"
check_path "$HOST_TI_ROOT/xdctools_3_50_08_24_core/xs"

printf '\nWritable output roots\n'
mkdir -p "$BUILD_ROOT" "$ARTIFACT_DIR" "$REPORT_DIR"
check_path "$BUILD_ROOT"
check_path "$ARTIFACT_DIR"
check_path "$REPORT_DIR"

printf '\nDocker image\n'
if docker image inspect "$IMAGE" >/dev/null 2>&1; then
  docker image inspect "$IMAGE" --format 'ok      {{.RepoTags}} {{.Size}} bytes'
else
  printf 'missing image %s, run: make docker-build\n' "$IMAGE"
  status=1
fi

printf '\nContainer smoke\n'
if docker run --rm -v "$HOST_TI_ROOT:$CONTAINER_TI_ROOT:ro" "$IMAGE" check-ti-linux >/tmp/ti-mmwave-doctor-check.log 2>&1; then
  tail -n 5 /tmp/ti-mmwave-doctor-check.log
else
  cat /tmp/ti-mmwave-doctor-check.log
  status=1
fi

exit "$status"
