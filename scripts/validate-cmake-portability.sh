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
python3 - "$repo_dir" <<'PY'
import re
import sys
from pathlib import Path

repo = Path(sys.argv[1])
checks = []

runner = (repo / "scripts" / "mmwave-run.sh").read_text(encoding="utf-8")
installer = (repo / "docs" / "install.py").read_text(encoding="utf-8")
template = (repo / "templates" / "mmwave-cmake-project" / "CMakeLists.txt.in").read_text(encoding="utf-8")
root_cmake = (repo / "CMakeLists.txt").read_text(encoding="utf-8")

def require(name: str, ok: bool) -> None:
    if not ok:
        checks.append(name)

for text_name, text in (("scripts/mmwave-run.sh", runner), ("docs/install.py", installer)):
    require(f"{text_name}: must run commands through env -i", "env -i" in text)
    require(f"{text_name}: must use isolated HOME", "HOME=/tmp/mmwave-home" in text)
    require(f"{text_name}: must set fixed TI_ROOT", "TI_ROOT=/opt/ti" in text)
    require(f"{text_name}: must support explicit Docker pulls", "--pull" in text and "docker pull" in text)
    require(f"{text_name}: must preflight missing Docker", "Docker is required for this command" in text)
    require(f"{text_name}: must reject missing commands", "COMMAND is required unless --shell is used" in text)
    require(f"{text_name}: must check workdir writability", "Workdir is not writable" in text)
    require(f"{text_name}: must include TI ARM compiler path", "ti-cgt-arm_16.9.6.LTS/bin" in text)
    require(f"{text_name}: must include TI C6000 compiler path", "ti-cgt-c6000_8.3.3/bin" in text)
    require(f"{text_name}: must include XDC tools path", "xdctools_3_50_08_24_core" in text)
    require(f"{text_name}: interactive shell must avoid host startup files", "bash --noprofile --norc" in text)

for text_name, text in (("template CMakeLists", template), ("docs/install.py CMakeLists", installer)):
    require(f"{text_name}: must expose SDK overlay option", "MMWAVE_USE_SDK_OVERLAY" in text)
    require(f"{text_name}: must generate MSS-only metaimage when needed", "generateMetaImage.sh" in text and "NULL" in text)
    require(f"{text_name}: make clean must override SDK tool path on command line",
            re.search(r'make -f makefile .*?MMWAVE_SDK_TOOLS_INSTALL_PATH=.*?TI_ROOT', text, re.S) is not None)
    require(f"{text_name}: make build must override SDK package path on command line",
            re.search(r'make -f makefile .*?MMWAVE_SDK_INSTALL_PATH=.*?MMWAVE_BUILD_SDK_PACKAGES', text, re.S) is not None)

require("repo-local generator must support explicit CMake project names", "--cmake-name" in (repo / "scripts" / "create-mmwave-app.sh").read_text(encoding="utf-8"))

stale_tokens = (
    "examples/xwr68xx-sdk-mss-dss-cmake",
    "scripts/new-project.sh",
    "config/sdk-manifest.json",
)
for token in stale_tokens:
    require(f"root CMake must not reference stale scaffold {token}", token not in root_cmake)

if checks:
    raise SystemExit("\n".join(checks))
PY
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
