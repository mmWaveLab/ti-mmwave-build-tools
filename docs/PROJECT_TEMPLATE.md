# mmWave CMake Project Template

This repository can create CMake/Ninja firmware projects by forking an official
TI mmWave SDK demo from an SDK-full Docker image. The generated project is a
normal source tree that developers can edit directly.

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
  .gitignore
  app/
    makefile
    mss/
    dss/
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

Build with the SDK-full Docker image:

```bash
cd examples/people-count-6843
make build
```

## Design Rules

- The generated project copies a TI SDK demo into `app/`.
- The build copies `app/` into the CMake build tree before invoking the
  original TI SDK makefile.
- The SDK-full Docker image provides TI SDK, compilers, CMake, Ninja, and
  helper scripts.
- Generated build outputs stay under `build/`.

## When To Use This Template

Use it for board bring-up, regression projects, and real firmware development
starting from a known-good TI demo such as IWR1843 or IWR6843 out-of-box.
