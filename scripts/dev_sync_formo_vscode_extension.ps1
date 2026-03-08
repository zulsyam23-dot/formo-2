param(
    [ValidateSet("local", "global")]
    [string]$Scope = "local",
    [switch]$CleanupGlobal
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceDir = Join-Path $repoRoot ".vscode\formo-local-extension"

if (-not (Test-Path $sourceDir)) {
    throw "source extension not found: $sourceDir"
}

$pkgPath = Join-Path $sourceDir "package.json"
$pkg = Get-Content -Raw $pkgPath | ConvertFrom-Json
$extId = "$($pkg.publisher).$($pkg.name)"
$version = "$($pkg.version)"

if ($Scope -eq "local") {
    $extensionsRoot = Join-Path $repoRoot ".vscode\.extensions"
} else {
    $extensionsRoot = Join-Path $env:USERPROFILE ".vscode\extensions"
}

if (-not (Test-Path $extensionsRoot)) {
    New-Item -ItemType Directory -Path $extensionsRoot -Force | Out-Null
}

$targetDir = Join-Path $extensionsRoot "$extId-$version"

Get-ChildItem $extensionsRoot -Directory -Filter "$extId-*" -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force

New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
Copy-Item -Path (Join-Path $sourceDir "*") -Destination $targetDir -Recurse -Force

if ($CleanupGlobal) {
    $installed = & code --list-extensions
    if ($installed -contains $extId) {
        & code --uninstall-extension $extId | Out-Null
    }
}

Write-Host "formo extension synced to: $targetDir"
