#
# migrate-choco-to-winget.ps1 - interactive helper to move installed
# Chocolatey packages over to winget, one at a time.
#
# This is NOT run automatically by install.ps1 and does not blindly rename
# packages - Chocolatey and winget package IDs don't map 1:1 (e.g. choco's
# "ripgrep" is winget's "BurntSushi.ripgrep.MSVC"), so guessing wrong and
# silently installing/uninstalling things is worse than doing nothing. For
# every installed choco package this looks up candidate winget matches via
# the real winget package search, shows them to you, and asks per package:
#   - which match (if any) to install via winget
#   - whether to then uninstall the Chocolatey copy
# Nothing is installed or removed without an explicit answer.
#
# Run it directly: .\powershell\migrate-choco-to-winget.ps1
# Or preview matches without being prompted to act on them: -ListOnly
#
# NOTE: this hasn't been run against a real choco/winget install - there's
# neither on the Linux machine this was written on. The choco output
# parsing and the Find-WinGetPackage/Install-WinGetPackage/Get-WinGetPackage
# calls are written against their documented behavior but not exercised
# end-to-end. Try -ListOnly first to sanity check the matches it finds
# before letting it install/uninstall anything.

param(
    [switch]$ListOnly
)

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "choco not found on PATH - nothing to migrate." -ForegroundColor Yellow
    return
}

if (-not (Get-Module -ListAvailable -Name Microsoft.WinGet.Client)) {
    Write-Host "Installing Microsoft.WinGet.Client (one-time, provides Find/Install/Get-WinGetPackage)..." -ForegroundColor Cyan
    Install-Module -Name Microsoft.WinGet.Client -Scope CurrentUser -Force -Repository PSGallery
}
Import-Module Microsoft.WinGet.Client

# `choco list` stopped taking --local-only in Chocolatey CLI v2 (it lists
# local packages by default there, and warns/fails if you still pass it) -
# branch on major version so this works against either.
$chocoMajor = 1
$versionOutput = choco --version
if ($versionOutput -match '^\d+') {
    $chocoMajor = [int]($versionOutput -split '\.')[0]
}

$rawList = if ($chocoMajor -ge 2) {
    choco list --limit-output
} else {
    choco list --local-only --limit-output
}

# Chocolatey's own bookkeeping package, not something to migrate.
$SkipNames = @("chocolatey")

$packages = $rawList |
    Where-Object { $_ -match '\|' } |
    ForEach-Object {
        $parts = $_ -split '\|'
        [pscustomobject]@{ Name = $parts[0]; Version = $parts[1] }
    } |
    Where-Object { $SkipNames -notcontains $_.Name }

Write-Host "Found $($packages.Count) installed Chocolatey package(s) (excluding chocolatey itself)." -ForegroundColor Cyan

$results = @()

foreach ($pkg in $packages) {
    Write-Host ""
    Write-Host "=== $($pkg.Name) ($($pkg.Version)) ===" -ForegroundColor Cyan

    $candidates = @(Find-WinGetPackage $pkg.Name -ErrorAction SilentlyContinue | Select-Object -First 5)

    if ($candidates.Count -eq 0) {
        Write-Host "  no winget matches found." -ForegroundColor Yellow
        $results += [pscustomobject]@{ Choco = $pkg.Name; Winget = $null; Action = "no-match" }
        continue
    }

    for ($i = 0; $i -lt $candidates.Count; $i++) {
        Write-Host "  [$i] $($candidates[$i].Name)  ($($candidates[$i].Id))  $($candidates[$i].Version)"
    }

    if ($ListOnly) { continue }

    $choice = Read-Host "  Pick a match number to install via winget, 'c' for a custom Id, or Enter to skip"

    $wingetId = $null
    if ($choice -eq "c") {
        $wingetId = Read-Host "  Enter the winget package Id"
    } elseif ($choice -match '^\d+$' -and [int]$choice -lt $candidates.Count) {
        $wingetId = $candidates[[int]$choice].Id
    }

    if (-not $wingetId) {
        Write-Host "  skipped." -ForegroundColor Yellow
        $results += [pscustomobject]@{ Choco = $pkg.Name; Winget = $null; Action = "skipped" }
        continue
    }

    if (Get-WinGetPackage -Id $wingetId -ErrorAction SilentlyContinue) {
        Write-Host "  $wingetId already installed via winget." -ForegroundColor Green
    } else {
        Write-Host "  installing $wingetId via winget..." -ForegroundColor Cyan
        Install-WinGetPackage -Id $wingetId
    }

    $action = "installed-winget-only"
    $removeChoco = Read-Host "  Uninstall the Chocolatey copy of $($pkg.Name) now? [y/N]"
    if ($removeChoco -eq "y") {
        choco uninstall $pkg.Name -y
        $action = "migrated"
    }

    $results += [pscustomobject]@{ Choco = $pkg.Name; Winget = $wingetId; Action = $action }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize
