# Project Template Validation

Date: 2026-05-15T13:00:10Z

Host:

```text
kj@192.168.8.109
```

Repository path:

```text
/home/kj/ti-mmwave-build-tools-docker
```

## Commands

```bash
make project-new PROJECT=generated-6843 DEVICE=xwr68xx OUT=build/generated-6843 FORCE=1
make project-docker PROJECT=build/generated-6843

make project-new PROJECT=generated-1843 DEVICE=xwr18xx OUT=build/generated-1843 FORCE=1
make project-docker PROJECT=build/generated-1843
```

## Results

| Generated project | Device template | Result | Firmware artifact | SHA-256 |
|---|---|---:|---|---|
| `build/generated-6843` | `xwr68xx` | PASS | `xwr68xx_mmw_demo.bin` | `4d37093668aa1106fdde282cc6e3eb22b6b823e6d73b93dbff908f8e1fc9d0b6` |
| `build/generated-1843` | `xwr18xx` | PASS | `xwr18xx_mmw_demo.bin` | `2609674aed3bab4338ab62bcc50ff19f72201f8ebf5e0612e3ade40cdee6789b` |
| `build/generated-1843` | `xwr18xx AOP` | PASS | `xwr18xx_mmw_aop_demo.bin` | `0de1fc782afdfd0bc070bcf1406bb567579e694e9cfced3964035a3cc1652fe6` |

## Notes

- The generated CMake projects configured with Ninja inside Docker.
- The builds invoked TI SDK MSS, DSS, RTSC/configuro, and metaimage generation.
- The produced hashes match the latest full device-validation run for these
  SDK demo artifacts.
