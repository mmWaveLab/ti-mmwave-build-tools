#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/lib.sh"
load_machine_env

project="${PROJECT:-${1:-}}"
if [[ -z "$project" ]]; then
  printf 'Set PROJECT=examples/name or pass a project path.\n' >&2
  exit 2
fi

case "$project" in
  /*) project_dir="$project" ;;
  *) project_dir="$repo_dir/$project" ;;
esac

if [[ ! -f "$project_dir/CMakeLists.txt" ]]; then
  printf 'Missing CMake project: %s\n' "$project_dir" >&2
  exit 2
fi

build_dir="${BUILD_DIR:-$BUILD_ROOT/projects/$(basename "$project_dir")-docker}"
container_project_dir="$(repo_path_for_container "$project_dir" "$repo_dir")"
container_build_dir="$(repo_path_for_container "$build_dir" "$repo_dir")"

rm -rf "$build_dir"
mkdir -p "$build_dir"

docker_sdk_run "$repo_dir" \
  bash -lc 'source /usr/local/bin/ti-sdk-env && cmake -S "$0" -B "$1" -G Ninja -DTI_ROOT=/home/kj/ti && cmake --build "$1" --target firmware' \
  "$container_project_dir" \
  "$container_build_dir"
