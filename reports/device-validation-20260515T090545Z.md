# TI mmWave Device Validation

- Timestamp UTC: `20260515T090545Z`
- Docker image: `ti-mmwave-build-tools:linux-smoke`
- Host TI root: `/opt/ti`

| Device ID | SDK Device | Result | Seconds | Firmware Outputs |
|---|---|---:|---:|---|
| `xwr16xx` | `iwr16xx` | PASS | `61.02` | xwr16xx_mmw_demo.bin (5977d13ed0e9e48622f1cd9df307a6e831d6a59090c795072171ccf3569b558b) |
| `xwr18xx` | `iwr18xx` | PASS | `76.60` | xwr18xx_mmw_aop_demo.bin (0de1fc782afdfd0bc070bcf1406bb567579e694e9cfced3964035a3cc1652fe6),xwr18xx_mmw_demo.bin (2609674aed3bab4338ab62bcc50ff19f72201f8ebf5e0612e3ade40cdee6789b) |
| `xwr64xx` | `iwr68xx` | PASS | `65.75` | xwr64xxAOP_mmw_demo.bin (1081f4f81d03c7982709ad775d34b6ec1299c97c09bfbc5dcb218d33c3d1c685),xwr64xx_mmw_demo.bin (c67c90c8a9d2abb129505fae1a24c5cbd0335fd3ff675abd8ffba679fc55b15d) |
| `xwr64xx_compression` | `iwr68xx` | PASS | `32.67` | xwr64xx_compression_mmw_demo.bin (e16fce9c1518186128ea339ad5a8924eb5f2c1366a224f0058a9b48d04c8e565) |
| `xwr68xx` | `iwr68xx` | PASS | `64.02` | xwr68xx_mmw_demo.bin (4d37093668aa1106fdde282cc6e3eb22b6b823e6d73b93dbff908f8e1fc9d0b6) |
