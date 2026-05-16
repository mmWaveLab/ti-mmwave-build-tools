#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${CMAKE_PORTABILITY_BUILD:-$repo_dir/build/cmake-portability}"

rm -rf "$build_dir"
mkdir -p "$build_dir"

printf 'CMake portability smoke\n'
printf 'repo: %s\n\n' "$repo_dir"

printf 'Root configure without TI SDK\n'
cmake -S "$repo_dir" -B "$build_dir/root" -G Ninja >/dev/null

printf 'Template syntax and hermetic runner\n'
bash -n "$repo_dir/scripts/mmwave-run.sh"
test -f "$repo_dir/templates/mmwave-cmake-project/CMakeLists.txt.in"
test -f "$repo_dir/templates/mmwave-cmake-project/Makefile.in"
find "$repo_dir/scripts" "$repo_dir/templates" "$repo_dir/config" "$repo_dir/demos" \
  -type f \
  ! -name validate-cmake-portability.sh \
  -print0 |
  xargs -0 grep -InE '/home/[^/]+|/Users/[^/]+|source[[:space:]].*(bashrc|zshrc|profile)|[[:space:]]\.[[:space:]].*(bashrc|zshrc|profile)' \
  >/tmp/mmwave-portability-leaks.txt && {
  cat /tmp/mmwave-portability-leaks.txt >&2
  exit 1
}

printf 'Demo profile manifest shape\n'
awk -F '\t' '
  BEGIN { ok=1 }
  /^#/ || NF == 0 { next }
  NF != 15 { printf "bad field count: %s\n", $0 > "/dev/stderr"; ok=0; next }
  $3 !~ /^(mss-only|mss-dss)$/ { printf "bad core mode: %s\n", $0 > "/dev/stderr"; ok=0 }
  $4 !~ /^(sdk-make|toolbox-projectspec)$/ { printf "bad source kind: %s\n", $0 > "/dev/stderr"; ok=0 }
  $8 !~ /[.]bin$/ { printf "starter output is not flashable bin: %s\n", $0 > "/dev/stderr"; ok=0 }
  $9 !~ /^(MSS|MSS[+]DSS)$/ { printf "bad cores: %s\n", $0 > "/dev/stderr"; ok=0 }
  $14 !~ /^(validated|cataloged)$/ { printf "bad status: %s\n", $0 > "/dev/stderr"; ok=0 }
  END { exit ok ? 0 : 1 }
' "$repo_dir/config/demo-profiles.tsv"

printf 'Toolbox profile manifest shape\n'
awk -F '\t' '
  BEGIN { ok=1 }
  /^#/ || NF == 0 { next }
  NF != 12 { printf "bad field count: %s\n", $0 > "/dev/stderr"; ok=0; next }
  $5 !~ /^(SDK3|L-SDK|MCU[+])$/ { printf "bad SDK family: %s\n", $0 > "/dev/stderr"; ok=0 }
  $6 !~ /^(MSS|DSS|MSS[+]DSS|MSS[+]DSS[+]CM4|MSS[+]CM4|APPSS|APPIMAGE)$/ { printf "bad cores: %s\n", $0 > "/dev/stderr"; ok=0 }
  $10 !~ /^(starter-sdk3|starter-other-sdk|defer)$/ { printf "bad suitability: %s\n", $0 > "/dev/stderr"; ok=0 }
  END { exit ok ? 0 : 1 }
' "$repo_dir/docs/catalog/toolbox-oob-profiles.tsv"

printf 'Toolbox application manifest shape\n'
awk -F '\t' '
  BEGIN { ok=1 }
  /^#/ || NF == 0 { next }
  NF != 13 { printf "bad field count: %s\n", $0 > "/dev/stderr"; ok=0; next }
  $5 !~ /^SDK3$/ { printf "bad SDK family: %s\n", $0 > "/dev/stderr"; ok=0 }
  $6 !~ /^MSS[+]DSS$/ { printf "bad cores: %s\n", $0 > "/dev/stderr"; ok=0 }
  $7 !~ /IWR6843AOP/ { printf "missing AOP target: %s\n", $0 > "/dev/stderr"; ok=0 }
  $11 !~ /^starter-application$/ { printf "bad suitability: %s\n", $0 > "/dev/stderr"; ok=0 }
  END { exit ok ? 0 : 1 }
' "$repo_dir/docs/catalog/toolbox-application-profiles.tsv"

printf 'PASS: CMake portability smoke succeeded.\n'
