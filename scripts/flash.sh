#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/flash-common.sh"

if [[ "${CONFIRM_FLASH:-}" != "YES" ]]; then
  printf 'ERROR: refusing to flash without CONFIRM_FLASH=YES.\n' >&2
  printf 'Example: make flash PORT=/dev/ttyACM0 BIN=build/sdk-image-smoke/smoke-iwr6843isk-oob/build/app/xwr68xx_mmw_demo.bin CONFIRM_FLASH=YES\n' >&2
  exit 2
fi

flash_require_port
bin="$(flash_resolve_default_bin "$repo_dir")"
flash_require_bin "$bin"

if ! dslite="$(flash_find_dslite)"; then
  printf 'ERROR: DSLite not found. Install TI UniFlash for Linux or set DSLITE=/path/to/dslite.sh.\n' >&2
  exit 2
fi

ccxml="$(flash_resolve_ccxml || true)"
if [[ -z "$ccxml" || ! -f "$ccxml" ]]; then
  printf 'ERROR: CCXML is required for flashing.\n' >&2
  printf 'Set CCXML=/path/to/device.ccxml or UNIFLASH_CLI_DIR=/path/to/generated-cli-package.\n' >&2
  exit 2
fi

settings_src="$(flash_resolve_ufsettings || true)"
settings=""
if [[ -n "$settings_src" ]]; then
  settings="$(flash_stage_settings "$repo_dir" "$settings_src" "$PORT")"
fi

mkdir -p "$repo_dir/reports"
log_file="$repo_dir/reports/uniflash-$(date -u +%Y%m%dT%H%M%SZ).log"

printf 'Flashing with UniFlash DSLite.\n'
printf 'PORT: %s\nBIN: %s\nCCXML: %s\nLOG: %s\n' "$PORT" "$bin" "$ccxml" "$log_file"

cmd=("$dslite" flash -c "$ccxml")
if [[ -n "$settings" ]]; then
  cmd+=(-l "$settings")
fi
cmd+=(-e -f -v -g "$log_file" "$bin")

"${cmd[@]}"
