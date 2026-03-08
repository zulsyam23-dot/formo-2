param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FormoArgs
)

$ErrorActionPreference = "Stop"

if (-not $FormoArgs -or $FormoArgs.Count -eq 0) {
    throw "usage: .\scripts\formo2_cli.ps1 <formo-cli args>"
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$pathHelper = Join-Path $PSScriptRoot "formo_repo_paths.ps1"
$localCargoTarget = Join-Path $repoRoot "target\cargo-shared"

function Get-BoolEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [bool]$DefaultValue
    )

    $raw = [Environment]::GetEnvironmentVariable($Name)
    if ($null -eq $raw) {
        $raw = ""
    }
    $raw = $raw.Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $DefaultValue
    }
    if ($raw -in @("1", "true", "yes", "on")) {
        return $true
    }
    if ($raw -in @("0", "false", "no", "off")) {
        return $false
    }
    return $DefaultValue
}

if (-not (Test-Path $pathHelper)) {
    throw "path helper script not found: $pathHelper"
}

. $pathHelper

if ($FormoArgs[0] -eq "parity") {
    $parityScript = Join-Path $PSScriptRoot "ci_verify_logic_parity.ps1"
    $parityArgs = @()
    if ($FormoArgs.Count -gt 1) {
        $parityArgs = $FormoArgs[1..($FormoArgs.Count - 1)]
    }
    & powershell -ExecutionPolicy Bypass -File $parityScript @parityArgs
    exit $LASTEXITCODE
}

if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    throw "cargo is not available in PATH. install Rust toolchain first (https://rustup.rs/)."
}

$autoInstallByDefault = [string]::IsNullOrWhiteSpace($env:CI)
$autoInstallLibrary = Get-BoolEnv -Name "FORMO_LIBRARY_AUTO_INSTALL" -DefaultValue $autoInstallByDefault
$resolution = Resolve-FormoLibrary -RepoRoot $repoRoot -AutoInstall:$autoInstallLibrary -Quiet
if (-not $resolution) {
    throw "library Cargo manifest not found. run scripts/formo2_bootstrap.ps1 once, or set FORMO_LIBRARY_ROOT / FORMO_LIBRARY_MANIFEST."
}

if ($FormoArgs[0] -eq "where-library") {
    Write-Host "manifest: $($resolution.ManifestPath)"
    Write-Host "root: $($resolution.LibraryRoot)"
    Write-Host "source: $($resolution.Source)"
    if ($resolution.AutoInstalled) {
        Write-Host "autoInstalled: true"
    }
    exit 0
}

if ($resolution.AutoInstalled) {
    Write-Host "formo library prepared: $($resolution.LibraryRoot)"
}

if (-not $env:CARGO_TARGET_DIR) {
    New-Item -Path $localCargoTarget -ItemType Directory -Force | Out-Null
    $env:CARGO_TARGET_DIR = $localCargoTarget
}

$manifestPath = $resolution.ManifestPath
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
