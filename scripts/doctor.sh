#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/lib.sh"
load_machine_env

status=0
docker_available=0

check_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'ok      command %s -> %s\n' "$cmd" "$(command -v "$cmd")"
    [[ "$cmd" == "docker" ]] && docker_available=1
  else
    printf 'missing command %s\n' "$cmd"
    status=1
  fi
  return 0
}

check_path() {
  local path="$1"
  if [[ -e "$path" ]]; then
    printf 'ok      %s\n' "$path"
  else
    printf 'missing %s\n' "$path"
    status=1
  fi
  return 0
}

printf 'TI mmWave Docker SDK doctor\n'
printf 'repo: %s\n' "$repo_dir"
printf 'SDK-full image: %s\n\n' "$SDK_FULL_IMAGE"

check_cmd docker
check_cmd cmake
check_cmd ninja
check_cmd make

printf '\nWritable output roots\n'
mkdir -p "$BUILD_ROOT" "$ARTIFACT_DIR" "$REPORT_DIR"
check_path "$BUILD_ROOT"
check_path "$ARTIFACT_DIR"
check_path "$REPORT_DIR"

printf '\nDocker image\n'
if (( ! docker_available )); then
  printf 'skip    Docker image check because docker is not available\n'
elif docker image inspect "$SDK_FULL_IMAGE" >/dev/null 2>&1; then
  docker image inspect "$SDK_FULL_IMAGE" --format 'ok      {{.RepoTags}} {{.Size}} bytes'
else
  printf 'missing image %s, run: make sdk-image or docker pull it\n' "$SDK_FULL_IMAGE"
  status=1
fi

printf '\nContainer smoke\n'
if (( ! docker_available )); then
  printf 'skip    Container smoke because docker is not available\n'
elif docker run --rm "$SDK_FULL_IMAGE" check-ti-linux >/tmp/ti-mmwave-doctor-check.log 2>&1; then
  tail -n 5 /tmp/ti-mmwave-doctor-check.log
else
  cat /tmp/ti-mmwave-doctor-check.log
  status=1
fi

exit "$status"
