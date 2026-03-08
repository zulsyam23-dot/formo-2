$ErrorActionPreference = "Stop"
$ManifestPath = "..\formo-library-ecosystem\Cargo.toml"
$LocalCargoTarget = "target/cargo-shared"

New-Item -Path $LocalCargoTarget -ItemType Directory -Force | Out-Null
$env:CARGO_TARGET_DIR = (Resolve-Path $LocalCargoTarget).Path

function Run-Cargo {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Args
    )

    if ($Args.Count -eq 0) {
        throw "Run-Cargo requires at least one cargo subcommand"
    }

    $subcommand = $Args[0]
    $rest = @()
    if ($Args.Count -gt 1) {
        $rest = $Args[1..($Args.Count - 1)]
    }

    $finalArgs = @($subcommand, "--manifest-path", $ManifestPath) + $rest
    Write-Host ">> cargo $($finalArgs -join ' ')"
    & cargo @finalArgs
    if ($LASTEXITCODE -ne 0) {
        throw "command failed: cargo $($finalArgs -join ' ')"
    }
}

Run-Cargo @("check")

Run-Cargo @("run", "-p", "formo-cli", "--", "help")

Run-Cargo @("run", "-p", "formo-cli", "--", "check", "main.fm")
Run-Cargo @("run", "-p", "formo-cli", "--", "check", "--input", "main.fm", "--json")
Run-Cargo @("run", "-p", "formo-cli", "--", "check", "--input", "main.fm", "--json-pretty")
Run-Cargo @("run", "-p", "formo-cli", "--", "check", "--input", "main.fm", "--json-schema")

Run-Cargo @("run", "-p", "formo-cli", "--", "diagnose", "--input", "main.fm", "--json")
Run-Cargo @("run", "-p", "formo-cli", "--", "diagnose", "--input", "main.fm", "--json-schema")
Run-Cargo @("run", "-p", "formo-cli", "--", "diagnose", "--input", "main.fm", "--lsp")

Run-Cargo @("run", "-p", "formo-cli", "--", "lsp", "--input", "main.fm")

if (-not (Test-Path "main.fm")) {
    throw "main.fm is required for README example checks"
}

$backupDir = "target/formo-readme-ci"
New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
$mainBackup = Join-Path $backupDir "main.fm.bak"
Copy-Item "main.fm" $mainBackup -Force

Run-Cargo @("run", "-p", "formo-cli", "--", "fmt", "--input", "main.fm")
Run-Cargo @("run", "-p", "formo-cli", "--", "fmt", "--input", "main.fm", "--check")
Run-Cargo @("run", "-p", "formo-cli", "--", "fmt", "--input", "main.fm", "--stdout")

Copy-Item $mainBackup "main.fm" -Force

Run-Cargo @("run", "-p", "formo-cli", "--", "doctor", "--input", "main.fm", "--json")
Run-Cargo @("run", "-p", "formo-cli", "--", "doctor", "--input", "main.fm", "--json-schema")
Run-Cargo @("run", "-p", "formo-cli", "--", "logic", "--input", "logic/controllers/app_controller.fl", "--json-pretty", "--rt-manifest-out", "dist-ci/readme/fl-runtime-contract.json")

Run-Cargo @(
    "run",
    "-p",
    "formo-cli",
    "--",
    "bench",
    "--input",
    "main.fm",
    "--iterations",
    "6",
    "--warmup",
    "2",
    "--nodes",
    "1000",
    "--out",
    "dist-ci/readme/benchmark.json",
    "--json-pretty",
    "--max-compile-p95-ms",
    "120",
    "--max-first-render-p95-ms",
    "10"
)

Run-Cargo @("run", "-p", "formo-cli", "--", "build", "--target", "web", "--input", "main.fm", "--out", "dist-readme/web")
Run-Cargo @("run", "-p", "formo-cli", "--", "build", "--target", "desktop", "--input", "main.fm", "--out", "dist-readme/desktop")
Run-Cargo @("run", "-p", "formo-cli", "--", "build", "--target", "multi", "--input", "main.fm", "--out", "dist-readme/multi")
Run-Cargo @("run", "-p", "formo-cli", "--", "build", "--target", "desktop", "--input", "main.fm", "--out", "dist-readme/desktop-strict", "--strict-parity")
Run-Cargo @("run", "-p", "formo-cli", "--", "build", "--target", "web", "--input", "main.fm", "--out", "dist-readme/web-follow-desktop")
Run-Cargo @("run", "-p", "formo-cli", "--", "build", "--target", "web", "--input", "main.fm", "--out", "dist-readme/web-prod", "--prod")

Write-Host "README example commands completed successfully."
