#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/lib.sh"
load_machine_env

docker run --rm \
  -v "$HOST_TI_ROOT":/opt/ti:ro \
  "$IMAGE" \
  check-ti-linux

rm -rf "$BUILD_ROOT/test-configure"
source "$repo_dir/scripts/ti-sdk-env.sh"
cmake -S "$repo_dir/examples/xwr68xx-sdk-mss-dss-cmake" \
  -B "$BUILD_ROOT/test-configure" \
  -G Ninja \
  -DTI_ROOT="$TI_ROOT"
cmake --build "$BUILD_ROOT/test-configure" --target help >/dev/null

printf 'PASS: toolchain check and CMake/Ninja configure succeeded.\n'
