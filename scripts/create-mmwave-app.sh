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
  create-mmwave-app NAME [--profile xwr6843isk-mss-dss] [--dir DIR] [--cmake-name NAME] [--image IMAGE] [--force]
  create-mmwave-app --list-profiles

Examples:
  create-mmwave-app people-count-6843 --profile xwr6843isk-mss-dss
  create-mmwave-app vital-signs-1843 --profile xwr1843boost-mss-only --dir /work/vital-signs-1843 --cmake-name vital_signs_1843

This creates a clean standalone project by forking one of the converted demo
projects stored under demos/<profile>/app. The generated project builds with
CMake+Ninja inside the SDK-full Docker image.

Common --profile values:
  xwr6843isk-mss-only, xwr6843isk-mss-dss
  xwr6843aop-mss-only, xwr6843aop-mss-dss
  xwr1843boost-mss-only, xwr1843boost-mss-dss

Legacy --device values are still accepted:
  xwr18xx, xwr68xx
USAGE
}

profiles_file="$repo_dir/config/starter-demo-profiles.tsv"

need_value() {
  local opt="$1"
  local value="${2:-}"
  if [[ -z "$value" || "$value" == --* ]]; then
    printf 'Missing value for %s.\n\n' "$opt" >&2
    usage >&2
    exit 2
  fi
}

cmake_name_from() {
  local raw="$1"
  local name
  name="$(printf '%s' "$raw" | sed -E -e 's/[^A-Za-z0-9_]/_/g' -e 's/^_+//' -e 's/_+$//' -e 's/_+/_/g')"
  [[ -z "$name" ]] && name="mmwave_app"
  [[ "$name" =~ ^[0-9] ]] && name="app_$name"
  printf '%s\n' "$name"
}

list_profiles() {
  printf 'Available TI mmWave demo profiles:\n\n'
  while IFS=$'\t' read -r profile board core_mode source_kind source_rel sdk_device_type sdk_device output_bin cores build_entry_kind build_entry clean_target make_vars config_profiles status summary; do
    [[ -z "${profile:-}" || "$profile" == \#* ]] && continue
    printf '  %-26s %-12s %-8s %-17s %s\n' "$profile" "$board" "$core_mode" "$status" "$summary"
    printf '  %-26s source=%s entry=%s:%s output=%s configs=%s\n' "" "$source_kind" "$build_entry_kind" "$build_entry" "$output_bin" "$config_profiles"
  done < "$profiles_file"
}

load_profile() {
  local requested="$1"
  while IFS=$'\t' read -r profile_row board_row core_mode_row source_kind_row source_rel_row sdk_device_type_row sdk_device_row output_bin_row cores_row build_entry_kind_row build_entry_row clean_target_row make_vars_row config_profiles_row status_row summary_row; do
    [[ -z "${profile_row:-}" || "$profile_row" == \#* ]] && continue
    if [[ "$profile_row" == "$requested" ]]; then
      profile="$profile_row"
      board="$board_row"
      core_mode="$core_mode_row"
      source_kind="$source_kind_row"
      device="$sdk_device_type_row"
      sdk_demo_rel="$source_rel_row"
      sdk_device="$sdk_device_row"
      output_bin="$output_bin_row"
      core_hint="$cores_row"
      build_entry_kind="$build_entry_kind_row"
      build_entry="$build_entry_row"
      build_target="$build_entry_row"
      clean_target="$clean_target_row"
      make_extra_args="$make_vars_row"
      [[ "$make_extra_args" == "-" ]] && make_extra_args=""
      profile_configs="$config_profiles_row"
      profile_status="$status_row"
      profile_summary="$summary_row"
      return 0
    fi
  done < "$profiles_file"
  printf 'Unsupported demo profile: %s\n\n' "$requested" >&2
  list_profiles >&2
  return 2
}

profile_from_device() {
  case "$1" in
    xwr18xx) printf '%s\n' "xwr1843boost-mss-dss" ;;
    xwr68xx) printf '%s\n' "xwr6843isk-mss-dss" ;;
    *)
      printf 'Unsupported legacy device template: %s\n' "$1" >&2
      usage >&2
      return 2
      ;;
  esac
}

if [[ "${1:-}" == "--list-profiles" ]]; then
  list_profiles
  exit 0
fi

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
profile=""
legacy_device="xwr68xx"
device_was_set=0
out_dir=""
cmake_project=""
force=0
sdk_image="${SDK_IMAGE:-meowpas/ti-mmwave-sdk:03.06.02}"
ti_root="${TI_ROOT:-/opt/ti}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      need_value "$1" "${2:-}"
      profile="${2:-}"
      shift 2
      ;;
    --device)
      need_value "$1" "${2:-}"
      legacy_device="${2:-}"
      device_was_set=1
      shift 2
      ;;
    --dir|--out)
      need_value "$1" "${2:-}"
      out_dir="${2:-}"
      shift 2
      ;;
    --cmake-name)
      need_value "$1" "${2:-}"
      cmake_project="${2:-}"
      shift 2
      ;;
    --image)
      need_value "$1" "${2:-}"
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

if [[ -n "$profile" && "$device_was_set" -eq 1 ]]; then
  printf 'Use either --profile or legacy --device, not both.\n' >&2
  exit 2
fi

if [[ ! "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  printf 'Invalid project name: %s\n' "$name" >&2
  printf 'Use letters, numbers, dot, underscore, and hyphen only.\n' >&2
  exit 2
fi

if [[ -z "$cmake_project" ]]; then
  cmake_project="$(cmake_name_from "$name")"
fi
if [[ ! "$cmake_project" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
  printf 'Invalid CMake project name: %s\n' "$cmake_project" >&2
  printf 'Use letters, numbers, and underscore only; the first character must not be a number.\n' >&2
  exit 2
fi

if [[ -z "$profile" ]]; then
  profile="$(profile_from_device "$legacy_device")"
fi
load_profile "$profile"

if [[ "$source_kind" != "sdk-make" && "$source_kind" != "toolbox-make" ]]; then
  printf 'Profile is cataloged but not yet generatable by this SDK makefile template: %s\n' "$profile" >&2
  printf 'Source kind: %s\n' "$source_kind" >&2
  printf 'Build entry: %s:%s\n' "$build_entry_kind" "$build_entry" >&2
  printf 'This profile needs the Toolbox projectspec importer before create-mmwave-app can fork it.\n' >&2
  exit 2
fi

if [[ "$build_entry_kind" != "make-target" ]]; then
  printf 'Profile does not expose a TI make target: %s\n' "$profile" >&2
  printf 'Build entry: %s:%s\n' "$build_entry_kind" "$build_entry" >&2
  exit 2
fi

repo_demo_dir="$repo_dir/demos/$profile/app"
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

if [[ -f "$repo_demo_dir/makefile" ]]; then
  demo_source_dir="$repo_demo_dir"
elif [[ "$source_kind" == "sdk-make" && -f "$sdk_demo_dir/makefile" ]]; then
  demo_source_dir="$sdk_demo_dir"
else
  printf 'Demo makefile not found in repository converted demo or SDK image:\n' >&2
  printf '  repo: %s/makefile\n' "$repo_demo_dir" >&2
  printf '  sdk:  %s/makefile\n' "$sdk_demo_dir" >&2
  exit 2
fi

rm -rf "$abs_out"
mkdir -p "$abs_out/app"
cp -a "$demo_source_dir/." "$abs_out/app/"
if [[ ! -f "$abs_out/app/utils/mmwdemo_rfparser.c" && -f "$ti_root/mmwave_sdk_03_06_02_00-LTS/packages/ti/demo/utils/mmwdemo_rfparser.c" ]]; then
  mkdir -p "$abs_out/app/utils"
  cp -a "$ti_root/mmwave_sdk_03_06_02_00-LTS/packages/ti/demo/utils/." "$abs_out/app/utils/"
fi
mkdir -p "$abs_out/src"
printf 'Project-local sources can live here when they are not part of the forked TI demo tree.\n' > "$abs_out/src/README.md"
mkdir -p "$abs_out/tools"
cp "$repo_dir/scripts/mmwave-run.sh" "$abs_out/tools/mmwave-run"
chmod +x "$abs_out/tools/mmwave-run"
cp -a "$repo_dir/cmake" "$abs_out/tools/cmake"
if [[ -f "$repo_dir/THIRD_PARTY_NOTICES.md" ]]; then
  cp "$repo_dir/THIRD_PARTY_NOTICES.md" "$abs_out/THIRD_PARTY_NOTICES.md"
fi

render() {
  local src="$1"
  local dst="$2"
  sed \
    -e "s|@PROJECT_NAME@|$name|g" \
    -e "s|@CMAKE_PROJECT_NAME@|$cmake_project|g" \
    -e "s|@PROFILE@|$profile|g" \
    -e "s|@PROFILE_SUMMARY@|$profile_summary|g" \
    -e "s|@PROFILE_CONFIGS@|$profile_configs|g" \
    -e "s|@CORE_HINT@|$core_hint|g" \
    -e "s|@BUILD_ENTRY_KIND@|$build_entry_kind|g" \
    -e "s|@BUILD_ENTRY@|$build_entry|g" \
    -e "s|@BUILD_TARGET@|$build_target|g" \
    -e "s|@CLEAN_TARGET@|$clean_target|g" \
    -e "s|@MAKE_EXTRA_ARGS@|$make_extra_args|g" \
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
if [[ "$core_hint" == "MSS" && "$mss" == "no" && -f "$abs_out/app/mmw.mak" ]]; then
  mss="yes"
fi

cat <<EOF
Created TI mmWave fork project: $abs_out
Profile: $profile
CMake project: $cmake_project
Board: $board
Mode: $core_mode
Device template: $device ($sdk_device)
Forked demo source: $demo_source_dir
Cores: MSS=$mss DSS=$dss (profile: $core_hint)
Expected output: $output_bin
Docker image: $sdk_image

Next:
  cd "$abs_out"
  make build
EOF
