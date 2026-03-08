$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$autoSupportScript = Join-Path $PSScriptRoot "auto_enable_formo_editor_support.ps1"
$pathHelper = Join-Path $PSScriptRoot "formo_repo_paths.ps1"
$extDir = Join-Path $repoRoot ".vscode\.extensions"
$workspaceFile = Join-Path $repoRoot "formo2.code-workspace"
$workspaceToOpen = $workspaceFile

if (Test-Path $autoSupportScript) {
    & powershell -ExecutionPolicy Bypass -File $autoSupportScript
}

if (Test-Path $pathHelper) {
    . $pathHelper
    $resolution = Resolve-FormoLibrary -RepoRoot $repoRoot -AutoInstall -Quiet
    if ($resolution) {
        $manifestPath = $resolution.ManifestPath
        $generatedWorkspace = Join-Path $repoRoot "target\formo2.generated.code-workspace"
        New-Item -Path (Split-Path -Parent $generatedWorkspace) -ItemType Directory -Force | Out-Null

        $workspaceJson = Get-Content -Raw $workspaceFile | ConvertFrom-Json
        if (-not $workspaceJson.settings) {
            $workspaceJson | Add-Member -NotePropertyName settings -NotePropertyValue ([pscustomobject]@{})
        }
        $workspaceJson.settings."rust-analyzer.linkedProjects" = @($manifestPath)
        $workspaceJson.settings."rust-analyzer.check.overrideCommand" = @(
            "cargo",
            "check",
            "--workspace",
            "--message-format=json",
            "--all-targets",
            "--manifest-path",
            $manifestPath
        )
        $workspaceJson | ConvertTo-Json -Depth 32 | Set-Content -Path $generatedWorkspace -Encoding UTF8
        $workspaceToOpen = $generatedWorkspace
        Write-Host "workspace manifest resolved: $manifestPath"
        Write-Host "workspace library source: $($resolution.Source)"
    } else {
        Write-Warning "library manifest not found; opening default workspace."
    }
}

Write-Host "opening VS Code with local extensions dir: $extDir"
& code --extensions-dir $extDir $workspaceToOpen
