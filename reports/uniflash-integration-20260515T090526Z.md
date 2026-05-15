# UniFlash Integration Test

- Timestamp UTC: `20260515T090526Z`
- Host: `kj@192.168.8.109`
- Repository: `/home/kj/ti-mmwave-build-tools-docker`
- Firmware fixture: `artifacts/device-validation/xwr68xx/xwr68xx_mmw_demo.bin`

## Results

| Check | Result | Notes |
|---|---:|---|
| `make flash-list` | PASS | Found `/dev/ttyACM0` and `/dev/ttyACM3`. |
| `make flash-doctor` | PASS_WITH_EXPECTED_BLOCKER | Serial devices and firmware artifact detected; DSLite is not installed. |
| `make flash-dry-run PORT=/dev/ttyACM0 ...` | PASS_WITH_EXPECTED_BLOCKER | Refused before flashing because DSLite is missing. |
| `make flash PORT=/dev/ttyACM0 ...` without confirmation | PASS | Refused because `CONFIRM_FLASH=YES` was not set. |
| Fake DSLite dry-run | PASS | Generated the expected `dslite flash -c ... -l ... -e -f -v -g ...` command. |
| Fake DSLite confirmed invocation | PASS | Called fake DSLite with the expected arguments; no hardware flash performed. |
| UFSETTINGS staging | PASS | Copied settings to `build/flash/generated.port.ufsettings` and replaced the port with `/dev/ttyACM0`. |

## Current Blocker

Actual hardware flashing was not attempted because TI UniFlash/DSLite is not
installed on the lab PC. Install TI UniFlash for Linux or pass a valid
`DSLITE=/path/to/dslite.sh`, `CCXML=/path/to/device.ccxml`, and optional
`UFSETTINGS=/path/to/generated.ufsettings`.

## Safety Status

- Serial port is mandatory.
- The scripts do not auto-select a serial port.
- Actual flashing requires `CONFIRM_FLASH=YES`.
- Source UniFlash settings are not modified in place.
