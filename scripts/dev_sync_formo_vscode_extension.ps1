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

function Remove-ExtensionEntriesFromObsolete {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath,
        [Parameter(Mandatory = $true)]
        [string]$ExtensionId
    )

    $obsoletePath = Join-Path $RootPath ".obsolete"
    if (-not (Test-Path $obsoletePath)) {
        return
    }

    $raw = Get-Content -Raw $obsoletePath
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return
    }

    $obj = $raw | ConvertFrom-Json
    $keysToKeep = @()

    foreach ($prop in $obj.PSObject.Properties) {
        if ($prop.Name -notlike "$ExtensionId-*") {
            $keysToKeep += $prop.Name
        }
    }

    if ($keysToKeep.Count -eq $obj.PSObject.Properties.Count) {
        return
    }

    $clean = [ordered]@{}
    foreach ($key in $keysToKeep) {
        $clean[$key] = $obj.$key
    }

    if ($clean.Count -eq 0) {
        Remove-Item $obsoletePath -Force
    } else {
        $clean | ConvertTo-Json -Compress | Set-Content $obsoletePath
    }
}

function Remove-ExtensionEntriesFromRegistry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath,
        [Parameter(Mandatory = $true)]
        [string]$ExtensionId
    )

    $registryPath = Join-Path $RootPath "extensions.json"
    if (-not (Test-Path $registryPath)) {
        return
    }

    $raw = Get-Content -Raw $registryPath
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return
    }

    $entries = $raw | ConvertFrom-Json
    if ($null -eq $entries) {
        return
    }

    $list = @($entries)
    $filtered = @()
    foreach ($entry in $list) {
        if ($null -eq $entry.identifier -or $entry.identifier.id -ne $ExtensionId) {
            $filtered += $entry
        }
    }

    if ($filtered.Count -eq $list.Count) {
        return
    }

    if ($filtered.Count -eq 0) {
        "[]" | Set-Content $registryPath
    } else {
        $filtered | ConvertTo-Json -Depth 32 -Compress | Set-Content $registryPath
    }
}

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

Remove-ExtensionEntriesFromObsolete -RootPath $extensionsRoot -ExtensionId $extId
Remove-ExtensionEntriesFromRegistry -RootPath $extensionsRoot -ExtensionId $extId

if ($CleanupGlobal) {
    $globalExtensionsRoot = Join-Path $env:USERPROFILE ".vscode\extensions"
    if (Test-Path $globalExtensionsRoot) {
        Get-ChildItem $globalExtensionsRoot -Directory -Filter "$extId-*" -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force
        Remove-ExtensionEntriesFromObsolete -RootPath $globalExtensionsRoot -ExtensionId $extId
        Remove-ExtensionEntriesFromRegistry -RootPath $globalExtensionsRoot -ExtensionId $extId
    }
}

Write-Host "formo extension synced to: $targetDir"
