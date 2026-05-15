#!/usr/bin/env bash

flash_find_dslite() {
  if [[ -n "${DSLITE:-}" && -x "$DSLITE" ]]; then
    printf '%s\n' "$DSLITE"
    return 0
  fi

  if [[ -n "${UNIFLASH_ROOT:-}" ]]; then
    for candidate in \
      "$UNIFLASH_ROOT/dslite.sh" \
      "$UNIFLASH_ROOT/dslite" \
      "$UNIFLASH_ROOT/deskdb/content/TICloudAgent/linux/ccs_base/DebugServer/bin/DSLite"; do
      if [[ -x "$candidate" ]]; then
        printf '%s\n' "$candidate"
        return 0
      fi
    done
  fi

  if command -v dslite.sh >/dev/null 2>&1; then
    command -v dslite.sh
    return 0
  fi
  if command -v dslite >/dev/null 2>&1; then
    command -v dslite
    return 0
  fi

  return 1
}

flash_resolve_default_bin() {
  local repo_dir="$1"
  if [[ -n "${BIN:-}" ]]; then
    printf '%s\n' "$BIN"
    return 0
  fi
  if [[ -f "$repo_dir/artifacts/xwr68xx_mmw_demo.docker.bin" ]]; then
    printf '%s\n' "$repo_dir/artifacts/xwr68xx_mmw_demo.docker.bin"
    return 0
  fi
  if [[ -f "$repo_dir/artifacts/device-validation/xwr68xx/xwr68xx_mmw_demo.bin" ]]; then
    printf '%s\n' "$repo_dir/artifacts/device-validation/xwr68xx/xwr68xx_mmw_demo.bin"
    return 0
  fi
  return 1
}

flash_require_port() {
  if [[ -z "${PORT:-}" ]]; then
    printf 'ERROR: PORT is required.\n' >&2
    printf 'Example: make flash-dry-run PORT=/dev/ttyACM0 BIN=artifacts/device-validation/xwr68xx/xwr68xx_mmw_demo.bin\n' >&2
    return 2
  fi
  if [[ ! -e "$PORT" ]]; then
    printf 'ERROR: PORT does not exist: %s\n' "$PORT" >&2
    return 2
  fi
}

flash_require_bin() {
  local bin="$1"
  if [[ -z "$bin" || ! -f "$bin" ]]; then
    printf 'ERROR: BIN does not exist: %s\n' "$bin" >&2
    return 2
  fi
}

flash_resolve_ccxml() {
  if [[ -n "${CCXML:-}" ]]; then
    printf '%s\n' "$CCXML"
    return 0
  fi
  if [[ -n "${UNIFLASH_CLI_DIR:-}" ]]; then
    find "$UNIFLASH_CLI_DIR/user_files/configs" -maxdepth 1 -type f -name '*.ccxml' 2>/dev/null | sort | head -n 1
    return 0
  fi
  return 1
}

flash_resolve_ufsettings() {
  if [[ -n "${UFSETTINGS:-}" ]]; then
    printf '%s\n' "$UFSETTINGS"
    return 0
  fi
  if [[ -n "${UNIFLASH_CLI_DIR:-}" && -f "$UNIFLASH_CLI_DIR/user_files/settings/generated.ufsettings" ]]; then
    printf '%s\n' "$UNIFLASH_CLI_DIR/user_files/settings/generated.ufsettings"
    return 0
  fi
  return 1
}

flash_stage_settings() {
  local repo_dir="$1"
  local src_settings="$2"
  local port="$3"

  if [[ -z "$src_settings" || ! -f "$src_settings" ]]; then
    return 1
  fi

  local stage_dir="$repo_dir/build/flash"
  mkdir -p "$stage_dir"
  local staged="$stage_dir/generated.port.ufsettings"
  cp "$src_settings" "$staged"

  # Best-effort serial-port substitution for generated CLI packages. Keep the
  # original settings untouched.
  sed -i.bak -E "s#(/dev/ttyACM[0-9]+|/dev/ttyUSB[0-9]+|COM[0-9]+)#$port#g" "$staged"
  rm -f "$staged.bak"
  printf '%s\n' "$staged"
}

flash_print_command() {
  local dslite="$1"
  local ccxml="$2"
  local settings="$3"
  local bin="$4"
  local log_file="$5"

  printf '%q flash -c %q' "$dslite" "$ccxml"
  if [[ -n "$settings" ]]; then
    printf ' -l %q' "$settings"
  fi
  printf ' -e -f -v -g %q %q\n' "$log_file" "$bin"
}
