# Demo Selection

This repository should provide small, board-oriented starting points first.
Application demos can be added later after the projectspec importer is stable.

## Selection Rules

Prefer a demo for first project generation when it has:

- a board bring-up purpose instead of a full application workflow
- a small projectspec surface
- a prebuilt binary in Toolbox for reference
- SDK 03.x / xWR18xx or xWR68xx compatibility
- clear MSS or MSS+DSS structure

Avoid first-wave templates when a demo:

- needs a different SDK family such as L-SDK or MCU+ SDK
- mixes many boards and build systems in one folder
- is primarily a full application rather than a minimal firmware fork
- requires custom import logic that is not validated yet

## First-Wave Toolbox Candidates

| Candidate | Board | Source | Cores | Why |
|---|---|---|---:|---|
| `iwr1843boost-toolbox-oob` | IWR1843BOOST | `source/ti/examples/Out_Of_Box_Demo/src/xwr1843` | MSS+DSS | Common board, direct OOB bring-up, separate MSS/DSS projectspecs. |
| `iwr6843isk-toolbox-oob` | IWR6843ISK | `source/ti/examples/Out_Of_Box_Demo/src/xwr6843ISK` | MSS+DSS | Main 68xx ISK bring-up path, separate MSS/DSS projectspecs. |
| `iwr6843aop-toolbox-oob` | IWR6843AOP | `source/ti/examples/Out_Of_Box_Demo/src/xwr6843AOP` | MSS | AOP is a real separate Toolbox OOB target; do not alias it to ISK. |

These should be the first Toolbox-backed generated project profiles after the
projectspec importer is implemented. Until then they stay `analysis-only` in
`config/toolbox-oob-profiles.tsv`.

## Second-Wave Application Candidates

| Demo | Boards seen | Cores | Why later |
|---|---|---:|---|
| `Industrial_and_Personal_Electronics/People_Tracking/3D_People_Tracking` | 6843 | MSS+DSS | High user value, but more application-specific than OOB. |
| `Industrial_and_Personal_Electronics/Area_Scanner` | 6843 | MSS+DSS | Useful 68xx application, but should wait for OOB projectspec import. |
| `Industrial_and_Personal_Electronics/Long_Range_People_Detection` | 6843 / 6443 | MSS+DSS | Useful, but mixes more board variants. |
| `Industrial_and_Personal_Electronics/People_Tracking/3D_People_Tracking_Low_Power` | 6843AOP / 6843ISK / 6843ODS | MSS+DSS | Good AOP/ISK runtime comparison target after basic AOP import works. |
| `Fundamentals/Enabling_57_to_61_GHz_Bandwidth` | 6843AOP / 6843ISK / 6843ODS | MSS+DSS | Useful hardware variant demo, not a first default project. |

## Not First-Wave

- xWRL6432 / xWRL1432 / other L-SDK demos: different SDK and toolchain flow.
- AWR294x / AWR2x44 / AWR2544 demos: MCU+ SDK or DFP-style flow, not this
  SDK 03.x CMake/Ninja path.
- Large automotive demos: useful later, but not ideal for a clean first fork.

## Testing Strategy

Dual SHA remains a CI method for SDK makefile profiles: build the original demo
and generated fork, then compare firmware bytes. For Toolbox profiles, the next
step is projectspec-to-CMake import validation. After import works, use the same
principle: compare generated build artifacts against the closest TI reference
build or prebuilt binary when reproducibility permits.
