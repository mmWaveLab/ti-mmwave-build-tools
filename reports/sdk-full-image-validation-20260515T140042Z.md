# SDK-full Docker Image Validation

Date: 2026-05-15T14:00:42Z

Host:

```text
kj@192.168.8.109
```

Image:

```text
meowkj/ti-mmwave-sdk:03.06.02-local
```

Image ID:

```text
sha256:bb968b6446e462f7ed346efe7f4e4121749af234008633500a2fb2eeb000c30e
```

Docker disk usage:

```text
4.03GB
```

## Commands

```bash
make sdk-image SDK_FULL_IMAGE=meowkj/ti-mmwave-sdk:03.06.02-local HOST_TI_ROOT=/home/kj/ti
make sdk-image-smoke SDK_FULL_IMAGE=meowkj/ti-mmwave-sdk:03.06.02-local
```

## Results

| Check | Result |
|---|---:|
| TI SDK path inside image | PASS |
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
| `xwr68xx` | MSS=yes DSS=yes | `xwr68xx_mmw_demo.bin` | `4d37093668aa1106fdde282cc6e3eb22b6b823e6d73b93dbff908f8e1fc9d0b6` |
| `xwr18xx` | MSS=yes DSS=yes | `xwr18xx_mmw_demo.bin` | `2609674aed3bab4338ab62bcc50ff19f72201f8ebf5e0612e3ade40cdee6789b` |

## Notes

- The SDK-full image intentionally keeps TI tools at `/home/kj/ti` inside the
  container because TI SDK make/configuro fragments can embed install paths.
- Containers run generated project builds as the host UID/GID to avoid
  root-owned files in mounted source trees.
- The image is suitable for a private Docker Hub repository, not public
  redistribution.
