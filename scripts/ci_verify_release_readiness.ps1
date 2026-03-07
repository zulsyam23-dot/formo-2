$ErrorActionPreference = "Stop"

$requiredFiles = @(
    "CHANGELOG.md",
    "docs/RELEASE_CHECKLIST.md",
    "docs/IR_MIGRATIONS.md",
    "docs/IR_COMPATIBILITY.md"
)

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        throw "missing required release document: $file"
    }
}

$changelog = Get-Content -Raw "CHANGELOG.md"
if ($changelog -notmatch "## \[Unreleased\]") {
    throw "CHANGELOG.md must contain '## [Unreleased]'"
}
if ($changelog -notmatch "## \[[0-9]+\.[0-9]+\.[0-9]+\] - [0-9]{4}-[0-9]{2}-[0-9]{2}") {
    throw "CHANGELOG.md must contain at least one released version heading"
}

$releaseChecklist = Get-Content -Raw "docs/RELEASE_CHECKLIST.md"
if ($releaseChecklist -notmatch "Semver Tag") {
    throw "release checklist must contain 'Semver Tag' section"
}
if ($releaseChecklist -notmatch "Changelog") {
    throw "release checklist must contain 'Changelog' section"
}
if ($releaseChecklist -notmatch "Migration Notes") {
    throw "release checklist must contain 'Migration Notes' section"
}

if ($env:RELEASE_TAG) {
    if ($env:RELEASE_TAG -notmatch "^v[0-9]+\.[0-9]+\.[0-9]+$") {
        throw "RELEASE_TAG must follow format vX.Y.Z (got: $env:RELEASE_TAG)"
    }
}

Write-Host "release-readiness docs check passed."
