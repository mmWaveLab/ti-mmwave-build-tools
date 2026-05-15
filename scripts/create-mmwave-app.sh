#!/usr/bin/env bash
set -euo pipefail

script_path="${BASH_SOURCE[0]}"
if command -v readlink >/dev/null 2>&1; then
  resolved_path="$(readlink -f "$script_path" 2>/dev/null || true)"
  [[ -n "$resolved_path" ]] && script_path="$resolved_path"
fi
script_dir="$(cd "$(dirname "$script_path")" && pwd)"
repo_dir="$(cd "$script_dir/.." && pwd)"
template_dir="$repo_dir/templates/mmwave-cmake-project"

usage() {
  cat <<'USAGE'
Usage:
  create-mmwave-app NAME [--device xwr68xx] [--dir DIR] [--image IMAGE] [--force]

Examples:
  create-mmwave-app people-count-6843 --device xwr68xx
  create-mmwave-app vital-signs-1843 --device xwr18xx --dir /work/vital-signs-1843

This creates a clean standalone project by forking a TI mmWave SDK demo from
the SDK-full Docker image. The generated project builds with CMake+Ninja inside
the same SDK-full Docker image.

Supported --device values:
  xwr16xx, xwr18xx, xwr64xx, xwr64xx_compression, xwr68xx
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 2
fi

name="$1"
shift
device="xwr68xx"
out_dir=""
force=0
sdk_image="${SDK_IMAGE:-meowkj/ti-mmwave-sdk:03.06.02-local}"
ti_root="${TI_ROOT:-/opt/ti}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)
      device="${2:-}"
      shift 2
      ;;
    --dir|--out)
      out_dir="${2:-}"
      shift 2
      ;;
    --image)
      sdk_image="${2:-}"
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
sdk_demo_dir="$ti_root/mmwave_sdk_03_06_02_00-LTS/packages/$sdk_demo_rel"

if [[ -z "$out_dir" ]]; then
  out_dir="$PWD/$name"
fi

case "$out_dir" in
  /*) abs_out="$out_dir" ;;
  *) abs_out="$PWD/$out_dir" ;;
esac

if [[ -e "$abs_out" && "$force" -ne 1 ]]; then
  printf 'Output already exists: %s\n' "$abs_out" >&2
  printf 'Use --force to overwrite generated template files.\n' >&2
  exit 2
fi

if [[ ! -f "$sdk_demo_dir/makefile" ]]; then
  printf 'SDK demo makefile not found: %s/makefile\n' "$sdk_demo_dir" >&2
  printf 'Run this generator inside the SDK-full Docker image, or set TI_ROOT.\n' >&2
  exit 2
fi

rm -rf "$abs_out"
mkdir -p "$abs_out/app"
cp -a "$sdk_demo_dir/." "$abs_out/app/"
mkdir -p "$abs_out/src"
printf 'Project-local sources can live here when they are not part of the forked TI demo tree.\n' > "$abs_out/src/README.md"

render() {
  local src="$1"
  local dst="$2"
  sed \
    -e "s|@PROJECT_NAME@|$name|g" \
    -e "s|@SDK_DEVICE@|$sdk_device|g" \
    -e "s|@SDK_DEVICE_TYPE@|$device|g" \
    -e "s|@SDK_DEMO_REL@|$sdk_demo_rel|g" \
    -e "s|@OUTPUT_BIN@|$output_bin|g" \
    -e "s|@SDK_IMAGE@|$sdk_image|g" \
    "$src" > "$dst"
}

render "$template_dir/CMakeLists.txt.in" "$abs_out/CMakeLists.txt"
render "$template_dir/Makefile.in" "$abs_out/Makefile"
render "$template_dir/README.md.in" "$abs_out/README.md"
cp "$template_dir/gitignore.in" "$abs_out/.gitignore"

mss="no"
dss="no"
[[ -d "$abs_out/app/mss" ]] && mss="yes"
[[ -d "$abs_out/app/dss" ]] && dss="yes"

cat <<EOF
Created TI mmWave fork project: $abs_out
Device template: $device ($sdk_device)
Forked SDK demo: $sdk_demo_rel
Cores: MSS=$mss DSS=$dss
Docker image: $sdk_image

Next:
  cd "$abs_out"
  make build
EOF
