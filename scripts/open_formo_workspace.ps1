$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$autoSupportScript = Join-Path $PSScriptRoot "auto_enable_formo_editor_support.ps1"
$extDir = Join-Path $repoRoot ".vscode\.extensions"
$workspaceFile = Join-Path $repoRoot "formo2.code-workspace"

if (Test-Path $autoSupportScript) {
    & powershell -ExecutionPolicy Bypass -File $autoSupportScript
}

Write-Host "opening VS Code with local extensions dir: $extDir"
& code --extensions-dir $extDir $workspaceFile
