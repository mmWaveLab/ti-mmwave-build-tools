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

project_dir="$BUILD_ROOT/test-generated-project"
rm -rf "$BUILD_ROOT/test-configure"
rm -rf "$project_dir"
"$repo_dir/scripts/create-mmwave-app.sh" test-generated-project \
  --profile xwr6843isk-mss-dss \
  --dir "$project_dir" \
  --image "${SDK_FULL_IMAGE:-meowpas/ti-mmwave-sdk:03.06.02}" \
  --force >/dev/null

source "$repo_dir/scripts/ti-sdk-env.sh"
cmake -S "$project_dir" \
  -B "$BUILD_ROOT/test-configure" \
  -G Ninja \
  -DTI_ROOT="$TI_ROOT"
cmake --build "$BUILD_ROOT/test-configure" --target help >/dev/null

printf 'PASS: toolchain check and CMake/Ninja configure succeeded.\n'
