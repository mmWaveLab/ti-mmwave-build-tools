#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
profiles_file="${DEMO_PROFILES_FILE:-$repo_dir/config/demo-profiles.tsv}"
image="${SDK_FULL_IMAGE:-meowpas/ti-mmwave-sdk:03.06.02}"
work_dir="${INSTALL_VALIDATION_WORK:-$repo_dir/build/install-profile-validation}"
report_dir="${REPORT_DIR:-$repo_dir/reports}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
report="$report_dir/install-profile-validation-$timestamp.md"
profiles_filter="${DEMO_PROFILES:-}"
jobs="${INSTALL_VALIDATION_JOBS:-auto}"
jobs_label="$jobs"
pull_policy="${INSTALL_VALIDATION_PULL:-auto}"
require_all="${INSTALL_REQUIRE_ALL_PROFILES:-0}"

mkdir -p "$work_dir" "$report_dir"
rm -rf "$work_dir"/projects "$work_dir"/results
mkdir -p "$work_dir"/projects "$work_dir"/results

installer="${INSTALLER:-$repo_dir/docs/install.py}"
if [[ -n "${INSTALLER_URL:-}" ]]; then
  installer="$work_dir/install.py"
  curl -fsSL "$INSTALLER_URL" -o "$installer"
fi

case "$jobs" in
  all)
    jobs=9999
    ;;
  auto)
    jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '1')"
    jobs_label="auto:$jobs"
    ;;
  *)
    if [[ ! "$jobs" =~ ^[0-9]+$ || "$jobs" -lt 1 ]]; then
      printf 'INSTALL_VALIDATION_JOBS must be all, auto, or a positive integer, got: %s\n' "$jobs" >&2
      exit 2
    fi
    ;;
esac

if [[ "$pull_policy" != "never" ]]; then
  docker pull "$image"
fi

profile_enabled() {
  local candidate="$1"
  [[ -z "$profiles_filter" ]] && return 0
  local selected
  for selected in $profiles_filter; do
    [[ "$selected" == "$candidate" ]] && return 0
  done
  return 1
}

validate_one_profile() {
  local profile="$1"
  local source_kind="$2"
  local output_bin="$3"
  local status="$4"
  local project="install-$profile"
  local out_dir="$work_dir/projects/$project"
  local log="$report_dir/install-profile-$profile-$timestamp.log"
  local result_file="$work_dir/results/$profile.tsv"
  local start
  local elapsed
  local rc=0
  local result="FAIL"
  local sha="-"
  local size="-"
  local note="-"

  start="$(date +%s)"
  if [[ "$source_kind" == "sdk-make" && "$status" == "validated" ]]; then
    python3 "$installer" \
      --name "$project" \
      --profile "$profile" \
      --dir "$out_dir" \
      --image "$image" \
      --pull never \
      --build \
      --force >"$log" 2>&1 || rc=$?
    if [[ "$rc" -eq 0 && -f "$out_dir/build/app/$output_bin" ]]; then
      sha="$(sha256sum "$out_dir/build/app/$output_bin" | cut -d ' ' -f 1)"
      size="$(stat -c '%s' "$out_dir/build/app/$output_bin" 2>/dev/null || wc -c <"$out_dir/build/app/$output_bin" | tr -d ' ')"
      result="PASS"
      note="built"
    else
      note="install-or-build-failed"
    fi
  else
    python3 "$installer" \
      --name "$project" \
      --profile "$profile" \
      --dir "$out_dir" \
      --image "$image" \
      --pull never \
      --force >"$log" 2>&1 || rc=$?
    if [[ "$require_all" == "1" ]]; then
      note="not-buildable-yet"
    elif [[ "$rc" -ne 0 ]] && grep -q 'Toolbox projectspec importer' "$log"; then
      result="SKIP"
      note="expected-toolbox-importer-missing"
    else
      note="unexpected-cataloged-behavior"
    fi
  fi
  elapsed=$(( $(date +%s) - start ))
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$profile" "$result" "$rc" "$elapsed" "$sha" "$size" "$note" >"$result_file"
}

printf '# Install Profile Validation\n\n' >"$report"
printf '%s\n' "- Timestamp UTC: \`$timestamp\`" >>"$report"
printf '%s\n' "- SDK-full image: \`$image\`" >>"$report"
printf '%s\n' "- Installer: \`${INSTALLER_URL:-$installer}\`" >>"$report"
printf '%s\n' "- Profile manifest: \`$profiles_file\`" >>"$report"
printf '%s\n' "- Parallel install jobs: \`$jobs_label\`" >>"$report"
printf '%s\n\n' "- Work directory: \`$work_dir\`" >>"$report"
printf '%s\n\n' "Validated SDK profiles must generate from \`install.py\`, build with CMake+Ninja inside Docker, and expose the expected flashable output. Cataloged Toolbox profiles must fail clearly until the projectspec importer exists." >>"$report"
printf '| Profile | Result | Exit | Seconds | SHA-256 | Bytes | Note |\n' >>"$report"
printf '|---|---:|---:|---:|---|---:|---|\n' >>"$report"

overall=0
running=0
pids=()
profiles=()

wait_for_slot() {
  local pid
  while (( running >= jobs )); do
    pid="${pids[0]}"
    wait "$pid" || overall=1
    pids=("${pids[@]:1}")
    running=$((running - 1))
  done
}

while IFS=$'\t' read -r profile _board _core_mode source_kind _source_rel _sdk_device_type _sdk_device output_bin _cores _build_target _clean_target _make_vars _config_profiles status _summary; do
  [[ -z "${profile:-}" || "$profile" == \#* ]] && continue
  profile_enabled "$profile" || continue

  wait_for_slot
  profiles+=("$profile")
  validate_one_profile "$profile" "$source_kind" "$output_bin" "$status" &
  pids+=("$!")
  running=$((running + 1))
done <"$profiles_file"

for pid in "${pids[@]}"; do
  wait "$pid" || overall=1
done

for profile in "${profiles[@]}"; do
  result_file="$work_dir/results/$profile.tsv"
  if [[ ! -f "$result_file" ]]; then
    printf '| `%s` | FAIL | - | - | `-` | - | `missing-result` |\n' "$profile" >>"$report"
    overall=1
    continue
  fi
  IFS=$'\t' read -r profile_result result rc elapsed sha size note <"$result_file"
  printf '| `%s` | %s | %s | %s | `%s` | %s | `%s` |\n' \
    "$profile_result" "$result" "$rc" "$elapsed" "$sha" "$size" "$note" >>"$report"
  if [[ "$result" == "FAIL" ]]; then
    overall=1
  fi
done

printf '\nReport: %s\n' "$report"
exit "$overall"
