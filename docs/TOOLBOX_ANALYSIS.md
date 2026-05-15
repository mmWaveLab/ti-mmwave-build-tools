# TI Radar Toolbox Analysis

This repository does not vendor TI Toolbox source or binaries. The full
Toolbox packages are cached on the lab PC only:

```text
/home/kj/ti-cache/toolboxes/
```

Downloaded packages:

| Package | Version | SHA-256 |
|---|---:|---|
| `radar_toolbox` | `4.00.00.05` | `e861a67c115f687bf57147c5775122698fc2c3a5fe8c710472de04d2c05a97e8` |
| `mmwave_industrial_toolbox` | `4.12.1` | `b4b51fbe84ae05292c3051905b92909485f99cc80a7aa44f81e05d4519328ca9` |

The full generated demo index is intentionally kept on the lab PC, not in git:

```text
/home/kj/ti-cache/toolboxes/reports/radar-toolbox-demo-index.tsv
```

The TI download page currently lists RADAR-TOOLBOX `3.30.00.06`, while TIREX
also exposes `radar_toolbox` `4.00.00.05`. The lab PC cache uses the newer
TIREX package and keeps the legacy Industrial Toolbox for comparison.

## OOB Findings

For the boards currently in scope, Toolbox has separate Out-of-Box entries:

| Profile candidate | Toolbox source | Cores | Prebuilt binary | Build implication |
|---|---|---:|---|---|
| `iwr1843boost-toolbox-oob` | `source/ti/examples/Out_Of_Box_Demo/src/xwr1843` | MSS+DSS | `out_of_box_1843_isk.bin` | Projectspec copies SDK `ti/demo/xwr18xx/mmw` sources. |
| `iwr6843isk-toolbox-oob` | `source/ti/examples/Out_Of_Box_Demo/src/xwr6843ISK` | MSS+DSS | `out_of_box_6843_isk.bin` | Projectspec copies SDK `ti/demo/xwr68xx/mmw` sources. |
| `iwr6843aop-toolbox-oob` | `source/ti/examples/Out_Of_Box_Demo/src/xwr6843AOP` | MSS | `out_of_box_6843_aop.bin` | Projectspec copies SDK `ti/demo/xwr64xx/mmw` plus AOP antenna geometry. |

Conclusion: IWR6843AOP is not the same build target as IWR6843ISK. It should be
modeled as a Toolbox profile with its own MSS-only source mapping, not as an
alias for the ISK SDK makefile profile.

## Repository Policy

- Keep the active generator on validated SDK makefile profiles until a
  projectspec importer exists.
- Keep Toolbox profile candidates in `config/toolbox-oob-profiles.tsv` as a
  lightweight analysis manifest.
- Do not commit Toolbox zips, extracted TI source, prebuilt binaries, or build
  reports.
- Use dual SHA validation for SDK makefile profiles.
- Add projectspec-to-CMake validation before promoting Toolbox profiles from
  `analysis-only` to generated project profiles.

## Hermetic Command Method

Use `scripts/mmwave-run.sh` or the generated project's `tools/mmwave-run`.
It starts a disposable Docker container with:

- host project mounted at `/work/app`
- `HOME=/tmp/mmwave-home`
- `bash --noprofile --norc` for interactive shells
- `env -i` for command execution
- no writes to `.bashrc`, `.zshrc`, shell profile files, or host TI installs

This keeps TI setup, CMake, Ninja, and SDK paths inside the Docker process
instead of leaking them into the developer's terminal session.
