$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$bootstrapScript = Join-Path $PSScriptRoot "formo2_bootstrap.ps1"
$extDir = Join-Path $repoRoot ".vscode\.extensions"
$workspaceFile = Join-Path $repoRoot "formo2.code-workspace"

& powershell -ExecutionPolicy Bypass -File $bootstrapScript

Write-Host "opening VS Code with local extensions dir: $extDir"
& code --extensions-dir $extDir $workspaceFile
