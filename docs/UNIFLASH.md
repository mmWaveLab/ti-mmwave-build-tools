# UniFlash Integration

This project treats flashing as a host-side operation.

Docker builds the firmware. TI UniFlash/DSLite runs on the host so it can access
USB serial devices directly and avoid storing host USB state inside the build
container.

## Safety Rules

- Always pass `PORT`; scripts never auto-select a serial port.
- Use `make flash-dry-run` before `make flash`.
- Real flashing requires `CONFIRM_FLASH=YES`.
- Generated settings are copied into `build/flash/` before serial-port
  substitution. Original UniFlash files are not edited.
- Flash logs are written under `reports/`.

## Inputs

Required for dry-run and flash:

- `PORT`: serial download port, for example `/dev/ttyACM0`.
- `BIN`: firmware image to flash. If omitted, the scripts prefer the validated
  xWR68xx artifact.
- `DSLITE`: path to TI UniFlash `dslite.sh` or `dslite`.
- `CCXML`: TI target configuration file.

Optional but recommended:

- `UFSETTINGS`: UniFlash generated settings file.
- `UNIFLASH_ROOT`: root of a TI UniFlash install; used to discover DSLite.
- `UNIFLASH_CLI_DIR`: generated UniFlash CLI package; used to discover CCXML
  and generated settings.

## Commands

List serial ports:

```bash
make flash-list
```

Check integration status:

```bash
make flash-doctor
```

Generate the command without flashing:

```bash
make flash-dry-run \
  PORT=/dev/ttyACM0 \
  BIN=build/sdk-image-smoke/smoke-xwr6843isk-mss-dss/build/app/xwr68xx_mmw_demo.bin \
  DSLITE=/path/to/uniflash/dslite.sh \
  CCXML=/path/to/mmwave.ccxml \
  UFSETTINGS=/path/to/generated.ufsettings
```

Flash only after the dry-run command looks right:

```bash
make flash \
  PORT=/dev/ttyACM0 \
  BIN=build/sdk-image-smoke/smoke-xwr6843isk-mss-dss/build/app/xwr68xx_mmw_demo.bin \
  DSLITE=/path/to/uniflash/dslite.sh \
  CCXML=/path/to/mmwave.ccxml \
  UFSETTINGS=/path/to/generated.ufsettings \
  CONFIRM_FLASH=YES
```

## Lab PC Status

The integration can be tested without a UniFlash install:

- `make flash-list` should enumerate attached `/dev/ttyACM*` or `/dev/ttyUSB*`
  ports.
- `make flash-doctor` should report missing DSLite if UniFlash is absent.
- `make flash-dry-run` should fail before flashing when DSLite or CCXML is not
  available.
- `make flash` should refuse to run unless `CONFIRM_FLASH=YES` is set.

Actual flash verification requires TI UniFlash for Linux plus a board in
download mode.
