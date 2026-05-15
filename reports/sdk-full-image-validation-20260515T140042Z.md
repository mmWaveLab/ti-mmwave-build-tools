# SDK-full Docker Image Validation

Date: 2026-05-15T14:00:42Z

Host:

```text
labpc
```

Image:

```text
meowkj/ti-mmwave-sdk:03.06.02-local
```

Image ID:

```text
sha256:e31b7b668324d6abd16c78c374e28d268096d79070e64cb6465638167af888cf
```

Docker disk usage:

```text
670862781 bytes
```

## Commands

```bash
make sdk-image SDK_FULL_IMAGE=meowkj/ti-mmwave-sdk:03.06.02-local HOST_TI_ROOT=/opt/ti
make sdk-image-smoke SDK_FULL_IMAGE=meowkj/ti-mmwave-sdk:03.06.02-local
```

## Results

| Check | Result |
|---|---:|
| TI SDK path inside image `/opt/ti` | PASS |
| TI ARM CGT `armcl` | PASS |
| TI C6000 CGT `cl6x` | PASS |
| XDCtools `xs` | PASS |
| SYS/BIOS packages | PASS |
| DSPLIB / MATHLIB packages | PASS |
| Mono runtime | PASS |
| `create-mmwave-app` symlink | PASS |
| CMake+Ninja fork build | PASS |

## Fork-build Artifacts

| Device template | Cores detected | Firmware artifact | SHA-256 |
|---|---|---|---|
| `xwr68xx` | MSS=yes DSS=yes | `xwr68xx_mmw_demo.bin` | `77e61607d3f4329d2a23400a6e3b319aa7046cc7fe9626734389cfc06a35a8fe` |
| `xwr18xx` | MSS=yes DSS=yes | `xwr18xx_mmw_demo.bin` | `f2fecda06dfe24cda91afba1a0529809f0cccc56341d1a61ebb25e30ea7ef7d3` |

## Notes

- The SDK-full image intentionally keeps TI tools at `/opt/ti` inside the
  container to avoid leaking host usernames and to keep logs portable.
- The SDK build rewrites TI SDK `packages/scripts/unix/setenv.sh` and
  `setenv.mak` to `/opt/ti`, and filters stale generated build products before
  copying the SDK into the image.
- Containers run generated project builds as the host UID/GID to avoid
  root-owned files in mounted source trees.
- The image is suitable for a private Docker Hub repository, not public
  redistribution.
