# TI mmWave SDK Docker 构建工具

[English](README.md) | [中文](README.zh-CN.md)

这是面向 TI mmWave SDK 03.06 MSS+DSS demo 固件的可复现 Linux 构建、
验证和烧录辅助工具集。

本仓库围绕已有 TI SDK 安装提供主机侧胶水层：用 Docker 隔离依赖，
用 CMake+Ninja 提供固件构建入口，支持 starter 项目验证、原生与
Docker 构建基准对比，以及带保护的 UniFlash 命令生成。

仓库内带有少量仅源码形式的 TI mmWave SDK `packages/ti/demo` 和 Radar
Toolbox starter demo 副本，用作可 fork 的 starter 项目，并保留上游 TI
声明。本仓库不重新分发 TI 编译器、UniFlash、radarss 固件镜像、预构建
demo 二进制或其他 SDK 二进制组件。构建时需要自备 TI 安装，或者使用私有
SDK-full Docker 镜像。详见 `THIRD_PARTY_NOTICES.md`。

## 当前能力

- 在 Linux 上构建 TI mmWave SDK 03.06 demo 固件。
- 通过 CMake 和 Ninja 构建 `xwr68xx/mmw` MSS+DSS。
- 从 TI SDK 或 Radar Toolbox demo 创建可 fork 的 mmWave CMake/Ninja 固件项目。
- 在 Docker 中验证 starter OOB demo fork。
- 对比 TI OOB demo 直接构建与生成 starter 项目的 SHA-256。
- 对比 Docker 和 Ubuntu 原生构建时间与输出哈希。
- 显式指定串口生成安全的 UniFlash/DSLite 命令。
- 将生成输出收敛在 `build/`、`artifacts/` 和 `reports/` 下。

## 当前状态

| 领域 | 状态 | 证据 |
|---|---:|---|
| Docker SDK 环境 | 已验证 | `make doctor`, `make test`, `make ci` |
| CMake+Ninja MSS+DSS 构建 | 已验证 | Docker/native SHA-256 一致 |
| Starter demo fork SHA 对比 | 每次 push 门禁 | `sdk-full-sha256` GitHub Actions job |
| UniFlash 集成层 | 有保护测试 | `make flash-doctor`, `make flash-dry-run` |
| 真实硬件烧录 | 待完成 | 需要 TI UniFlash/DSLite 和处于下载模式的板卡 |

## 快速开始

在已安装 TI 工具的 Linux 主机上：

```bash
cp config/machine.env.example config/machine.env
```

编辑 `config/machine.env`：

```bash
HOST_TI_ROOT=/path/to/ti
TI_ROOT=/path/to/ti
CONTAINER_TI_ROOT=/opt/ti
```

构建并测试：

```bash
make docker-build
make doctor
make test
make sdk-profile-validate
```

构建 CMake+Ninja MSS+DSS 示例：

```bash
make docker-cmake
```

不克隆本工具仓库，直接创建并构建一个新的 fork CMake 项目：

```bash
python3 <(curl -fsSL https://mmwavelab.github.io/ti-mmwave-build-tools/install.py) \
  --name people-count-6843 \
  --cmake-name people_count_6843 \
  --profile xwr6843isk-mss-dss \
  --image meowpas/ti-mmwave-sdk:03.06.02 \
  --build
```

GitHub Pages installer 只需要 Python 和 Docker。它会拉取或使用 SDK-full
Docker 镜像，从本仓库 archive 下载选定的 vendored demo，写出一个独立的
CMake/Ninja wrapper，并且不会克隆 `ti-mmwave-build-tools`。

列出常用 TI demo fork profiles：

```bash
python3 <(curl -fsSL https://mmwavelab.github.io/ti-mmwave-build-tools/install.py) \
  --list-profiles
```

检查 UniFlash 准备状态：

```bash
make flash-list
make flash-doctor
```

## SDK 路径约定

容器内通过 `CONTAINER_TI_ROOT` 看到 TI 安装，默认是 `/opt/ti`。这个路径保持
稳定是有意的，因为 TI XDC/configuro 和生成的 make 片段会嵌入 SDK 与工具链
的绝对路径。

宿主机路径可以不同。把 `HOST_TI_ROOT` 设置为真实 TI 安装路径，脚本会以只读
方式把它挂载进容器。

## Starter Profiles

初始 starter 矩阵刻意保持小而明确。每块支持板卡都有一个 `mss-only` 和一个
`mss-dss` profile：

| Board | MSS-only profile | MSS+DSS profile |
|---|---|---|
| xWR1843BOOST | `xwr1843boost-mss-only` | `xwr1843boost-mss-dss` |
| xWR6843ISK | `xwr6843isk-mss-only` | `xwr6843isk-mss-dss` |
| xWR6843AOP | `xwr6843aop-mss-only` | `xwr6843aop-mss-dss` |

SDK 和 Toolbox make 行都会暴露一个可烧录的 metaimage `.bin` 作为主产物。
对 18xx/68xx MSS-only profiles，wrapper 会先构建 MSS R4F 镜像，然后用
radarss 和 `NULL` DSS 输入调用 TI 的 `generateMetaImage.sh`。
`xwr6843aop-mss-dss` 是已转换的 Radar Toolbox 3D People Tracking starter
profile，可以由 `create-mmwave-app` 生成。

profile manifest 使用统一的 build entry 约定：
SDK 或 Toolbox makefile demo 使用 `build_entry_kind=make-target`，已编目的
Toolbox demo 使用 `build_entry_kind=ccs-projectspecs`。

Radar Toolbox 对 6843AOP 分为两层：

| Manifest | 含义 |
|---|---|
| `docs/catalog/toolbox-oob-demo-profiles.tsv` | TI OOB 源目录的原始编目。`xwr6843AOP` OOB entry 是一个独立 single-projectspec target。 |
| `docs/catalog/toolbox-application-demo-profiles.tsv` | 3D People Tracking、Area Scanner、Automated Doors、Overhead People Tracking 等应用 demo。6843AOP 相关条目使用 6843 MSS+DSS 项目加 AOP 配置或预构建镜像。 |

相关命令运行后，验证报告会写入 `reports/`。版本库只保存源码、文档、模板和
轻量 manifest。

## 可复用 CMake API

原有可复用 CMake helper API 仍保留在 `cmake/` 下，供下游固件仓库通过
submodule、subtree 或 `FetchContent` 继承通用 TI mmWave 构建规则。

关键文件：

- `cmake/TiMmwaveSdk.cmake`：可复用构建 API。
- `cmake/RunConfiguro.cmake`：XDC configuro wrapper。
- `cmake/RunMetaImage.cmake`：ImageCreator wrapper。
- `cmake/TiMmwaveSdkPaths.cmake`：本 Docker lab 使用的 Linux 路径发现逻辑。
- `demos/<profile>`：可编辑的已转换 CMake/Ninja starter 项目；可构建 profile
  的 forked TI demo 源码放在 `app/` 下。
- `THIRD_PARTY_NOTICES.md`：vendored demo 源码的 TI notice 与 license 记录。
- `templates/mmwave-cmake-project`：把某个已转换 demo 复制到用户目标目录时使用
  的独立项目脚手架。
- `config/starter-demo-profiles.tsv`：`create-mmwave-app --profile` 使用的 starter
  TI OOB demo fork profiles，包括 3 块板卡乘 2 种 core mode 的 starter 矩阵。
- `docs/install.py`：用于创建独立项目的 no-clone GitHub Pages installer。
- `docs/STARTER_DEMOS.md`：六个 profile 的规范约定和生成项目布局。
- `docs/AI_CONVERSION.md`：面向已有 TI SDK、Toolbox 或 CCS 项目的转换指南。
- `docs/catalog/toolbox-oob-demo-profiles.tsv`：轻量 TI Radar Toolbox OOB catalog。
- `docs/catalog/toolbox-application-demo-profiles.tsv`：轻量 TI Radar Toolbox 应用
  demo catalog，包括 6843AOP MSS+DSS 候选项。
- `docker/Dockerfile.sdk-full`：本地或私有 registry 使用的私有 SDK-full 镜像
  recipe。它包含 SDK/toolchain runtime，不包含本仓库转换后的 demo 项目。

本 README 中的 Docker 验证流会跑 SDK reference demo makefiles。需要更细粒度
源码级构建集成的下游固件项目，仍可直接使用可复用 CMake API。

## 常用命令

在容器中直接验证 TI Linux 工具：

```bash
docker run --rm \
  -v /opt/ti:/opt/ti:ro \
  ti-mmwave-build-tools:linux-smoke \
  check-ti-linux
```

运行上游仓库 smoke test：

```bash
docker run --rm \
  -v /opt/ti:/opt/ti:ro \
  -v "$PWD/work":/work \
  ti-mmwave-build-tools:linux-smoke \
  run-repo-smoke
```

这个 smoke test 会配置一个最小 CMake 工具发现项目，并使用显式 Linux 工具路径。
当需要确认上游 `mmWaveLab/ti-mmwave-build-tools` 是否仍适配 Linux SDK/toolchain
profile 时可以使用它。

用 TI reference SDK make flow 构建 xWR68xx demo：

```bash
scripts/build-xwr68xx-sdk-demo.sh
```

## 用 CMake 和 Ninja 构建 MSS+DSS

CMake 构建脚本会在 `build/` 下创建一个临时生成的 starter 项目，并通过 Ninja
构建它。Ninja target 驱动原始 TI make 规则，因此 MSS、DSS、SYS/BIOS RTSC
configuro 和 metaimage 生成都与 TI reference build 保持一致，同时不需要在仓库中
保留永久 `examples/` 项目。

Docker：

```bash
scripts/cmake-build-xwr68xx-sdk-demo.sh
```

Ubuntu 原生：

```bash
scripts/native-cmake-build-xwr68xx-sdk-demo.sh
```

## 测试、基准与清理

```bash
make doctor
make github-actions-smoke
make install-profile-validate
make test
make benchmark
make sdk-image
make sdk-image-smoke
make sdk-profile-validate
make flash-list
make flash-doctor
make package
make clean
```

生成文件位于：

- `build/`：CMake/Ninja build trees
- `artifacts/`：复制出的固件二进制
- `reports/`：benchmark 和验证报告

Docker 命令使用 `--rm`，因此正常构建结束后不会残留已停止容器。SDK 挂载是只读
的，所以构建不会写入 `/opt/ti`。

## CI 与维护

- CI 指南：`docs/CI.md`
- Starter demo 约定：`docs/STARTER_DEMOS.md`
- Docker 镜像指南：`docs/DOCKER_IMAGE.md`
- UniFlash 指南：`docs/UNIFLASH.md`

CI 入口：

```bash
make ci
```

完整 Docker/native 固件对比：

```bash
CI_FULL_BUILD=1 scripts/ci.sh
```

## UniFlash 集成

UniFlash 烧录只在宿主机侧执行。Docker 负责构建固件；宿主机运行 TI
UniFlash/DSLite，并使用用户选择的串口下载端口。

列出端口：

```bash
make flash-list
```

检查集成状态：

```bash
make flash-doctor
```

生成 dry-run 命令：

```bash
make flash-dry-run \
  PORT=/dev/ttyACM0 \
  BIN=build/sdk-image-smoke/smoke-xwr6843isk-mss-dss/build/app/xwr68xx_mmw_demo.bin \
  DSLITE=/path/to/uniflash/dslite.sh \
  CCXML=/path/to/mmwave.ccxml \
  UFSETTINGS=/path/to/generated.ufsettings
```

真实烧录需要显式确认：

```bash
make flash \
  PORT=/dev/ttyACM0 \
  BIN=build/sdk-image-smoke/smoke-xwr6843isk-mss-dss/build/app/xwr68xx_mmw_demo.bin \
  DSLITE=/path/to/uniflash/dslite.sh \
  CCXML=/path/to/mmwave.ccxml \
  UFSETTINGS=/path/to/generated.ufsettings \
  CONFIRM_FLASH=YES
```

`PORT` 始终必填。脚本不会自动选择串口。

在 `labpc` 上验证的数据：

- Ubuntu 原生 clean build：`60.44s`
- Docker clean build：`62.58s`
- Docker CMake+Ninja MSS+DSS benchmark：`62.61s`
- 原生 CMake+Ninja MSS+DSS benchmark：`62.47s`
- Docker/native CMake+Ninja 输出 SHA-256：
  `4d37093668aa1106fdde282cc6e3eb22b6b823e6d73b93dbff908f8e1fc9d0b6`
- 真实 SDK demo 的 Docker 开销：约 `3.5%`
- Docker 中 CMake tool-discovery smoke：约 `0.30s`
- 原生 CMake tool-discovery smoke：约 `0.01s`

追求最高速度时直接在 Ubuntu 上跑。追求可复现时 Docker 足够接近，并且能避免
宿主机依赖漂移。
