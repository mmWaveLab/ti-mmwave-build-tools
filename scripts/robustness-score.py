#!/usr/bin/env python3
"""Score repository robustness from repeat-test evidence and static guards."""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path


EXPECTED_LOOP_COMMANDS = (
    "python3 scripts/validate-starter-demos.py",
    "python3 -m py_compile docs/install.py scripts/validate-starter-demos.py scripts/robustness-score.py",
    "make github-actions-smoke",
    "make cmake-portability",
    "git diff --check",
)
ROUND_ROW_RE = re.compile(r"^\|\s*(\d+)\s*\|\s*(PASS|FAIL)\s*\|\s*`([^`]+)`\s*\|\s*$")


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def area_grade(score: int, max_score: int) -> float:
    if max_score <= 0:
        return 0.0
    return score * 10.0 / max_score


def starter_matrix_score(repo: Path) -> tuple[int, list[str]]:
    path = repo / "config" / "demo-profiles.tsv"
    required = {
        "xwr1843boost-mss-only",
        "xwr1843boost-mss-dss",
        "xwr6843isk-mss-only",
        "xwr6843isk-mss-dss",
        "xwr6843aop-mss-only",
        "xwr6843aop-mss-dss",
    }
    notes: list[str] = []
    rows: dict[str, list[str]] = {}
    with path.open(encoding="utf-8", newline="") as f:
        for row in csv.reader(f, delimiter="\t"):
            if not row or row[0].startswith("#"):
                continue
            rows[row[0]] = row
    score = 0
    if set(rows) == required:
        score += 5
        notes.append("six starter profiles present")
    else:
        notes.append("starter profile set mismatch")
    if all(len(row) == 15 for row in rows.values()):
        score += 3
        notes.append("profile manifest shape is stable")
    if all(row[7].endswith(".bin") for row in rows.values()):
        score += 5
        notes.append("all starter outputs are flashable .bin artifacts")
    if all(row[13] in {"validated", "cataloged"} for row in rows.values()):
        score += 1
        notes.append("profile status values are bounded")
    if all(row[3] == "sdk-make" or (row[3] == "toolbox-projectspec" and row[13] == "cataloged") for row in rows.values()):
        score += 1
        notes.append("non-SDK projectspec profiles are explicitly cataloged, not claimed validated")
    return score, notes


def portability_score(repo: Path) -> tuple[int, list[str]]:
    notes: list[str] = []
    score = 0
    host_path_pattern = re.compile(r"(?<![\w.-])(?:/home/[A-Za-z0-9._-]+|/Users/[A-Za-z0-9._-]+)(?:/|\b)")
    shell_profile_pattern = re.compile(r"(^|[;&|]\s*)(?:source|\.)\s+[^#\n]*(?:bashrc|zshrc|profile)\b")
    checked_roots = ["scripts", "templates", "config", "docs"]
    leaks: list[str] = []
    for root_name in checked_roots:
        for path in (repo / root_name).rglob("*"):
            if not path.is_file() or path.suffix in {".pyc"}:
                continue
            if path.name == "robustness-score.py":
                continue
            text = path.read_text(encoding="utf-8", errors="ignore")
            if host_path_pattern.search(text) or shell_profile_pattern.search(text):
                leaks.append(str(path.relative_to(repo)))
    if not leaks:
        score += 5
        notes.append("no host-user path or shell profile leaks in portable files")
    else:
        notes.append("host-user path leaks: " + ", ".join(leaks[:4]))
    runner = read(repo / "scripts" / "mmwave-run.sh")
    if "env -i" in runner and "--noprofile" in runner and "--norc" in runner:
        score += 4
        notes.append("Docker shell runner avoids host shell pollution")
    template = read(repo / "templates" / "mmwave-cmake-project" / "CMakeLists.txt.in")
    if "mss-metaimage-if-needed.sh" in template and "MMWAVE_SDK_INSTALL_PATH" in template:
        score += 3
        notes.append("MSS-only .bin metaimage helper is template-backed")
    installer = read(repo / "docs" / "install.py")
    if "PATH=\"$PATH\"" not in installer and "clean_env=(env -i" in installer:
        score += 2
        notes.append("public installer emits a fixed clean container environment")
    if "meowpas/ti-mmwave-sdk:03.06.02" in read(repo / "Makefile"):
        score += 1
        notes.append("default SDK-full image is pinned")
    return score, notes


def docker_consistency_score(repo: Path) -> tuple[int, list[str]]:
    notes: list[str] = []
    score = 0
    dockerfile = read(repo / "docker" / "Dockerfile.sdk-full")
    build_script = read(repo / "scripts" / "build-sdk-image.sh")
    smoke_script = read(repo / "scripts" / "sdk-image-smoke.sh")
    if "ninja-build" in dockerfile and "cmake>=3.29,<3.31" in dockerfile:
        score += 4
        notes.append("SDK-full image carries CMake and Ninja")
    if (
        "COPY ti /opt/ti" in dockerfile
        and "COPY tools /opt/ti-mmwave-build-tools" in dockerfile
        and "s#/home/[^/]+/ti#/opt/ti#g" in dockerfile
        and "/home/kj" not in dockerfile
        and "'k''j'" not in dockerfile
    ):
        score += 4
        notes.append("SDK-full recipe relocates TI paths without user-specific strings")
    if (
        "create-mmwave-app.sh" in dockerfile
        and "check-ti-linux.sh" in dockerfile
        and "/opt/ti-mmwave-build-tools/scripts" in dockerfile
    ):
        score += 3
        notes.append("SDK-full image exposes generator and doctor commands on PATH")
    if "--exclude 'docs/'" in build_script and "--exclude '*.xer4f'" in build_script and "--exclude 'xwr*_mmw*_demo*.bin'" in build_script:
        score += 2
        notes.append("SDK image context excludes docs and generated build outputs")
    if "create-mmwave-app" in smoke_script and "-G Ninja" in smoke_script and "cmake --build" in smoke_script:
        score += 2
        notes.append("SDK image smoke builds generated projects with CMake+Ninja")
    return score, notes


def ci_score(repo: Path) -> tuple[int, list[str]]:
    workflow = read(repo / ".github" / "workflows" / "ci.yml")
    pages = read(repo / ".github" / "workflows" / "pages.yml")
    notes: list[str] = []
    score = 0
    if "public-smoke" in workflow and "make github-actions-smoke cmake-portability" in workflow:
        score += 4
        notes.append("public no-SDK smoke job runs the repository smoke and portability gates")
    if "docker-image" in workflow and "docker build -t ti-mmwave-build-tools:ci ." in workflow and "command -v cmake && command -v ninja" in workflow:
        score += 4
        notes.append("public Docker image job builds and checks CMake/Ninja")
    if (
        "sdk-full-sha256" in workflow
        and "docker pull \"$SDK_FULL_IMAGE\"" in workflow
        and "PROFILE_VALIDATION_JOBS=all SDK_FULL_IMAGE=\"$SDK_FULL_IMAGE\" make sdk-profile-validate" in workflow
        and "github.event_name != 'pull_request'" in workflow
        and "actions/upload-artifact@v4" in workflow
    ):
        score += 5
        notes.append("private SDK-full image job is mandatory on push and uploads SHA validation reports")
    if "self-hosted-full" in workflow and "workflow_dispatch" in workflow and "CI_FULL_BUILD=1 scripts/ci.sh" in workflow:
        score += 3
        notes.append("self-hosted full build job is manually gated")
    if "concurrency:" in workflow and "cancel-in-progress: true" in workflow:
        score += 2
        notes.append("workflow concurrency is guarded")
    if "actions/deploy-pages" in pages and "docs" in pages:
        score += 2
        notes.append("GitHub Pages installer deploy is configured")
    return score, notes


def maintainability_score(repo: Path) -> tuple[int, list[str]]:
    notes: list[str] = []
    score = 0
    if (repo / "docs" / "STARTER_DEMOS.md").is_file() and (repo / "docs" / "DOCKER_IMAGE.md").is_file():
        score += 2
        notes.append("core docs are focused")
    if "docs/install.py" in read(repo / "scripts" / "github-actions-smoke.sh"):
        score += 3
        notes.append("public installer is smoke-tested")
    if "starter output must be a flashable .bin" in read(repo / "scripts" / "validate-starter-demos.py"):
        score += 3
        notes.append("starter contract rejects non-flashable outputs")
    pages_workflow = read(repo / ".github" / "workflows" / "pages.yml")
    if "docs/" in pages_workflow or re.search(r"(?m)^\s*path:\s*docs\s*$", pages_workflow):
        score += 2
        notes.append("installer publication path is explicit")
    return score, notes


def parse_loop_evidence(repo: Path, run_dir: Path) -> tuple[int, int, int, bool, list[str]]:
    run_dir = run_dir if run_dir.is_absolute() else repo / run_dir
    summary = run_dir / "summary.md"
    notes: list[str] = []
    if not summary.is_file():
        return 0, 0, 0, False, [f"loop summary not found: {summary}"]

    rows: list[tuple[str, str, Path]] = []
    for line in summary.read_text(encoding="utf-8").splitlines():
        match = ROUND_ROW_RE.match(line)
        if not match:
            continue
        round_label, result, log_ref = match.groups()
        log_path = Path(log_ref)
        if not log_path.is_absolute():
            log_path = repo / log_path
        rows.append((round_label, result, log_path))

    if not rows:
        return 0, 0, 0, False, [f"no round rows found in {summary}"]

    passed = sum(1 for _round, result, _log in rows if result == "PASS")
    failed_commands = 0
    logs_ok = True
    missing_logs: list[str] = []
    incomplete_logs: list[str] = []
    for round_label, result, log_path in rows:
        if not log_path.is_file():
            logs_ok = False
            missing_logs.append(round_label)
            continue
        text = log_path.read_text(encoding="utf-8", errors="ignore")
        failed_commands += text.count("FAILED:")
        if result == "PASS":
            missing_commands = [command for command in EXPECTED_LOOP_COMMANDS if f"$ {command}" not in text]
            if missing_commands or "FAILED:" in text:
                logs_ok = False
                incomplete_logs.append(round_label)
    try:
        display_dir = run_dir.relative_to(repo)
    except ValueError:
        display_dir = run_dir
    notes.append(f"loop evidence verified from {display_dir}")
    if missing_logs:
        notes.append("missing logs: " + ", ".join(missing_logs[:5]))
    if incomplete_logs:
        notes.append("incomplete pass logs: " + ", ".join(incomplete_logs[:5]))
    return len(rows), passed, failed_commands, logs_ok, notes


def reliability_score(rounds_total: int, rounds_passed: int, failed_commands: int, min_rounds: int, evidence_ok: bool, evidence_notes: list[str]) -> tuple[int, list[str]]:
    if rounds_total <= 0:
        return 0, ["no repeat-test evidence provided"]
    ratio = rounds_passed / rounds_total
    score = round(25 * ratio)
    notes = [f"repeat-test pass ratio: {rounds_passed}/{rounds_total}"]
    notes.extend(evidence_notes)
    if rounds_total < min_rounds:
        score = min(score, 22)
        notes.append(f"repeat-test evidence below minimum rounds: {rounds_total}/{min_rounds}")
    if failed_commands:
        score = min(score, 22)
        notes.append(f"failed command count across loop: {failed_commands}")
    if min_rounds > 0 and not evidence_ok:
        score = min(score, 22)
        notes.append("loop evidence is incomplete or was not parsed from logs")
    if min_rounds <= 0 and not evidence_ok:
        notes.append("score computed from explicit round counters")
    return score, notes


def write_report(path: Path, rows: list[tuple[str, int, int, list[str]]], total: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Robustness Score",
        "",
        f"- Total score: `{total}/100`",
        f"- Project grade: `{total / 10:.1f}/10`",
        "",
        "| Area | Score | Grade | Evidence |",
        "|---|---:|---:|---|",
    ]
    for name, score, max_score, notes in rows:
        lines.append(f"| {name} | {score}/{max_score} | {area_grade(score, max_score):.1f}/10 | {'; '.join(notes)} |")
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Score ti-mmwave-build-tools robustness.")
    parser.add_argument("--rounds-total", type=int, default=0)
    parser.add_argument("--rounds-passed", type=int, default=0)
    parser.add_argument("--failed-commands", type=int, default=0)
    parser.add_argument("--run-dir", type=Path)
    parser.add_argument("--min-rounds", type=int, default=0)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--min-score", type=int, default=0)
    parser.add_argument("--min-area-grade", type=float, default=0.0)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo = repo_root()
    rows: list[tuple[str, int, int, list[str]]] = []

    rounds_total = args.rounds_total
    rounds_passed = args.rounds_passed
    failed_commands = args.failed_commands
    evidence_ok = False
    evidence_notes: list[str] = []
    if args.run_dir is not None:
        rounds_total, rounds_passed, failed_commands, evidence_ok, evidence_notes = parse_loop_evidence(repo, args.run_dir)
    reliability, notes = reliability_score(rounds_total, rounds_passed, failed_commands, args.min_rounds, evidence_ok, evidence_notes)
    rows.append(("repeat reliability", reliability, 25, notes))
    matrix, notes = starter_matrix_score(repo)
    rows.append(("starter contract", matrix, 15, notes))
    portability, notes = portability_score(repo)
    rows.append(("portability", portability, 15, notes))
    docker, notes = docker_consistency_score(repo)
    rows.append(("Docker consistency", docker, 15, notes))
    ci, notes = ci_score(repo)
    rows.append(("CI readiness", ci, 20, notes))
    maintainability, notes = maintainability_score(repo)
    rows.append(("maintainability", maintainability, 10, notes))

    total = sum(row[1] for row in rows)
    output = args.output or (repo / "reports" / "robustness-score.md")
    write_report(output, rows, total)
    print(f"robustness score: {total}/100 ({total / 10:.1f}/10)")
    for name, score, max_score, _notes in rows:
        print(f"{name}: {area_grade(score, max_score):.1f}/10")
    print(f"report: {output}")
    area_floor_ok = all(area_grade(score, max_score) >= args.min_area_grade for _name, score, max_score, _notes in rows)
    return 0 if total >= args.min_score and area_floor_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
