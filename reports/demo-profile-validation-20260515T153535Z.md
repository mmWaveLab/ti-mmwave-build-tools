# Demo Profile SHA-256 Validation

Date: 2026-05-15

Environment:

- SDK-full image: `meowkj/ti-mmwave-sdk:03.06.02-profile-test`
- Container TI root: `/opt/ti`
- Profile manifest: `config/demo-profiles.tsv`
- Parallel profile jobs: `2`
- Build path 1: direct SDK demo copied from the SDK-full image
- Build path 2: generated fork project built through CMake+Ninja

Command:

```bash
SDK_FULL_IMAGE=meowkj/ti-mmwave-sdk:03.06.02-profile-test \
PROFILE_VALIDATION_JOBS=2 \
make sdk-profile-validate
```

Results:

| Profile | Direct SDK SHA-256 | Fork CMake SHA-256 | Result | Output |
|---|---|---|---:|---|
| `iwr1642boost-oob` | `f4344add9377d523f5d4cdd7fbcce58baa9563c2befdb0c48235c6f214b07ebe` | `f4344add9377d523f5d4cdd7fbcce58baa9563c2befdb0c48235c6f214b07ebe` | PASS | `xwr16xx_mmw_demo.bin` |
| `iwr1843boost-oob` | `f2fecda06dfe24cda91afba1a0529809f0cccc56341d1a61ebb25e30ea7ef7d3` | `f2fecda06dfe24cda91afba1a0529809f0cccc56341d1a61ebb25e30ea7ef7d3` | PASS | `xwr18xx_mmw_demo.bin` |
| `iwr1843aop-oob` | `2e5f28ca7b155dd6625925be0f7bf632b3c37406f4d1ca3d09191fb51a74cc60` | `2e5f28ca7b155dd6625925be0f7bf632b3c37406f4d1ca3d09191fb51a74cc60` | PASS | `xwr18xx_mmw_aop_demo.bin` |
| `xwr64xx-oob` | `e68ba8df2c53900e9dbfabc641e2274dfeef222d7733d4c7b448775de3f0ff9a` | `e68ba8df2c53900e9dbfabc641e2274dfeef222d7733d4c7b448775de3f0ff9a` | PASS | `xwr64xx_mmw_demo.bin` |
| `xwr64xx-aop-oob` | `22c2377c56ee43a664f178ca0fc10d0dddae8c676dfd59aa9c5d94a0e19d6c92` | `22c2377c56ee43a664f178ca0fc10d0dddae8c676dfd59aa9c5d94a0e19d6c92` | PASS | `xwr64xxAOP_mmw_demo.bin` |
| `xwr64xx-compression` | `07528e6515adece6d2c68ef0de880317df5ab2d178ef93d59618b20fb5f7f80a` | `07528e6515adece6d2c68ef0de880317df5ab2d178ef93d59618b20fb5f7f80a` | PASS | `xwr64xx_compression_mmw_demo.bin` |
| `iwr6843isk-oob` | `77e61607d3f4329d2a23400a6e3b319aa7046cc7fe9626734389cfc06a35a8fe` | `77e61607d3f4329d2a23400a6e3b319aa7046cc7fe9626734389cfc06a35a8fe` | PASS | `xwr68xx_mmw_demo.bin` |

Interpretation:

- The generated fork projects are byte-for-byte equivalent to direct TI SDK OOB
  demo builds for the expected non-secure firmware binaries.
- The script parallelizes independent profile jobs. It does not force parallel
  execution inside a single TI makefile because TI OOB makefiles use
  `.NOTPARALLEL`.
- xWR64xx profiles use `MMWAVE_SDK_DEVICE=iwr68xx` and
  `MMWAVE_SDK_DEVICE_TYPE=xwr68xx`, matching the SDK's own build expectation.
