# Third-Party Notices

This repository contains project-owned tooling plus selected Texas Instruments
mmWave SDK and Radar Toolbox starter demo files.

The repository root `LICENSE` applies to project-owned tooling, templates, and
documentation. It does not replace or override third-party notices preserved in
vendored files.

## Texas Instruments mmWave SDK Demo Sources

- Upstream package: TI mmWave SDK 03.06.02.00-LTS
- Upstream manifest: <https://dr-download.ti.com/software-development/software-development-kit-sdk/MD-PIrUeCYr3X/03.06.02.00-LTS/mmwave_sdk_software_manifest.html>
- Vendored paths:
  - `demos/xwr1843boost-mss-only/app`
  - `demos/xwr1843boost-mss-dss/app`
  - `demos/xwr6843isk-mss-only/app`
  - `demos/xwr6843isk-mss-dss/app`
  - `demos/xwr6843aop-mss-only/app`
- Manifest license for `packages/ti/demo`: BSD-3-Clause

The vendored copy is limited to source and configuration files used as starter
project fork points. It intentionally excludes generated build outputs,
prebuilt firmware images, TI toolchains, radarss firmware images, UniFlash, and
other binary SDK components.

The upstream TI copyright and license notices inside source files are preserved
verbatim. Do not remove or normalize those notices when updating vendored demo
files.

BSD-3-Clause text used by the TI demo source headers:

```text
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the
distribution.

Neither the name of Texas Instruments Incorporated nor the names of
its contributors may be used to endorse or promote products derived
from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

## Texas Instruments Radar Toolbox Demo Sources

- Upstream package: TI Radar Toolbox 4.00.00.05
- Upstream demo path: `source/ti/examples/Industrial_and_Personal_Electronics/People_Tracking/3D_People_Tracking`
- Upstream support path: `source/ti/custom_sdk_files/sdk3`
- Vendored path:
  - `demos/xwr6843aop-mss-dss/app`
- Vendored binary dependency:
  - `demos/xwr6843aop-mss-dss/app/dpu/trackerproc_overhead/packages/ti/alg/gtrack/lib/libgtrack3D.aer4f`

This copy is limited to the converted 3D People Tracking starter project and
the minimal Radar Toolbox support files needed to build it. It intentionally
excludes the full Radar Toolbox tree, generated build outputs, prebuilt demo
images, TI toolchains, radarss firmware images, UniFlash, and other unrelated
binary components.

Limited License text used by the TI Radar Toolbox demo source headers:

```text
All rights reserved not granted herein.
Limited License.

Texas Instruments Incorporated grants a world-wide, royalty-free,
non-exclusive license under copyrights and patents it now or hereafter
owns or controls to make, have made, use, import, offer to sell and sell ("Utilize")
this software subject to the terms herein. With respect to the foregoing patent
license, such license is granted solely to the extent that any such patent is necessary
to Utilize the software alone. The patent license shall not apply to any combinations which
include this software, other than combinations with devices manufactured by or for TI ("TI Devices").
No hardware patent is licensed hereunder.

Redistributions must preserve existing copyright notices and reproduce this license
(including the above copyright notice and the disclaimer and (if applicable) source code
license limitations below) in the documentation and/or other materials provided with
the distribution.

Redistribution and use in binary form, without modification, are permitted provided that
the following conditions are met:

* No reverse engineering, decompilation, or disassembly of this software is permitted
  with respect to any software provided in binary form.
* any redistribution and use are licensed by TI for use only with TI Devices.
* Nothing shall obligate TI to provide you with source code for the software licensed
  and provided to you in object code.

If software source code is provided to you, modification and redistribution of the
source code are permitted provided that the following conditions are met:

* any redistribution and use of the source code, including any resulting derivative
  works, are licensed by TI for use only with TI Devices.
* any redistribution and use of any object code compiled from the source code and any
  resulting derivative works, are licensed by TI for use only with TI Devices.

Neither the name of Texas Instruments Incorporated nor the names of its suppliers may
be used to endorse or promote products derived from this software without specific
prior written permission.

THIS SOFTWARE IS PROVIDED BY TI AND TI'S LICENSORS "AS IS" AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TI AND TI'S
LICENSORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
