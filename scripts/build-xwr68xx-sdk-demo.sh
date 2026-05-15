#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/lib.sh"
load_machine_env

work_dir="${BUILD_DIR:-${1:-$BUILD_ROOT/docker-mmw-cleanbuild}}"
artifact_dir="${ARTIFACT_DIR:-$repo_dir/artifacts}"

rm -rf "$work_dir"
mkdir -p "$(dirname "$work_dir")"
mkdir -p "$artifact_dir"
require_host_ti_root
cp -a "$HOST_TI_ROOT/mmwave_sdk_03_06_02_00-LTS/packages/ti/demo/xwr68xx/mmw" "$work_dir"

common_args=(
  CCS_MAKEFILE_BASED_BUILD=1
  MMWAVE_SDK_DEVICE=iwr68xx
  MMWAVE_SDK_TOOLS_INSTALL_PATH=/home/kj/ti
  MMWAVE_SDK_INSTALL_PATH=/home/kj/ti/mmwave_sdk_03_06_02_00-LTS/packages
)

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  -v "$HOST_TI_ROOT":/home/kj/ti:ro \
  -v "$work_dir":/work/mmw \
  "$IMAGE" \
  bash -lc 'cd /work/mmw && make -f makefile clean "$@" && make -f makefile all "$@"' \
  _ "${common_args[@]}"

cp "$work_dir"/xwr68xx_mmw_demo.bin "$artifact_dir"/xwr68xx_mmw_demo.make-docker.bin
sha256sum "$artifact_dir"/xwr68xx_mmw_demo.make-docker.bin
ls -lh "$artifact_dir"/xwr68xx_mmw_demo.make-docker.bin
