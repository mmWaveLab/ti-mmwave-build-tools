# mmWave CMake Project Template

This repository can create CMake/Ninja firmware projects by forking an official
TI mmWave SDK demo from an SDK-full Docker image. The generated project is a
normal source tree that developers can edit directly.

## Create A Project

```bash
make project-new PROJECT=people-count-6843 PROFILE=iwr6843isk-oob
```

Use a custom output directory or overwrite a generated scaffold:

```bash
make project-new PROJECT=vital-signs-1843 PROFILE=iwr1843boost-oob OUT=examples/vital-signs-1843
make project-new PROJECT=vital-signs-1843 PROFILE=iwr1843boost-oob OUT=examples/vital-signs-1843 FORCE=1
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

List available fork profiles:

```bash
docker run --rm meowkj/ti-mmwave-sdk:03.06.02-local create-mmwave-app --list-profiles
```

Common fork profiles:

| Profile | SDK demo | SDK device | Default output |
|---|---|---|---|
| `iwr1642boost-oob` | `ti/demo/xwr16xx/mmw` | `iwr16xx` | `xwr16xx_mmw_demo.bin` |
| `iwr1843boost-oob` | `ti/demo/xwr18xx/mmw` | `iwr18xx` | `xwr18xx_mmw_demo.bin` |
| `iwr1843aop-oob` | `ti/demo/xwr18xx/mmw` | `iwr18xx` | `xwr18xx_mmw_aop_demo.bin` |
| `xwr64xx-oob` | `ti/demo/xwr64xx/mmw` | `iwr68xx` | `xwr64xx_mmw_demo.bin` |
| `xwr64xx-aop-oob` | `ti/demo/xwr64xx/mmw` | `iwr68xx` | `xwr64xxAOP_mmw_demo.bin` |
| `xwr64xx-compression` | `ti/demo/xwr64xx_compression/mmw` | `iwr68xx` | `xwr64xx_compression_mmw_demo.bin` |
| `iwr6843isk-oob` | `ti/demo/xwr68xx/mmw` | `iwr68xx` | `xwr68xx_mmw_demo.bin` |

Legacy `DEVICE=xwr68xx` still works, but `PROFILE=...` is preferred because it
captures the expected board/demo variant and output artifact.

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

The SDK 03.06 `ti/demo/xwr68xx/mmw` folder is represented as
`iwr6843isk-oob`. IWR6843AOP should be tracked as a separate profile once its
source package is added from the appropriate TI package; do not treat it as the
same fork target as IWR6843ISK.
