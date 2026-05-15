#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rounds="${ROBUSTNESS_ROUNDS:-100}"
min_score="${ROBUSTNESS_MIN_SCORE:-90}"
min_area_grade="${ROBUSTNESS_MIN_AREA_GRADE:-9}"
min_rounds="${ROBUSTNESS_MIN_ROUNDS:-10}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
run_dir="${ROBUSTNESS_RUN_DIR:-$repo_dir/reports/robustness-$timestamp}"
summary="$run_dir/summary.md"

if [[ ! "$rounds" =~ ^[0-9]+$ || "$rounds" -lt 1 ]]; then
  printf 'ROBUSTNESS_ROUNDS must be a positive integer, got: %s\n' "$rounds" >&2
  exit 2
fi

mkdir -p "$run_dir"

commands=(
  "python3 scripts/validate-starter-demos.py"
  "python3 -m py_compile docs/install.py scripts/validate-starter-demos.py scripts/robustness-score.py"
  "make github-actions-smoke"
  "make cmake-portability"
  "git diff --check"
)

passed=0
failed=0
failed_commands=0

printf '# Robustness Loop\n\n' >"$summary"
printf '%s\n' "- Timestamp UTC: \`$timestamp\`" >>"$summary"
printf '%s\n' "- Rounds requested: \`$rounds\`" >>"$summary"
printf '%s\n' "- Minimum total score: \`$min_score/100\`" >>"$summary"
printf '%s\n' "- Minimum area grade: \`$min_area_grade/10\`" >>"$summary"
printf '%s\n' "- Minimum scored rounds: \`$min_rounds\`" >>"$summary"
printf '%s\n\n' "- Run directory: \`$run_dir\`" >>"$summary"
printf '| Round | Result | Log |\n' >>"$summary"
printf '|---:|---:|---|\n' >>"$summary"

for round in $(seq 1 "$rounds"); do
  round_label="$(printf '%03d' "$round")"
  log="$run_dir/round-$round_label.log"
  round_ok=1
  {
    printf 'round=%s\n' "$round_label"
    printf 'repo=%s\n\n' "$repo_dir"
  } >"$log"

  for command in "${commands[@]}"; do
    {
      printf '\n$ %s\n' "$command"
      (cd "$repo_dir" && bash -c "$command")
    } >>"$log" 2>&1 || {
      round_ok=0
      failed_commands=$((failed_commands + 1))
      printf '\nFAILED: %s\n' "$command" >>"$log"
      break
    }
  done

  if [[ "$round_ok" -eq 1 ]]; then
    passed=$((passed + 1))
    printf '| %s | PASS | `%s` |\n' "$round_label" "${log#$repo_dir/}" >>"$summary"
  else
    failed=$((failed + 1))
    printf '| %s | FAIL | `%s` |\n' "$round_label" "${log#$repo_dir/}" >>"$summary"
  fi
done

score_report="$run_dir/score.md"
score_rc=0
(cd "$repo_dir" && scripts/robustness-score.py \
  --rounds-total "$rounds" \
  --rounds-passed "$passed" \
  --failed-commands "$failed_commands" \
  --run-dir "$run_dir" \
  --min-rounds "$min_rounds" \
  --min-score "$min_score" \
  --min-area-grade "$min_area_grade" \
  --output "$score_report") || score_rc=$?

{
  printf '\n## Result\n\n'
  printf '%s\n' "- Passed rounds: \`$passed\`"
  printf '%s\n' "- Failed rounds: \`$failed\`"
  printf '%s\n' "- Failed commands: \`$failed_commands\`"
  printf '%s\n' "- Score report: \`${score_report#$repo_dir/}\`"
} >>"$summary"

printf 'robustness loop report: %s\n' "$summary"

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi
exit "$score_rc"
