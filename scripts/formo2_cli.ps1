param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FormoArgs
)

$ErrorActionPreference = "Stop"

if (-not $FormoArgs -or $FormoArgs.Count -eq 0) {
    throw "usage: .\scripts\formo2_cli.ps1 <formo-cli args>"
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $repoRoot "..\formo-library-ecosystem\Cargo.toml"

if (-not (Test-Path $manifestPath)) {
    throw "library Cargo manifest not found: $manifestPath"
}

$cargoArgs = @(
    "run",
    "--manifest-path", $manifestPath,
    "-p", "formo-cli",
    "--"
) + $FormoArgs

Write-Host ">> cargo $($cargoArgs -join ' ')"
& cargo @cargoArgs
exit $LASTEXITCODE
