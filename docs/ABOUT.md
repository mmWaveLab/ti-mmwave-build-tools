# Repository About

Use this page as the source text for the GitHub repository About panel and
public project description.

## Short Description

Reproducible private Docker SDK images, CMake/Ninja fork templates, validation,
and UniFlash helpers for TI mmWave SDK 03.06 firmware builds.

## Website

Leave empty unless a project site or published documentation page is added.

## Topics

```text
ti
mmwave
mmwave-sdk
iwr6843
iwr1843
iwr1642
awr1843
awr1642
embedded
firmware
docker
cmake
ninja
template
uniflash
dslite
radar
```

## Long About

This repository provides a repeatable Linux environment for building and
validating TI mmWave SDK 03.06 demo firmware without redistributing TI-owned
SDKs or compilers. It focuses on first-generation TI mmWave SDK MSS+DSS demo
flows, including Docker dependency isolation, CMake+Ninja build entry points,
private SDK-full image creation, CMake+Ninja fork project scaffolding,
device-matrix validation, Docker-vs-native benchmarks, and guarded host-side
UniFlash command generation.

## Chinese Summary

面向 TI mmWave SDK 03.06 的可复现 Linux 构建与验证环境：使用 Docker 隔离依赖，
提供私有 SDK-full Docker 镜像、CMake+Ninja fork 工程模板、1 代毫米波 demo
矩阵验证、原生与 Docker 构建对比，以及需要显式串口和确认参数的
UniFlash/DSLite 刷写封装。

## Boundary

This project validates build and packaging flows. It does not claim that every
generated binary has been flashed to hardware, and it does not mark newer TI
device generations as unsupported. Devices such as AWR2x44P, AWR2544, AWR294x,
AWR1243, AWR2243, and newer low-power parts use different TI SDK or DFP flows.
