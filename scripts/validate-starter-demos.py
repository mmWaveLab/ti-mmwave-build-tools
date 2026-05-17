#!/usr/bin/env python3
"""Validate the starter demo contract shared by manifest and installer."""

from __future__ import annotations

import csv
import importlib.util
import sys
from pathlib import Path


REQUIRED_PROFILES = {
    "xwr1843boost-mss-only",
    "xwr1843boost-mss-dss",
    "xwr6843isk-mss-only",
    "xwr6843isk-mss-dss",
    "xwr6843aop-mss-only",
    "xwr6843aop-mss-dss",
}
REQUIRED_BOARDS = {"xwr1843boost", "xwr6843isk", "xwr6843aop"}
REQUIRED_MODES = {"mss-only", "mss-dss"}


def load_manifest(path: Path) -> dict[str, dict[str, str]]:
    rows: dict[str, dict[str, str]] = {}
    with path.open(encoding="utf-8", newline="") as f:
        reader = csv.reader(f, delimiter="\t")
        header: list[str] | None = None
        for line_no, row in enumerate(reader, 1):
            if not row:
                continue
            if row[0].startswith("#"):
                header = [row[0].lstrip("# "), *row[1:]]
                continue
            if header is None:
                raise SystemExit(f"{path}:{line_no}: missing header")
            if len(row) != len(header):
                raise SystemExit(f"{path}:{line_no}: expected {len(header)} columns, got {len(row)}")
            item = dict(zip(header, row))
            profile = item["profile"]
            if profile in rows:
                raise SystemExit(f"{path}:{line_no}: duplicate profile {profile}")
            rows[profile] = item
    return rows


def load_installer(path: Path):
    spec = importlib.util.spec_from_file_location("mmwave_install", path)
    if spec is None or spec.loader is None:
        raise SystemExit(f"cannot load installer: {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module.PROFILES


def main() -> None:
    repo = Path(__file__).resolve().parents[1]
    manifest = load_manifest(repo / "config" / "starter-demo-profiles.tsv")
    installer_profiles = load_installer(repo / "docs" / "install.py")
    errors: list[str] = []
    notices = repo / "THIRD_PARTY_NOTICES.md"

    if not notices.is_file():
        errors.append("missing THIRD_PARTY_NOTICES.md")
    else:
        notice_text = notices.read_text(encoding="utf-8")
        for required in ("Texas Instruments", "BSD-3-Clause", "packages/ti/demo"):
            if required not in notice_text:
                errors.append(f"THIRD_PARTY_NOTICES.md missing {required!r}")

    if set(manifest) != REQUIRED_PROFILES:
        errors.append(f"manifest profiles mismatch: {sorted(set(manifest) ^ REQUIRED_PROFILES)}")
    if set(installer_profiles) != REQUIRED_PROFILES:
        errors.append(f"installer profiles mismatch: {sorted(set(installer_profiles) ^ REQUIRED_PROFILES)}")

    matrix = {(row["board"], row["core_mode"]) for row in manifest.values()}
    missing_cells = sorted((board, mode) for board in REQUIRED_BOARDS for mode in REQUIRED_MODES if (board, mode) not in matrix)
    if missing_cells:
        errors.append(f"missing board/mode cells: {missing_cells}")

    for profile, row in sorted(manifest.items()):
        installed = installer_profiles.get(profile)
        if installed is None:
            continue
        comparisons = {
            "board": installed.board,
            "core_mode": installed.mode,
            "source_kind": installed.source_kind,
            "source_rel": installed.source_rel,
            "sdk_device_type": installed.sdk_device_type,
            "sdk_device": installed.sdk_device,
            "output_artifact": installed.artifact,
            "cores": installed.cores,
            "build_entry_kind": installed.build_entry_kind,
            "build_entry": installed.build_entry,
            "clean_target": installed.clean_target,
            "status": installed.status,
        }
        for key, installer_value in comparisons.items():
            if row[key] != installer_value:
                errors.append(f"{profile}: {key} manifest={row[key]!r} installer={installer_value!r}")
        manifest_configs = tuple(row["config_profiles"].split(","))
        if manifest_configs != installed.configs:
            errors.append(f"{profile}: config profiles manifest={manifest_configs!r} installer={installed.configs!r}")
        if not row["output_artifact"].endswith(".bin"):
            errors.append(f"{profile}: starter output must be a flashable .bin")
        if row["build_entry_kind"] not in {"make-target", "ccs-projectspecs"}:
            errors.append(f"{profile}: invalid build entry kind {row['build_entry_kind']!r}")
        if row["source_kind"] == "sdk-make":
            if row["build_entry_kind"] != "make-target":
                errors.append(f"{profile}: SDK make profile must use make-target build entry")
            demo_dir = repo / "demos" / profile / "app"
            if not (demo_dir / "makefile").is_file():
                errors.append(f"{profile}: missing converted demo makefile at {demo_dir}")
            generated = [
                path.relative_to(demo_dir)
                for path in demo_dir.rglob("*")
                if path.is_file()
                and path.suffix in {".bin", ".xer4f", ".xe674", ".map", ".obj"}
            ]
            if generated:
                errors.append(f"{profile}: converted demo contains generated files: {generated[:5]}")
        elif row["source_kind"] == "toolbox-projectspec":
            if row["build_entry_kind"] != "ccs-projectspecs":
                errors.append(f"{profile}: Toolbox profile must use ccs-projectspecs build entry")
            if ".projectspec" not in row["build_entry"]:
                errors.append(f"{profile}: Toolbox build entry must list projectspec files")

    for path in sorted((repo / "demos").glob("*/app/**/*")):
        if not path.is_file() or path.suffix not in {".c", ".h"}:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        rel = path.relative_to(repo)
        for required in (
            "Texas Instruments",
            "Redistribution and use in source and binary forms",
            "Neither the name of Texas Instruments Incorporated",
        ):
            if required not in text:
                errors.append(f"{rel}: missing preserved TI BSD notice fragment {required!r}")

    if errors:
        raise SystemExit("\n".join(errors))
    print("starter demo contract ok: 6 profiles")


if __name__ == "__main__":
    main()
