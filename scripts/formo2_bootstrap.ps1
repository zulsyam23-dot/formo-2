param(
    [switch]$SkipCheck
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$libraryRoot = Join-Path $repoRoot "..\formo-library-ecosystem"
$manifestPath = Join-Path $libraryRoot "Cargo.toml"
$syncScript = Join-Path $PSScriptRoot "dev_sync_formo_vscode_extension.ps1"
$workspaceFile = Join-Path $repoRoot "formo2.code-workspace"

if (-not (Test-Path $libraryRoot)) {
    throw "library repo not found: $libraryRoot"
}

if (-not (Test-Path $manifestPath)) {
    throw "library Cargo manifest not found: $manifestPath"
}

if (-not (Test-Path $workspaceFile)) {
    throw "workspace file not found: $workspaceFile"
}

& powershell -ExecutionPolicy Bypass -File $syncScript -Scope local -CleanupGlobal

if (-not $SkipCheck) {
    & cargo run --manifest-path $manifestPath -p formo-cli -- check --input (Join-Path $repoRoot "main.fm")
    if ($LASTEXITCODE -ne 0) {
        throw "formo2 bootstrap check failed"
    }
}

Write-Host "formo2 bootstrap complete."
Write-Host "workspace: $workspaceFile"
