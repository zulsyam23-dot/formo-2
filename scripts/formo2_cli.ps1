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
$localCargoTarget = Join-Path $repoRoot "target\cargo-shared"

if ($FormoArgs[0] -eq "parity") {
    $parityScript = Join-Path $PSScriptRoot "ci_verify_logic_parity.ps1"
    $parityArgs = @()
    if ($FormoArgs.Count -gt 1) {
        $parityArgs = $FormoArgs[1..($FormoArgs.Count - 1)]
    }
    & powershell -ExecutionPolicy Bypass -File $parityScript @parityArgs
    exit $LASTEXITCODE
}

if (-not (Test-Path $manifestPath)) {
    throw "library Cargo manifest not found: $manifestPath"
}

if (-not $env:CARGO_TARGET_DIR) {
    New-Item -Path $localCargoTarget -ItemType Directory -Force | Out-Null
    $env:CARGO_TARGET_DIR = $localCargoTarget
}

$cargoArgs = @(
    "run",
    "--manifest-path", $manifestPath,
    "-p", "formo-cli",
    "--"
) + $FormoArgs

Write-Host ">> cargo $($cargoArgs -join ' ')"
Write-Host ">> CARGO_TARGET_DIR=$env:CARGO_TARGET_DIR"
& cargo @cargoArgs
exit $LASTEXITCODE
