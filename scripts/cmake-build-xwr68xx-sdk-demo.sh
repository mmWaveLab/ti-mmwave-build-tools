#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/lib.sh"
load_machine_env

build_dir="${BUILD_DIR:-${1:-$BUILD_ROOT/cmake-xwr68xx-docker}}"
project_dir="$BUILD_ROOT/generated-xwr68xx-sdk-mss-dss-cmake"
artifact_dir="${ARTIFACT_DIR:-$repo_dir/artifacts}"
container_project_dir="$(repo_path_for_container "$project_dir" "$repo_dir")"
container_build_dir="$(repo_path_for_container "$build_dir" "$repo_dir")"

rm -rf "$build_dir"
rm -rf "$project_dir"
mkdir -p "$build_dir" "$artifact_dir"
"$repo_dir/scripts/create-mmwave-app.sh" xwr68xx-sdk-mss-dss-cmake \
  --profile xwr6843isk-mss-dss \
  --dir "$project_dir" \
  --image "${SDK_FULL_IMAGE:-meowpas/ti-mmwave-sdk:03.06.02}" \
  --force >/dev/null

docker_sdk_run "$repo_dir" \
  bash -lc 'source /usr/local/bin/ti-sdk-env && cmake -S "$0" -B "$1" -G Ninja -DTI_ROOT=/opt/ti && cmake --build "$1" --target firmware' \
  "$container_project_dir" \
  "$container_build_dir"

cp "$build_dir"/app/xwr68xx_mmw_demo.bin "$artifact_dir"/xwr68xx_mmw_demo.docker.bin
sha256sum "$artifact_dir"/xwr68xx_mmw_demo.docker.bin
ls -lh "$artifact_dir"/xwr68xx_mmw_demo.docker.bin
