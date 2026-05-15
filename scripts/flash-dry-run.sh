#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$repo_dir/scripts/flash-common.sh"

flash_require_port
bin="$(flash_resolve_default_bin "$repo_dir")"
flash_require_bin "$bin"

if ! dslite="$(flash_find_dslite)"; then
  printf 'ERROR: DSLite not found. Install TI UniFlash for Linux or set DSLITE=/path/to/dslite.sh.\n' >&2
  exit 2
fi

ccxml="$(flash_resolve_ccxml || true)"
if [[ -z "$ccxml" || ! -f "$ccxml" ]]; then
  printf 'ERROR: CCXML is required for dry-run command generation.\n' >&2
  printf 'Set CCXML=/path/to/device.ccxml or UNIFLASH_CLI_DIR=/path/to/generated-cli-package.\n' >&2
  exit 2
fi

settings_src="$(flash_resolve_ufsettings || true)"
settings=""
if [[ -n "$settings_src" ]]; then
  settings="$(flash_stage_settings "$repo_dir" "$settings_src" "$PORT")"
fi

log_file="$repo_dir/reports/uniflash-$(date -u +%Y%m%dT%H%M%SZ).log"

printf 'Dry-run only. No flash will be performed.\n'
printf 'PORT: %s\n' "$PORT"
printf 'BIN: %s\n' "$bin"
printf 'CCXML: %s\n' "$ccxml"
[[ -n "$settings" ]] && printf 'UFSETTINGS staged: %s\n' "$settings"
printf 'Command:\n'
flash_print_command "$dslite" "$ccxml" "$settings" "$bin" "$log_file"
