#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/lib.sh"
load_machine_env

build_dir="${BUILD_DIR:-${1:-$BUILD_ROOT/cmake-xwr68xx-docker}}"
artifact_dir="${ARTIFACT_DIR:-$repo_dir/artifacts}"
container_build_dir="$(repo_path_for_container "$build_dir" "$repo_dir")"

rm -rf "$build_dir"
mkdir -p "$build_dir" "$artifact_dir"

docker_sdk_run "$repo_dir" \
  bash -lc 'source /usr/local/bin/ti-sdk-env && cmake -S /work/ti-mmwave-build-tools-docker/examples/xwr68xx-sdk-mss-dss-cmake -B "$0" -G Ninja -DTI_ROOT=/home/kj/ti && cmake --build "$0" --target firmware' \
  "$container_build_dir"

cp "$build_dir"/xwr68xx_mmw/xwr68xx_mmw_demo.bin "$artifact_dir"/xwr68xx_mmw_demo.docker.bin
sha256sum "$artifact_dir"/xwr68xx_mmw_demo.docker.bin
ls -lh "$artifact_dir"/xwr68xx_mmw_demo.docker.bin
