#!/usr/bin/env bash

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

load_machine_env() {
  local repo_dir
  repo_dir="$(repo_root)"
  if [[ -f "$repo_dir/config/machine.env" ]]; then
    # shellcheck disable=SC1091
    source "$repo_dir/config/machine.env"
  fi

  export SDK_FULL_IMAGE="${SDK_FULL_IMAGE:-meowpas/ti-mmwave-sdk:03.06.02}"
  export TI_ROOT="${TI_ROOT:-/opt/ti}"
  export HOST_TI_ROOT="${HOST_TI_ROOT:-$TI_ROOT}"
  export BUILD_ROOT="${BUILD_ROOT:-$repo_dir/build}"
  export ARTIFACT_DIR="${ARTIFACT_DIR:-$repo_dir/artifacts}"
  export REPORT_DIR="${REPORT_DIR:-$repo_dir/reports}"
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    printf 'Docker is required for this command, but the docker executable was not found in PATH.\n' >&2
    printf 'Install Docker or run this command on a machine with Docker access.\n' >&2
    return 2
  fi
}

require_host_ti_root() {
  local required=(
    "$HOST_TI_ROOT/mmwave_sdk_03_06_02_00-LTS/packages"
    "$HOST_TI_ROOT/mmwave_sdk_03_06_02_00-LTS/packages/scripts/unix/generateMetaImage.sh"
    "$HOST_TI_ROOT/ti-cgt-arm_16.9.6.LTS/bin/armcl"
    "$HOST_TI_ROOT/ti-cgt-c6000_8.3.3/bin/cl6x"
    "$HOST_TI_ROOT/xdctools_3_50_08_24_core/xs"
  )
  local missing=0
  for path in "${required[@]}"; do
    if [[ ! -e "$path" ]]; then
      printf 'missing: %s\n' "$path" >&2
      missing=1
    fi
  done
  if (( missing )); then
    printf 'Set HOST_TI_ROOT in config/machine.env or export it before running.\n' >&2
    return 2
  fi
}

repo_path_for_container() {
  local host_path="$1"
  local repo_dir="$2"
  case "$host_path" in
    "$repo_dir"/*) printf '/work/ti-mmwave-build-tools-docker/%s\n' "${host_path#$repo_dir/}" ;;
    "$repo_dir") printf '/work/ti-mmwave-build-tools-docker\n' ;;
    *)
      printf 'Path must be under repo directory: %s\n' "$host_path" >&2
      return 2
      ;;
  esac
}

docker_sdk_run() {
  local repo_dir="$1"
  shift
  require_docker
  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -e TI_ROOT=/opt/ti \
    -v "$repo_dir":/work/ti-mmwave-build-tools-docker \
    "$SDK_FULL_IMAGE" \
    "$@"
}
