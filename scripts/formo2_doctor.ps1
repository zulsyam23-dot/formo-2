param(
    [switch]$AutoInstall
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pathHelper = Join-Path $PSScriptRoot "formo_repo_paths.ps1"
$errors = 0

function Write-Check {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [ValidateSet("ok", "warn", "error")]
        [string]$Status,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $prefix = switch ($Status) {
        "ok" { "[ok]" }
        "warn" { "[warn]" }
        "error" { "[error]" }
    }
    Write-Host "$prefix ${Name}: $Message"
}

if (-not (Test-Path $pathHelper)) {
    Write-Check -Name "path-helper" -Status "error" -Message "missing: $pathHelper"
    exit 1
}

. $pathHelper

$cargoCmd = Get-Command cargo -ErrorAction SilentlyContinue
if ($cargoCmd) {
    Write-Check -Name "cargo" -Status "ok" -Message $cargoCmd.Source
} else {
    Write-Check -Name "cargo" -Status "error" -Message "not found in PATH"
    $errors++
}

$resolution = Resolve-FormoLibrary -RepoRoot $repoRoot -AutoInstall:$AutoInstall -Quiet
if ($resolution) {
    Write-Check -Name "library-manifest" -Status "ok" -Message $resolution.ManifestPath
    Write-Check -Name "library-source" -Status "ok" -Message $resolution.Source
    if ($resolution.AutoInstalled) {
        Write-Check -Name "library-cache" -Status "ok" -Message "freshly auto-installed"
    }
} else {
    Write-Check -Name "library-manifest" -Status "error" -Message "not found"
    $errors++
}

$extPkg = Join-Path $repoRoot ".vscode\formo-local-extension\package.json"
if (Test-Path $extPkg) {
    try {
        $pkg = Get-Content -Raw $extPkg | ConvertFrom-Json
        Write-Check -Name "editor-extension" -Status "ok" -Message "$($pkg.publisher).$($pkg.name)@$($pkg.version)"
    } catch {
        Write-Check -Name "editor-extension" -Status "warn" -Message "package.json exists but unreadable"
    }
} else {
    Write-Check -Name "editor-extension" -Status "warn" -Message "local extension source missing"
}

if ($errors -gt 0) {
    exit 1
}

Write-Host "formo2 doctor: healthy"
