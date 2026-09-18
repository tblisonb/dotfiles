#
# PowerShell profile - Windows counterpart to bash/.bash_aliases. Dot-sourced
# from Microsoft.PowerShell_profile.ps1, kept separate for the same reason
# .bash_aliases is split out from .bashrc: so it can be reused as-is.
#
# Differences from the bash version, and why:
#  - cp/mv/rm use -Confirm on every call, not just on overwrite like bash's
#    `-i` (PowerShell's -Confirm has no "only prompt if destination exists"
#    mode) - errs on the safe side rather than trying to fake bash's exact,
#    narrower behavior.
#  - `sudo` isn't wrapped: this machine already has Windows' own built-in
#    sudo.exe, which has no timestamp-cache-refresh concept the way
#    `alias sudo='sudo -v; sudo '` works around in bash, so there's nothing
#    to port.
#  - `more='less'` is skipped: no `less` on Windows; the built-in `more`
#    pager stays as-is.
#  - bash's bare `-` for `cd -` isn't ported: PowerShell's parser reads a
#    bare `-` as the unary minus operator, not a command name, so a function
#    literally named `-` can't be defined. zoxide's `cd` (wired up earlier in
#    the profile) already supports `cd -` as two tokens, which is as close
#    as PowerShell allows.
#  - `up`, `extract`, `weather`, `myip` are reimplemented against what's
#    actually on this machine (choco, tar.exe/7z.exe, curl.exe) rather than a
#    literal line-for-line port, since the bash versions are themselves
#    distro/tool-specific.
#
# NOT verified interactively on real Windows hardware - written and syntax-
# checked, but not exercised in a live PowerShell console. Sanity-check after
# install.ps1 picks this up (see its dot-source of the profile).

# --- Modern tool replacements ------------------------------------------------
# ls/cat/cp/mv/rm each carry a builtin ReadOnly+AllScope alias in PowerShell
# that outranks a same-named function in command resolution, so the alias is
# removed first. grep/find/vi/vim have no such builtin alias to fight.

Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue
Remove-Item Alias:cp -Force -ErrorAction SilentlyContinue
Remove-Item Alias:mv -Force -ErrorAction SilentlyContinue
Remove-Item Alias:rm -Force -ErrorAction SilentlyContinue

function ls { eza --color=auto @args }
function ll { ls -l @args }
function la { ls -la @args }
function cat { bat @args }
function grep { rg @args }
function find { fd @args }
function vi { nvim @args }
function vim { nvim @args }

# Safety nets. -Confirm prompts on every call, not just on overwrite - see
# the header note on why this doesn't match bash's `-i` exactly.
function cp { Copy-Item @args -Confirm }
function mv { Move-Item @args -Confirm }
function rm { Remove-Item @args -Confirm }

# --- Navigation --------------------------------------------------------------
# These call `cd`, not Set-Location directly, so zoxide (which wraps `cd`
# earlier in the profile) still sees and learns from these jumps.
function .. { cd .. }
function ... { cd ..\.. }
function .... { cd ..\..\.. }

# --- Package-manager-aware system update (bash's `up`, distro-branched) -----
function up {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        choco upgrade all -y
    } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
        winget upgrade --all --accept-package-agreements --accept-source-agreements
    } else {
        Write-Warning "up: neither choco nor winget found on PATH, upgrade manually"
    }
}

# Extract almost any archive type: extract archive.tar.gz
# tar.exe (bsdtar, ships with Windows) auto-detects compression from the
# file itself, so a bare `xf` covers every tar.* variant; 7z.exe covers the
# single-file compressed formats tar doesn't handle.
function extract {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path -PathType Leaf)) {
        Write-Error "extract: '$Path' is not a valid file"
        return
    }

    switch -Regex ($Path) {
        '\.(tar\.bz2|tar\.gz|tar\.xz|tbz2|tgz|tar)$' { tar xf $Path; break }
        '\.(zip|rar|7z|gz|bz2)$'                     { 7z x $Path; break }
        default { Write-Error "extract: don't know how to extract '$Path'" }
    }
}

# Copy a file to file.bak before editing it: backup file.txt
function backup {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) {
        Write-Error "backup: '$Path' is not a valid file"
        return
    }
    Copy-Item $Path "$Path.bak" -Confirm
}

# Quick weather / public IP lookups. Explicitly curl.exe, not the `curl`
# alias PowerShell points at Invoke-WebRequest by default, so the bash-style
# flags and plain-text output actually work.
function weather {
    param([string]$Location = "")
    curl.exe -s "wttr.in/$Location"
}

function myip {
    curl.exe -s "ifconfig.me"
    Write-Host ""
}
