param(
    [string]$TiRoot = "C:\ti",
    [switch]$InstallOpenTools
)

$ErrorActionPreference = "Stop"

function Test-Command($Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

if ($InstallOpenTools) {
    if (Test-Command scoop) {
        if (-not (Test-Command cmake)) { scoop install cmake }
        if (-not (Test-Command ninja)) { scoop install ninja }
    } elseif (Test-Command winget) {
        if (-not (Test-Command cmake)) { winget install --id Kitware.CMake -e --accept-package-agreements --accept-source-agreements }
        if (-not (Test-Command ninja)) { winget install --id Ninja-build.Ninja -e --accept-package-agreements --accept-source-agreements }
    } else {
        throw "Neither scoop nor winget is available. Install CMake and Ninja manually."
    }
}

$required = [ordered]@{
    "mmWave SDK" = Join-Path $TiRoot "mmwave_sdk_03_06_02_00-LTS"
    "SYS/BIOS" = Join-Path $TiRoot "bios_6_73_01_01"
    "XDCtools" = Join-Path $TiRoot "xdctools_3_50_08_24_core"
    "ARM CGT" = Join-Path $TiRoot "ti-cgt-arm_16.9.6.LTS"
    "C674 CGT" = Join-Path $TiRoot "ti-cgt-c6000_8.3.3"
    "DSPLIB C64Px" = Join-Path $TiRoot "dsplib_c64Px_3_4_0_0"
    "MATHLIB C674x" = Join-Path $TiRoot "mathlib_c674x_3_1_2_1"
}

$rows = foreach ($item in $required.GetEnumerator()) {
    [pscustomobject]@{
        Component = $item.Key
        Path = $item.Value
        Found = Test-Path $item.Value
    }
}

$rows | Format-Table -AutoSize

$missing = $rows | Where-Object { -not $_.Found }
if ($missing) {
    Write-Warning "Some TI components are missing. They are not redistributed by this project; install them from TI, then rerun this script."
    exit 2
}

Write-Host "Open tools and TI tool roots look ready."
