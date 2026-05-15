# Official TI SDK Demo Matrix

This directory documents the TI mmWave SDK demo projects that this repository
can validate without vendoring TI-owned source code.

The entries here are references into an installed TI SDK, not copies of TI SDK
files. A self-hosted runner must provide the SDK/toolchain under `HOST_TI_ROOT`
or `config/machine.env`.

## Why This Exists

Public GitHub-hosted runners can only verify the repository structure, Docker
image, and manifest syntax. They cannot contain the proprietary TI SDK,
compilers, RadarSS firmware, SYS/BIOS, DSPLIB, or UniFlash.

Self-hosted runners can use this matrix to build real TI demo firmware on every
commit or on manual dispatch.

## Demo Coverage

| ID | Common devices | SDK demo path | SDK build device | CI purpose |
|---|---|---|---|---|
| `xwr16xx` | IWR1642, AWR1642 | `ti/demo/xwr16xx/mmw` | `iwr16xx` | 16xx MSS+DSS reference demo |
| `xwr18xx` | IWR1843, AWR1843 | `ti/demo/xwr18xx/mmw` | `iwr18xx` | 1843 MSS+DSS reference demo |
| `xwr64xx` | xWR64xx family | `ti/demo/xwr64xx/mmw` | `iwr68xx` | 64xx reference demo through 68xx SDK profile |
| `xwr64xx_compression` | xWR64xx family | `ti/demo/xwr64xx_compression/mmw` | `iwr68xx` | 64xx compression demo |
| `xwr68xx` | IWR6843ISK, AWR6843 | `ti/demo/xwr68xx/mmw` | `iwr68xx` | 6843 MSS+DSS reference demo |

## Commands

Manifest-only check, suitable for public GitHub Actions:

```bash
make official-demo-manifest
```

Full build check, suitable for a self-hosted runner with TI SDK access:

```bash
make docker-build
make validate-devices
```

Use a custom subset by passing another TSV file with the same first four columns
as `config/devices.tsv`:

```bash
DEVICES_FILE=examples/official-sdk-demos/devices-ci.tsv make validate-devices
```

IWR6843AOP is intentionally not folded into the `xwr68xx` row. It is a
separate AOP device/package profile and should be added as its own source-backed
demo entry when the corresponding TI package is available in the SDK-full image.

## Legal Boundary

Do not commit TI SDK source files, generated firmware binaries, compiler
outputs, or UniFlash packages into this repository. Keep only manifests,
wrappers, reports, and reproducible build scripts here.
