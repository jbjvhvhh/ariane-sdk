param(
    [string]$Output = ""
)

$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot

git submodule update --init --recursive

if ([string]::IsNullOrWhiteSpace($Output)) {
    make XLEN=64 BOARD=atk_ku040
} else {
    make XLEN=64 BOARD=atk_ku040 OUTPUT=$Output
}
