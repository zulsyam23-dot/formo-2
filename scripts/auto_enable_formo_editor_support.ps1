param()

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$syncScript = Join-Path $PSScriptRoot "dev_sync_formo_vscode_extension.ps1"
$sourceDir = Join-Path $repoRoot ".vscode\formo-local-extension"

if (-not (Test-Path $syncScript)) {
    throw "sync script not found: $syncScript"
}

if (-not (Test-Path $sourceDir)) {
    throw "local extension source not found: $sourceDir"
}

$pkgPath = Join-Path $sourceDir "package.json"
$pkg = Get-Content -Raw $pkgPath | ConvertFrom-Json
$extId = "$($pkg.publisher).$($pkg.name)"
$version = "$($pkg.version)"

& $syncScript -Scope global
& $syncScript -Scope local

Write-Host "formo editor support ready: $extId@$version"
