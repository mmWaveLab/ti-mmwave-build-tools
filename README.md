# ti-mmwave-build-tools

Git-friendly CMake/Ninja build tooling for TI mmWave SDK projects.

The goal is to keep application repositories small and reviewable while sharing
one build implementation across many mmWave firmware projects. Downstream
projects can inherit this repository with a git submodule, subtree, or CMake
`FetchContent`.

## What This Provides

- MSS-only builds for xWR68xx/IWR6843AOP-style applications.
- MSS + DSS metaimage composition for dual-core projects.
- SYS/BIOS `configuro` automation without importing a CCS project.
- Direct ImageCreator integration without the fragile SDK batch wrappers.
- Tool discovery for common `C:\ti` installations.
- Layered device/board/project configuration.

## Repository Layout

```text
cmake/
  TiMmwaveSdk.cmake       Core build API.
  RunConfiguro.cmake      Robust XDC configuro wrapper.
  RunMetaImage.cmake      Robust ImageCreator wrapper.
  devices/xwr68xx.cmake   Device defaults.
  boards/iwr6843aop.cmake Board defaults.
scripts/
  bootstrap-windows.ps1   Install/check open tools and detect TI tools.
examples/
  breath-rate-6843aop/    Minimal downstream CMake example.
```

## Inherit From A Firmware Repo

As a submodule:

```powershell
git submodule add https://github.com/<you>/ti-mmwave-build-tools.git tools/ti-mmwave-build-tools
```

In the firmware repo `CMakeLists.txt`:

```cmake
cmake_minimum_required(VERSION 3.20)
project(my_mmwave_app NONE)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/tools/ti-mmwave-build-tools/cmake")
include(TiMmwaveSdk)
include(devices/xwr68xx)
include(boards/iwr6843aop)

ti_mmwave_find_tools()

ti_mmwave_add_mss_image(
    TARGET my_mss
    OUTPUT "${CMAKE_BINARY_DIR}/mss/my_mss.xer4f"
    CONFIG "${CMAKE_CURRENT_LIST_DIR}/mmw.cfg"
    LINKER "${CMAKE_CURRENT_LIST_DIR}/mss_mmw_linker.cmd"
    SOURCES
        "${CMAKE_CURRENT_LIST_DIR}/main.c"
        "${CMAKE_CURRENT_LIST_DIR}/objectdetection.c"
    INCLUDES
        "${CMAKE_CURRENT_LIST_DIR}"
)

ti_mmwave_add_metaimage(
    TARGET firmware_bin
    OUTPUT "${CMAKE_BINARY_DIR}/my_app.bin"
    MSS_IMAGE "${CMAKE_BINARY_DIR}/mss/my_mss.xer4f"
    DSS_IMAGE "NULL"
    DEPENDS my_mss
)
```

Build:

```powershell
cmake -S . -B build -G Ninja -DTI_ROOT=C:\ti
cmake --build build --target firmware_bin
```

## Layered Configuration

The intended inheritance model is:

```text
tool defaults -> device defaults -> board defaults -> project overrides
```

For example:

- `devices/xwr68xx.cmake` sets `MMWAVE_SDK_DEVICE`, `MMWAVE_SDK_DEVICE_TYPE`,
  shared-memory defaults, and platform identity.
- `boards/iwr6843aop.cmake` sets AOP antenna and board defines.
- The application CMake file owns source lists, linker scripts, and output names.

This keeps hardware and SDK policy shared while application code stays local.

## License

The build tooling in this repository is MIT licensed. TI SDKs, compilers,
SYS/BIOS, radar firmware, and libraries are not redistributed here and remain
under their respective TI licenses.
