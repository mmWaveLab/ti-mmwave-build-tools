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

build_dir="${BUILD_DIR:-$BUILD_ROOT/projects/$(basename "$project_dir")-native}"

rm -rf "$build_dir"
mkdir -p "$build_dir"

source "$repo_dir/scripts/ti-sdk-env.sh"
cmake -S "$project_dir" -B "$build_dir" -G Ninja -DTI_ROOT="$TI_ROOT"
cmake --build "$build_dir" --target firmware
