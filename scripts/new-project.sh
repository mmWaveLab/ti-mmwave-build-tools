#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template_dir="$repo_dir/templates/mmwave-cmake-project"

usage() {
  cat <<'USAGE'
Usage:
  scripts/new-project.sh NAME [--device xwr68xx] [--out DIR] [--force]

Examples:
  scripts/new-project.sh people-count-6843 --device xwr68xx
  scripts/new-project.sh vital-signs-1843 --device xwr18xx --out examples/vital-signs-1843

Supported --device values:
  xwr16xx, xwr18xx, xwr64xx, xwr64xx_compression, xwr68xx
USAGE
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 2
fi

name="$1"
shift
device="xwr68xx"
out_dir=""
force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)
      device="${2:-}"
      shift 2
      ;;
    --out)
      out_dir="${2:-}"
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ ! "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  printf 'Invalid project name: %s\n' "$name" >&2
  printf 'Use letters, numbers, dot, underscore, and hyphen only.\n' >&2
  exit 2
fi

case "$device" in
  xwr16xx)
    sdk_device="iwr16xx"
    output_bin="xwr16xx_mmw_demo.bin"
    ;;
  xwr18xx)
    sdk_device="iwr18xx"
    output_bin="xwr18xx_mmw_demo.bin"
    ;;
  xwr64xx)
    sdk_device="iwr68xx"
    output_bin="xwr64xx_mmw_demo.bin"
    ;;
  xwr64xx_compression)
    sdk_device="iwr68xx"
    output_bin="xwr64xx_compression_mmw_demo.bin"
    ;;
  xwr68xx)
    sdk_device="iwr68xx"
    output_bin="xwr68xx_mmw_demo.bin"
    ;;
  *)
    printf 'Unsupported device template: %s\n' "$device" >&2
    usage >&2
    exit 2
    ;;
esac

sdk_demo_rel="ti/demo/$device/mmw"
if [[ -z "$out_dir" ]]; then
  out_dir="examples/$name"
fi

case "$out_dir" in
  /*) abs_out="$out_dir" ;;
  *) abs_out="$repo_dir/$out_dir" ;;
esac

if [[ -e "$abs_out" && "$force" -ne 1 ]]; then
  printf 'Output already exists: %s\n' "$abs_out" >&2
  printf 'Use --force to overwrite generated template files.\n' >&2
  exit 2
fi

mkdir -p "$abs_out"

tools_cmake_dir="$repo_dir/cmake"
case "$abs_out" in
  "$repo_dir"/*)
    rel_project_path="${abs_out#$repo_dir/}"
    rel_cmake_path="$(python3 - "$abs_out" "$repo_dir/cmake" <<'PY'
import os
import sys

print(os.path.relpath(sys.argv[2], sys.argv[1]))
PY
)"
    tools_cmake_dir="\${CMAKE_CURRENT_LIST_DIR}/$rel_cmake_path"
    ;;
  "$repo_dir")
    rel_project_path="."
    tools_cmake_dir="\${CMAKE_CURRENT_LIST_DIR}/cmake"
    ;;
  *)
    rel_project_path="$abs_out"
    ;;
esac

render() {
  local src="$1"
  local dst="$2"
  sed \
    -e "s|@PROJECT_NAME@|$name|g" \
    -e "s|@PROJECT_PATH@|$rel_project_path|g" \
    -e "s|@TOOLS_CMAKE_DIR@|$tools_cmake_dir|g" \
    -e "s|@SDK_DEVICE@|$sdk_device|g" \
    -e "s|@SDK_DEVICE_TYPE@|$device|g" \
    -e "s|@SDK_DEMO_REL@|$sdk_demo_rel|g" \
    -e "s|@OUTPUT_BIN@|$output_bin|g" \
    "$src" > "$dst"
}

render "$template_dir/CMakeLists.txt.in" "$abs_out/CMakeLists.txt"
render "$template_dir/Makefile.in" "$abs_out/Makefile"
render "$template_dir/README.md.in" "$abs_out/README.md"
mkdir -p "$abs_out/src"
printf 'Local source overlays can live here after the SDK reference demo is reproducible.\n' > "$abs_out/src/README.md"

printf 'Created mmWave CMake project: %s\n' "$abs_out"
printf 'Device template: %s (%s)\n' "$device" "$sdk_device"
printf 'Build with: make project-docker PROJECT=%s\n' "$rel_project_path"
