#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/lib.sh"
load_machine_env

build_dir="${BUILD_DIR:-${1:-$BUILD_ROOT/cmake-xwr68xx-native}}"
project_dir="$BUILD_ROOT/generated-xwr68xx-sdk-mss-dss-cmake-native"
artifact_dir="${ARTIFACT_DIR:-$repo_dir/artifacts}"

source "$repo_dir/scripts/ti-sdk-env.sh"

rm -rf "$build_dir"
rm -rf "$project_dir"
mkdir -p "$build_dir" "$artifact_dir"
"$repo_dir/scripts/create-mmwave-app.sh" xwr68xx-sdk-mss-dss-cmake-native \
  --profile xwr6843isk-mss-dss \
  --dir "$project_dir" \
  --image "${SDK_FULL_IMAGE:-meowpas/ti-mmwave-sdk:03.06.02}" \
  --force >/dev/null

cmake -S "$project_dir" \
  -B "$build_dir" \
  -G Ninja \
  -DTI_ROOT="$TI_ROOT"
cmake --build "$build_dir" --target firmware

cp "$build_dir"/app/xwr68xx_mmw_demo.bin "$artifact_dir"/xwr68xx_mmw_demo.native.bin
sha256sum "$artifact_dir"/xwr68xx_mmw_demo.native.bin
ls -lh "$artifact_dir"/xwr68xx_mmw_demo.native.bin
