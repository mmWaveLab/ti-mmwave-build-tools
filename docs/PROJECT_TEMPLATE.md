# mmWave CMake Project Template

This repository can create small CMake/Ninja firmware projects that wrap an
official TI mmWave SDK demo without copying TI source into git.

## Create A Project

```bash
make project-new PROJECT=people-count-6843 DEVICE=xwr68xx
```

Use a custom output directory or overwrite a generated scaffold:

```bash
make project-new PROJECT=vital-signs-1843 DEVICE=xwr18xx OUT=examples/vital-signs-1843
make project-new PROJECT=vital-signs-1843 DEVICE=xwr18xx OUT=examples/vital-signs-1843 FORCE=1
```

This creates:

```text
examples/people-count-6843/
  CMakeLists.txt
  Makefile
  README.md
  src/README.md
```

Supported template devices:

| Device template | SDK device | Default output |
|---|---|---|
| `xwr16xx` | `iwr16xx` | `xwr16xx_mmw_demo.bin` |
| `xwr18xx` | `iwr18xx` | `xwr18xx_mmw_demo.bin` |
| `xwr64xx` | `iwr68xx` | `xwr64xx_mmw_demo.bin` |
| `xwr64xx_compression` | `iwr68xx` | `xwr64xx_compression_mmw_demo.bin` |
| `xwr68xx` | `iwr68xx` | `xwr68xx_mmw_demo.bin` |

## Build A Project

Docker:

```bash
make docker-build
make project-docker PROJECT=examples/people-count-6843
```

Native Ubuntu:

```bash
make project-native PROJECT=examples/people-count-6843
```

## Design Rules

- The generated project references `MMWAVE_SDK_PACKAGES/ti/demo/...`.
- The build copies SDK demo files into the CMake build tree before invoking the
  official SDK makefile.
- TI SDK source, tools, and generated binaries stay out of git.
- Keep reference-demo builds green before adding source overlays.

## When To Use This Template

Use it for board bring-up, regression projects, and CI examples such as IWR1843
or IWR6843. For deep source-level integration, keep using the reusable CMake API
under `cmake/` and graduate only the parts that need direct CMake control.
