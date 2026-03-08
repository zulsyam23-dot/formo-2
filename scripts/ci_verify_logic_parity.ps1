param(
    [string]$InputFm = "main.fm",
    [string]$LogicInput = "logic/controllers/app_controller.fl",
    [string]$OutDir = "dist-parity",
    [string]$RuntimeContractOut = "target/parity/fl-runtime-contract.json"
)

$ErrorActionPreference = "Stop"

function Resolve-RepoPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue,
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return $PathValue
    }

    return Join-Path $RepoRoot $PathValue
}

function Run-FormoCli {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Args
    )

    $cargoArgs = @(
        "run",
        "--manifest-path", $ManifestPath,
        "-p", "formo-cli",
        "--"
    ) + $Args

    Write-Host ">> cargo $($cargoArgs -join ' ')"
    & cargo @cargoArgs
    if ($LASTEXITCODE -ne 0) {
        throw "command failed: cargo $($cargoArgs -join ' ')"
    }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Resolve-RepoPath -PathValue "..\formo-library-ecosystem\Cargo.toml" -RepoRoot $repoRoot
$localCargoTarget = Resolve-RepoPath -PathValue "target/cargo-shared" -RepoRoot $repoRoot
$resolvedFm = Resolve-RepoPath -PathValue $InputFm -RepoRoot $repoRoot
$resolvedLogic = Resolve-RepoPath -PathValue $LogicInput -RepoRoot $repoRoot
$resolvedOutDir = Resolve-RepoPath -PathValue $OutDir -RepoRoot $repoRoot
$resolvedRuntimeContractOut = Resolve-RepoPath -PathValue $RuntimeContractOut -RepoRoot $repoRoot
$desktopOutDir = Join-Path $resolvedOutDir "desktop"
$webOutDir = Join-Path $resolvedOutDir "web"

if (-not (Test-Path $manifestPath)) {
    throw "library Cargo manifest not found: $manifestPath"
}
if (-not (Test-Path $resolvedFm)) {
    throw "fm input not found: $resolvedFm"
}
if (-not (Test-Path $resolvedLogic)) {
    throw "logic input not found: $resolvedLogic"
}

New-Item -Path $localCargoTarget -ItemType Directory -Force | Out-Null
$env:CARGO_TARGET_DIR = $localCargoTarget

New-Item -Path $resolvedOutDir -ItemType Directory -Force | Out-Null
New-Item -Path $desktopOutDir -ItemType Directory -Force | Out-Null
New-Item -Path $webOutDir -ItemType Directory -Force | Out-Null
New-Item -Path (Split-Path -Parent $resolvedRuntimeContractOut) -ItemType Directory -Force | Out-Null

Run-FormoCli -ManifestPath $manifestPath -Args @(
    "logic",
    "--input", $resolvedLogic,
    "--json-pretty",
    "--rt-manifest-out", $resolvedRuntimeContractOut
)

$manifestJson = Get-Content -Raw $resolvedRuntimeContractOut | ConvertFrom-Json
if (-not $manifestJson.ok) {
    throw "logic validation reported not-ok state"
}
if ($manifestJson.unitCount -eq 0) {
    throw "logic validation produced zero units"
}
if ($manifestJson.quality.parityReadyUnits -lt $manifestJson.unitCount) {
    throw "logic parity is not fully ready ($($manifestJson.quality.parityReadyUnits)/$($manifestJson.unitCount))"
}

Run-FormoCli -ManifestPath $manifestPath -Args @(
    "build",
    "--target", "desktop",
    "--input", $resolvedFm,
    "--out", $desktopOutDir,
    "--strict-parity"
)

Run-FormoCli -ManifestPath $manifestPath -Args @(
    "build",
    "--target", "web",
    "--input", $resolvedFm,
    "--out", $webOutDir
)

$expectedWeb = Join-Path $webOutDir "app.js"
$expectedDesktopNative = Join-Path $desktopOutDir "app.native.rs"
$expectedDesktopIr = Join-Path $desktopOutDir "app.ir.json"
if (-not (Test-Path $expectedDesktopNative)) {
    throw "missing desktop native output: $expectedDesktopNative"
}
if (-not (Test-Path $expectedDesktopIr)) {
    throw "missing desktop IR output: $expectedDesktopIr"
}
if (-not (Test-Path $expectedWeb)) {
    throw "missing web runtime output: $expectedWeb"
}

$reportPath = Resolve-RepoPath -PathValue "target/parity/parity-report.json" -RepoRoot $repoRoot
$report = [ordered]@{
    inputFm = $resolvedFm
    logicInput = $resolvedLogic
    runtimeContract = $resolvedRuntimeContractOut
    desktopBuildOut = $desktopOutDir
    webBuildOut = $webOutDir
    webOutput = $expectedWeb
    desktopNativeOutput = $expectedDesktopNative
    desktopIrOutput = $expectedDesktopIr
    parityScore = $manifestJson.quality.parityScore
    parityReadyUnits = $manifestJson.quality.parityReadyUnits
    unitCount = $manifestJson.unitCount
    generatedAtUtc = [DateTime]::UtcNow.ToString("o")
}
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $reportPath -Encoding UTF8

Write-Host "logic parity verification passed."
Write-Host "runtime contract: $resolvedRuntimeContractOut"
Write-Host "parity report: $reportPath"
