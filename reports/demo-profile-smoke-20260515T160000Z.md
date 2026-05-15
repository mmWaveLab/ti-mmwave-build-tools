# Demo Profile Smoke Validation

Date: 2026-05-15

Environment:

- SDK-full image: `meowkj/ti-mmwave-sdk:03.06.02-profile-test`
- Container TI root: `/opt/ti`
- Build entry: `scripts/sdk-image-smoke.sh`
- Build system: generated fork project, CMake configure, Ninja target `firmware`

Command:

```bash
SDK_FULL_IMAGE=meowkj/ti-mmwave-sdk:03.06.02-profile-test \
SDK_SMOKE_PROFILES="iwr6843isk-oob iwr1843boost-oob iwr1843aop-oob xwr64xx-oob xwr64xx-aop-oob xwr64xx-compression iwr1642boost-oob" \
scripts/sdk-image-smoke.sh
```

Results:

| Profile | SDK demo | Output | SHA-256 |
|---|---|---|---|
| `iwr6843isk-oob` | `ti/demo/xwr68xx/mmw` | `xwr68xx_mmw_demo.bin` | `77e61607d3f4329d2a23400a6e3b319aa7046cc7fe9626734389cfc06a35a8fe` |
| `iwr1843boost-oob` | `ti/demo/xwr18xx/mmw` | `xwr18xx_mmw_demo.bin` | `f2fecda06dfe24cda91afba1a0529809f0cccc56341d1a61ebb25e30ea7ef7d3` |
| `iwr1843aop-oob` | `ti/demo/xwr18xx/mmw` | `xwr18xx_mmw_aop_demo.bin` | `2e5f28ca7b155dd6625925be0f7bf632b3c37406f4d1ca3d09191fb51a74cc60` |
| `xwr64xx-oob` | `ti/demo/xwr64xx/mmw` | `xwr64xx_mmw_demo.bin` | `e68ba8df2c53900e9dbfabc641e2274dfeef222d7733d4c7b448775de3f0ff9a` |
| `xwr64xx-aop-oob` | `ti/demo/xwr64xx/mmw` | `xwr64xxAOP_mmw_demo.bin` | `22c2377c56ee43a664f178ca0fc10d0dddae8c676dfd59aa9c5d94a0e19d6c92` |
| `xwr64xx-compression` | `ti/demo/xwr64xx_compression/mmw` | `xwr64xx_compression_mmw_demo.bin` | `07528e6515adece6d2c68ef0de880317df5ab2d178ef93d59618b20fb5f7f80a` |
| `iwr1642boost-oob` | `ti/demo/xwr16xx/mmw` | `xwr16xx_mmw_demo.bin` | `f4344add9377d523f5d4cdd7fbcce58baa9563c2befdb0c48235c6f214b07ebe` |

Notes:

- These are generated projects forked from the SDK demo folders, not references
  to source files outside the project.
- `iwr6843isk-oob` tracks the SDK 03.06 `xwr68xx/mmw` demo. IWR6843AOP is kept
  separate and requires a source-backed profile before it is advertised as
  validated here.
- xWR64xx SDK demos are MSS-only and use a flat source layout instead of
  `mss/` and `dss/` subdirectories.
