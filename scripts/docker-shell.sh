#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/lib.sh"
load_machine_env

require_host_ti_root
docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  -e TI_ROOT="$CONTAINER_TI_ROOT" \
  -v "$HOST_TI_ROOT:$CONTAINER_TI_ROOT:ro" \
  -v "$repo_dir":/work/ti-mmwave-build-tools-docker \
  -w /work/ti-mmwave-build-tools-docker \
  "$IMAGE" \
  bash
