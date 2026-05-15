# Device Support

Validated on `labpc` with Docker image
`ti-mmwave-build-tools:linux-smoke`.

Validation command:

```bash
make validate-devices
```

Latest report:

```text
reports/device-validation-20260515T123503Z.md
```

| Device ID | SDK Device | Status | Seconds | Output |
|---|---|---:|---:|---|
| `xwr16xx` | `iwr16xx` | PASS | `62.17` | `xwr16xx_mmw_demo.bin` |
| `xwr18xx` | `iwr18xx` | PASS | `77.92` | `xwr18xx_mmw_demo.bin`, `xwr18xx_mmw_aop_demo.bin` |
| `xwr64xx` | `iwr68xx` | PASS | `66.81` | `xwr64xx_mmw_demo.bin`, `xwr64xxAOP_mmw_demo.bin` |
| `xwr64xx_compression` | `iwr68xx` | PASS | `33.26` | `xwr64xx_compression_mmw_demo.bin` |
| `xwr68xx` / `iwr6843isk-oob` | `iwr68xx` | PASS | `65.02` | `xwr68xx_mmw_demo.bin` |

Notes:

- The SDK common makefiles officially enumerate `awr14xx`, `iwr14xx`,
  `awr16xx`, `iwr16xx`, `awr18xx`, `iwr18xx`, `awr68xx`, and `iwr68xx`.
- This repository validates the demo folders present in
  `mmwave_sdk_03_06_02_00-LTS/packages/ti/demo`.
- The `xwr64xx` demo folders build through the SDK `iwr68xx` device profile and
  use the xWR6xxx RadarSS image.
- IWR6843AOP is not treated as the same profile as IWR6843ISK. The SDK 03.06
  `ti/demo/xwr68xx/mmw` source is tracked as `iwr6843isk-oob`; an IWR6843AOP
  source package should be added and validated as its own demo profile.
- Validation means the Docker SDK environment can compile the firmware and
  produce `.bin` artifacts. It does not mean each binary was flashed to hardware.
- Devices such as `AWR2x44P`, `AWR2544`, and `AWR294x` are not marked
  unsupported; they use a different TI SDK flow such as MMWAVE-MCUPLUS-SDK.
- RF transceiver/MMIC devices such as `AWR1243` and `AWR2243` use a different
  DFP/mmWaveLink-style flow rather than this MSS/DSS demo build.
