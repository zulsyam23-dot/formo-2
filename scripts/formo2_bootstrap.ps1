param(
    [switch]$SkipCheck
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pathHelper = Join-Path $PSScriptRoot "formo_repo_paths.ps1"
$syncScript = Join-Path $PSScriptRoot "dev_sync_formo_vscode_extension.ps1"
$workspaceFile = Join-Path $repoRoot "formo2.code-workspace"
$localCargoTarget = Join-Path $repoRoot "target\cargo-shared"

if (-not (Test-Path $pathHelper)) {
    throw "path helper script not found: $pathHelper"
}

. $pathHelper

if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    throw "cargo is not available in PATH. install Rust toolchain first (https://rustup.rs/)."
}

$resolution = Resolve-FormoLibrary -RepoRoot $repoRoot -AutoInstall
if (-not $resolution) {
    throw "library Cargo manifest not found. run this script with internet access once, or set FORMO_LIBRARY_ROOT / FORMO_LIBRARY_MANIFEST."
}
$manifestPath = $resolution.ManifestPath

if (-not (Test-Path $workspaceFile)) {
    throw "workspace file not found: $workspaceFile"
}

New-Item -Path $localCargoTarget -ItemType Directory -Force | Out-Null
$env:CARGO_TARGET_DIR = $localCargoTarget

& powershell -ExecutionPolicy Bypass -File $syncScript -Scope local -CleanupGlobal

if (-not $SkipCheck) {
    & cargo run --manifest-path $manifestPath -p formo-cli -- check --input (Join-Path $repoRoot "main.fm")
    if ($LASTEXITCODE -ne 0) {
        throw "formo2 bootstrap check failed"
    }
}

Write-Host "formo2 bootstrap complete."
Write-Host "workspace: $workspaceFile"
Write-Host "library manifest: $($resolution.ManifestPath)"
Write-Host "library source: $($resolution.Source)"
