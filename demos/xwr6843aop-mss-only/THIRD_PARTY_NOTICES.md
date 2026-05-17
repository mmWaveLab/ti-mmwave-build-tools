# Third-Party Notices

This repository contains project-owned tooling plus a small source-only copy of
selected Texas Instruments mmWave SDK demo files.

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
