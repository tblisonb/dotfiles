#
# install.ps1 - bootstrap this dotfiles repo onto a Windows/PowerShell machine.
#
# Windows counterpart to install.sh. Not a 1:1 port - see powershell/ for
# what's actually implemented and its "not tested interactively" caveats.
#
# Run this from inside a clone of the repo (e.g. `.\install.ps1`); it
# operates on whatever directory it lives in.
#
# What it does:
#   1. Points your real $PROFILE at powershell/Microsoft.PowerShell_profile.ps1
#      (via a dot-source line, not a symlink - see the note in Set-ProfileLink
#      below for why).
#   2. Links the nvim config directory into place via an NTFS junction
#      (junctions, unlike symlinks, don't require admin rights or Developer
#      Mode - deliberately used here so this also works on a locked-down
#      machine without admin).
#   3. Best-effort installs required packages via winget, skipping anything
#      already on PATH (so e.g. an fzf you already have via Chocolatey is
#      left alone rather than getting a second winget-managed copy).
#
# Safe to re-run: skips anything already linked/installed.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$RepoDir = $PSScriptRoot

function Write-Msg  { param($Text) Write-Host "==> $Text" -ForegroundColor Green }
function Write-Warn { param($Text) Write-Host "!! $Text" -ForegroundColor Yellow }

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warn "running under PowerShell $($PSVersionTable.PSVersion) - the profile/theme in powershell/ were written against PowerShell 7+ (pwsh); consider switching."
}

# --- 1. Point $PROFILE at the repo's profile script --------------------------

function Set-ProfileLink {
    # A real symlink for $PROFILE would need admin rights or Developer Mode
    # enabled - neither guaranteed on every machine this might run on - so
    # instead this appends a one-line dot-source into the real $PROFILE,
    # which works unprivileged everywhere and is just as effective, since
    # $PROFILE is itself just a PowerShell script that gets executed.
    $repoProfile = Join-Path $RepoDir "powershell\Microsoft.PowerShell_profile.ps1"
    $dotSourceLine = ". `"$repoProfile`""

    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType Directory -Force -Path (Split-Path $PROFILE) | Out-Null
        New-Item -ItemType File -Path $PROFILE | Out-Null
    }

    $existing = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($existing -and $existing.Contains($repoProfile)) {
        Write-Msg "already wired up: $PROFILE dot-sources $repoProfile"
        return
    }

    Add-Content -Path $PROFILE -Value "`n# Industrial dotfiles - do not edit below, edit the repo instead`n$dotSourceLine`n"
    Write-Msg "added dot-source of $repoProfile to $PROFILE"
}

function Set-JunctionLink {
    # Set-JunctionLink <source-dir-in-repo> <target-dir>
    param([string]$Source, [string]$Dest)

    if (-not (Test-Path $Source)) {
        Write-Warn "source '$Source' not found in repo, skipping"
        return
    }

    $resolvedSource = (Resolve-Path $Source).Path

    if (Test-Path $Dest) {
        $item = Get-Item $Dest -Force
        if ($item.LinkType -eq "Junction" -and $item.Target -eq $resolvedSource) {
            Write-Msg "already linked: $Dest"
            return
        }
        $backup = "$Dest.bak-$(Get-Date -Format yyyyMMddHHmmss)"
        Write-Warn "moving existing $Dest -> $backup"
        Move-Item -Path $Dest -Destination $backup
    } else {
        New-Item -ItemType Directory -Force -Path (Split-Path $Dest) | Out-Null
    }

    New-Item -ItemType Junction -Path $Dest -Target $resolvedSource | Out-Null
    Write-Msg "junctioned $Dest -> $resolvedSource"
}

Set-ProfileLink
Set-JunctionLink (Join-Path $RepoDir "nvim") (Join-Path $env:LOCALAPPDATA "nvim")

# --- 2. Install packages via Chocolatey (falling back to winget) -------------

# command-on-PATH -> package ID, one map per manager (IDs differ between the
# two). Chocolatey is tried first since that's this repo's actual in-use
# package manager (fzf/ripgrep/neovim here all came in via choco); winget is
# only a fallback for a machine that has it but not choco. Either way the
# command name is checked first so a package already installed by any means
# (the other manager, scoop, a manual install) is left alone instead of
# getting a second manager-owned copy.
$ChocoPackages = @{
    "eza"        = "eza"
    "bat"        = "bat"
    "fd"         = "fd"
    "rg"         = "ripgrep"
    "zoxide"     = "zoxide"
    "fzf"        = "fzf"
    "oh-my-posh" = "oh-my-posh"
    "nvim"       = "neovim"
}
$WingetPackages = @{
    "eza"        = "eza-community.eza"
    "bat"        = "sharkdp.bat"
    "fd"         = "sharkdp.fd"
    "rg"         = "BurntSushi.ripgrep.MSVC"
    "zoxide"     = "ajeetdsouza.zoxide"
    "fzf"        = "junegunn.fzf"
    "oh-my-posh" = "JanDeDobbeleer.OhMyPosh"
    "nvim"       = "Neovim.Neovim"
}

function Install-Packages {
    $useChoco = [bool](Get-Command choco -ErrorAction SilentlyContinue)
    $useWinget = [bool](Get-Command winget -ErrorAction SilentlyContinue)

    if (-not $useChoco -and -not $useWinget) {
        Write-Warn "neither choco nor winget found - install eza/bat/fd/ripgrep/zoxide/fzf/oh-my-posh/neovim manually"
        return
    }

    $packages = if ($useChoco) { $ChocoPackages } else { $WingetPackages }
    $managerName = if ($useChoco) { "choco" } else { "winget" }

    foreach ($cmd in $packages.Keys) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
            Write-Msg "$cmd already on PATH, skipping"
            continue
        }

        $id = $packages[$cmd]
        Write-Msg "installing $id via $managerName"
        if ($useChoco) {
            choco install $id -y
        } else {
            winget install --id $id --exact --source winget `
                --accept-package-agreements --accept-source-agreements
        }
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "$managerName install of $id failed (exit $LASTEXITCODE), check output above"
        }
    }
}

Install-Packages

# PSReadLine ships with PowerShell 7+ by default - only reinstall if it's
# somehow missing or too old for -PredictionViewStyle ListView (2.2+).
$psrl = Get-Module -ListAvailable -Name PSReadLine | Sort-Object Version -Descending | Select-Object -First 1
if (-not $psrl -or $psrl.Version -lt [version]"2.2.0") {
    Write-Msg "installing/updating PSReadLine"
    Install-Module -Name PSReadLine -Scope CurrentUser -Force -AllowClobber -MinimumVersion 2.2.0
}

Write-Msg "done. Start a new pwsh session (or '. `$PROFILE') to pick everything up."
