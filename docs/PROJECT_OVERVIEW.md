# 项目总览

`ti-mmwave-build-tools` 是一个面向 TI 毫米波雷达固件开发的构建与工程生成工具仓库。它的核心目标不是重新实现 TI SDK，也不是把 TI 的 SDK、Toolbox、编译器或固件二进制塞进开源仓库，而是提供一套干净、可复现、可验证的开发外壳：用 Docker 固定工具环境，用 CMake 和 Ninja 统一工程入口，用 profile 描述不同板卡和 demo 的构建边界，用 CI 检查工程结构和可移植性。

仓库当前最稳定的主线是 TI mmWave SDK 03.x 的 OOB demo fork 流程。用户可以通过私有 SDK-full Docker 镜像运行 `create-mmwave-app`，从已验证的 TI SDK demo 生成一个普通的 CMake/Ninja 工程。生成后的工程会把 TI demo 复制到本地 `app/` 目录，保留原始 TI makefile，再由 CMake/Ninja 调用 TI 的构建流程。这种方式的好处是稳：不会提前改写 TI 的复杂编译逻辑，同时又能让用户用现代工程入口管理构建。

项目结构分为几层。`scripts/` 放所有命令入口，包括 Docker 构建、项目生成、SDK profile 验证、UniFlash dry-run、清理和测试脚本。`templates/mmwave-cmake-project/` 是仓库内生成器模板。`docs/install.py` 是面向新用户的 GitHub Pages no-clone 入口。`cmake/` 保存可复用的 CMake helper，用来发现 TI SDK 路径、封装 configuro 和 metaimage 等步骤。`config/demo-profiles.tsv` 是当前 6 个 starter demo 的规范 manifest；`docs/STARTER_DEMOS.md` 说明这些 profile 的统一命名、存放位置和生成工程结构。`config/toolbox-oob-profiles.tsv` 是 TI Radar Toolbox OOB demo 的轻量目录；`config/toolbox-application-profiles.tsv` 是应用级 demo 目录，例如 6843AOP People Tracking、Area Scanner 和 Automated Doors。两个 Toolbox manifest 都只记录路径、芯片族、核心结构、预编译产物和适用层级，不提交任何 TI 源码或二进制。

初版 starter 目标固定为三块板卡乘以两种核心形态：`xwr1843boost-mss-only`、`xwr1843boost-mss-dss`、`xwr6843isk-mss-only`、`xwr6843isk-mss-dss`、`xwr6843aop-mss-only`、`xwr6843aop-mss-dss`。其中 SDK makefile 可直接生成的 profile 会进入 direct-vs-fork SHA-256 测试：先直接构建 TI SDK 原始 demo，再构建由模板生成的 CMake/Ninja fork 工程，最后比较输出物的 SHA。MSS-only profile 比较 R4F `*.xer4f`，MSS+DSS profile 比较 flash 用 `.bin`。`xwr6843aop-mss-dss` 先按 Toolbox projectspec 记录，等 projectspec importer 完成后进入同样的构建验证。

Toolbox 方向已经做了完整扫描，但还没有直接开放生成。Radar Toolbox 的 OOB 目录里不仅有 1843 和 6843，也有 xWR1443、xWR1642、xWR6443、IWR6843AOP、IWR6843ISK、IWR6843ODS，以及 AWR2544、AWR294x、AWR2x44、xWRL1432、xWRL6432 等新 SDK 家族。仓库会全面记录这些入口，但按适配难度分层：SDK3 类 OOB 是下一阶段最适合做初次工程生成的目标；L-SDK 和 MCU+ SDK 类 OOB 先记录，等有对应适配器后再进入生成流程。

MSS 和 DSS 的处理规则是：核心结构由 profile 决定，不让用户手动猜。TI OOB 目录里的 `xwr6843AOP` 入口是单 projectspec，应按独立 OOB 目标处理；但 6843AOP 并不等于 MSS-only。Radar Toolbox 的 3D People Tracking、Low Power People Tracking、Area Scanner、Automated Doors、Overhead 3D People Tracking 等应用 demo 都有 6843 MSS+DSS projectspec，并通过 AOP cfg 或 AOP 预编译镜像区分板级形态。未来生成器应按 manifest 决定：OOB 单工程就生成 MSS-only 工程，应用级双核 demo 就生成 MSS+DSS 工程。不要把双核 demo 强行裁成单核，也不要把 AOP 粗暴映射成 ISK。

为了不污染开发机，生成工程会带 `tools/mmwave-run`。它用 Docker 启动一次性容器，设置 `env -i`、`HOME=/tmp/mmwave-home`，交互 shell 使用 `bash --noprofile --norc`，项目挂载到 `/work/app`。这意味着构建不会修改用户的 `.bashrc`、`.zshrc`、profile 文件，也不会把 TI SDK 路径写进宿主机环境。不同系统的开发者只要共享同一份 git 工程和同一个私有 SDK-full 镜像，就能用一致的 CMake/Ninja 命令构建和验证。

CI 分为公开和私有两层。公开 GitHub Actions 不需要 TI SDK，主要检查脚本语法、工作流结构、CMake 基础配置、模板完整性、profile manifest 格式和 Docker 工具镜像。私有层依赖 SDK-full Docker 镜像，用于真实构建 firmware，并执行 SHA 验证。未来如果接入自托管 labpc runner，还可以把完整 SDK 构建、性能对比、甚至受控 UniFlash 流程纳入手动触发的 CI。

这个仓库的边界也很清楚：它是构建环境、工程模板、验证和刷写辅助工具，不是 TI SDK 镜像的公开分发仓库。`build/`、`artifacts/`、`reports/`、`packages/` 都是生成物，不应入库；TI Toolbox zip、解压源码、预编译固件也不应入库。仓库应该保持轻、清楚、可审计，把重资产放在 labpc 或私有镜像中。

下一步规划是先保持现有 SDK demo profile 稳定，然后实现 Toolbox projectspec importer，把 `config/toolbox-oob-profiles.tsv` 里的 SDK3 `starter-sdk3` 层和 `config/toolbox-application-profiles.tsv` 里的 `starter-application` 层逐步提升为可生成工程。完成后，用户不仅能生成 1843 和 6843ISK 工程，也能按 TI 的完整 OOB 体系生成 MSS-only 或 MSS+DSS 的初始项目，并进一步生成 6843AOP 这类应用级双核工程。
