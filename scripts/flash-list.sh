#!/usr/bin/env bash
set -euo pipefail

printf 'Serial ports:\n'
found=0
for port in /dev/ttyACM* /dev/ttyUSB*; do
  [[ -e "$port" ]] || continue
  found=1
  printf '\n%s\n' "$port"
  ls -l "$port"
  if command -v udevadm >/dev/null 2>&1; then
    udevadm info -q property -n "$port" 2>/dev/null \
      | grep -E '^(ID_MODEL=|ID_MODEL_ID=|ID_VENDOR=|ID_VENDOR_ID=|ID_SERIAL=|ID_SERIAL_SHORT=|ID_USB_INTERFACE_NUM=)' \
      | sort || true
  fi
done

if (( ! found )); then
  printf 'No /dev/ttyACM* or /dev/ttyUSB* ports found.\n'
fi
