function Add-ManifestCandidate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CandidatePath,
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [hashtable]$Seen,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.ArrayList]$Bucket
    )

    $fullPath = [System.IO.Path]::GetFullPath($CandidatePath)
    $key = $fullPath.ToLowerInvariant()
    if ($Seen.ContainsKey($key)) {
        return
    }

    $Seen[$key] = $true
    [void]$Bucket.Add([pscustomobject]@{
        ManifestPath = $fullPath
        Source = $Source
    })
}

function Test-FormoLibraryManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    if (-not (Test-Path $ManifestPath -PathType Leaf)) {
        return $false
    }

    try {
        $raw = Get-Content -Raw $ManifestPath
    } catch {
        return $false
    }

    if ($raw -notmatch "(?m)^\[workspace\]") {
        return $false
    }
    if ($raw -notmatch "tooling/programs/formo-cli") {
        return $false
    }

    return $true
}

function Test-TrustedFormoLibraryZipUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    $allowUntrusted = $env:FORMO_LIBRARY_ALLOW_UNTRUSTED_URL -eq "1"
    if ($allowUntrusted) {
        return $true
    }

    try {
        $uri = [Uri]$Url
    } catch {
        return $false
    }

    if ($uri.Scheme -ne "https") {
        return $false
    }

    $trustedHosts = @("github.com", "codeload.github.com")
    return $trustedHosts -contains $uri.Host.ToLowerInvariant()
}

function Install-FormoLibraryFromZip {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [switch]$Quiet
    )

    $managedBase = Join-Path $RepoRoot ".formo"
    $managedRoot = Join-Path $managedBase "formo-library-ecosystem"
    $managedManifest = Join-Path $managedRoot "Cargo.toml"
    if (Test-FormoLibraryManifest -ManifestPath $managedManifest) {
        return [pscustomobject]@{
            LibraryRoot = $managedRoot
            ManifestPath = $managedManifest
            Source = "managed-cache"
            AutoInstalled = $false
            ZipSha256 = $null
        }
    }

    $zipUrl = $env:FORMO_LIBRARY_ZIP_URL
    if ([string]::IsNullOrWhiteSpace($zipUrl)) {
        $zipUrl = "https://codeload.github.com/zulsyam23-dot/formo-library-ecosystem/zip/refs/heads/main"
    }
    if (-not (Test-TrustedFormoLibraryZipUrl -Url $zipUrl)) {
        throw "untrusted FORMO_LIBRARY_ZIP_URL host. use https://github.com or https://codeload.github.com, or set FORMO_LIBRARY_ALLOW_UNTRUSTED_URL=1."
    }

    New-Item -Path $managedBase -ItemType Directory -Force | Out-Null

    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("formo-lib-" + [Guid]::NewGuid().ToString("N"))
    New-Item -Path $tempRoot -ItemType Directory -Force | Out-Null
    $zipPath = Join-Path $tempRoot "formo-library-ecosystem.zip"
    $zipSha256 = $null

    try {
        if (-not $Quiet) {
            Write-Host "downloading formo library snapshot to: $managedRoot"
        }

        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
        $zipSha256 = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()

        $expectedSha256 = "$($env:FORMO_LIBRARY_ZIP_SHA256)".Trim().ToLowerInvariant()
        if (-not [string]::IsNullOrWhiteSpace($expectedSha256) -and $expectedSha256 -ne $zipSha256) {
            throw "FORMO_LIBRARY_ZIP_SHA256 mismatch. expected=$expectedSha256 actual=$zipSha256"
        }

        Expand-Archive -Path $zipPath -DestinationPath $tempRoot -Force

        $expandedRoot = Get-ChildItem -Path $tempRoot -Directory |
            Where-Object { $_.Name -like "formo-library-ecosystem*" } |
            Select-Object -First 1
        if ($null -eq $expandedRoot) {
            throw "unable to locate extracted formo-library-ecosystem folder"
        }

        if (Test-Path $managedRoot) {
            Remove-Item -Path $managedRoot -Recurse -Force
        }

        Move-Item -Path $expandedRoot.FullName -Destination $managedRoot
        if (-not (Test-FormoLibraryManifest -ManifestPath $managedManifest)) {
            throw "downloaded library does not contain expected Formo workspace manifest"
        }

        $metaPath = Join-Path $managedBase "library-source.json"
        $meta = [ordered]@{
            source = "auto-download"
            zipUrl = $zipUrl
            zipSha256 = $zipSha256
            downloadedAtUtc = [DateTime]::UtcNow.ToString("o")
        }
        $meta | ConvertTo-Json -Depth 5 | Set-Content -Path $metaPath -Encoding UTF8

        return [pscustomobject]@{
            LibraryRoot = $managedRoot
            ManifestPath = $managedManifest
            Source = "auto-download"
            AutoInstalled = $true
            ZipSha256 = $zipSha256
        }
    } catch {
        if (-not $Quiet) {
            Write-Warning "auto-download formo library failed: $($_.Exception.Message)"
        }
        return $null
    } finally {
        if (Test-Path $tempRoot) {
            Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Resolve-FormoLibrary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [switch]$AutoInstall,
        [switch]$Quiet
    )

    $repoRootAbs = [System.IO.Path]::GetFullPath($RepoRoot)

    $seen = @{}
    $candidates = New-Object System.Collections.ArrayList

    if (-not [string]::IsNullOrWhiteSpace($env:FORMO_LIBRARY_MANIFEST)) {
        Add-ManifestCandidate -CandidatePath $env:FORMO_LIBRARY_MANIFEST -Source "env-manifest" -Seen $seen -Bucket $candidates
    }
    if (-not [string]::IsNullOrWhiteSpace($env:FORMO_LIBRARY_ROOT)) {
        Add-ManifestCandidate -CandidatePath (Join-Path $env:FORMO_LIBRARY_ROOT "Cargo.toml") -Source "env-root" -Seen $seen -Bucket $candidates
    }

    $defaultRoots = @(
        (Join-Path $repoRootAbs "..\formo-library-ecosystem"),
        (Join-Path $repoRootAbs "formo-library-ecosystem"),
        (Join-Path $repoRootAbs ".formo\formo-library-ecosystem")
    )
    foreach ($root in $defaultRoots) {
        Add-ManifestCandidate -CandidatePath (Join-Path $root "Cargo.toml") -Source "default-root" -Seen $seen -Bucket $candidates
    }

    $scanBases = @(
        $repoRootAbs,
        (Split-Path -Parent $repoRootAbs)
    )
    foreach ($base in $scanBases) {
        if (-not (Test-Path $base)) {
            continue
        }
        Get-ChildItem -Path $base -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "formo-library-ecosystem*" } |
            ForEach-Object {
                Add-ManifestCandidate -CandidatePath (Join-Path $_.FullName "Cargo.toml") -Source "scan-nearby" -Seen $seen -Bucket $candidates
            }
    }

    foreach ($candidate in $candidates) {
        if (Test-FormoLibraryManifest -ManifestPath $candidate.ManifestPath) {
            $resolvedManifest = (Resolve-Path $candidate.ManifestPath).Path
            return [pscustomobject]@{
                ManifestPath = $resolvedManifest
                LibraryRoot = Split-Path -Parent $resolvedManifest
                Source = $candidate.Source
                AutoInstalled = $false
                ZipSha256 = $null
            }
        }
    }

    if ($AutoInstall) {
        $installed = Install-FormoLibraryFromZip -RepoRoot $repoRootAbs -Quiet:$Quiet
        if ($installed) {
            return [pscustomobject]@{
                ManifestPath = (Resolve-Path $installed.ManifestPath).Path
                LibraryRoot = (Resolve-Path $installed.LibraryRoot).Path
                Source = $installed.Source
                AutoInstalled = [bool]$installed.AutoInstalled
                ZipSha256 = $installed.ZipSha256
            }
        }
    }

    return $null
}

function Get-FormoLibraryManifestPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [switch]$AutoInstall,
        [switch]$Quiet
    )

    $resolved = Resolve-FormoLibrary -RepoRoot $RepoRoot -AutoInstall:$AutoInstall -Quiet:$Quiet
    if ($resolved) {
        return $resolved.ManifestPath
    }
    return $null
}
