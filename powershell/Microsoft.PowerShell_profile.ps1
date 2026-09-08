#
# PowerShell profile - Windows counterpart to bash/.bashrc + bash/.flyline.sh.
#
# Not a 1:1 port: flyline is a bash-only readline replacement, so the
# equivalent functionality here is built on PSReadLine (ships with
# PowerShell) plus Oh My Posh for the prompt. install.ps1 makes the real
# $PROFILE dot-source this file, so $PSScriptRoot below correctly resolves
# to this file's own directory (the repo's powershell/ folder) regardless
# of where $PROFILE itself lives.
#
# NOTE on what's actually been verified: the Tab handler (accept an inline
# suggestion, else fall back to native completion) and the Space-leader
# empty-buffer gate were exercised against real PSReadLine 2.4.5 in a pty
# harness on Linux pwsh, and work as written - that pass is also what
# killed the original Ctrl+D/Ctrl+U rebind below (it broke normal
# line-editing, see the comment on it). Still NOT verified anywhere: the
# oh-my-posh/zoxide/fzf integration (none of those are installed in the
# environment this was written in) or anything Windows-specific (real
# winget-installed binaries, actual paths, Windows Terminal rendering).
# Sanity-check those once this is actually installed on Windows.

# --- Editor / environment -----------------------------------------------

$env:EDITOR = "nvim"

# ripgrep: point at the same .ripgreprc tracked in the repo (ripgrep/.ripgreprc)
# rather than copying it - no symlink/junction needed for a single file read
# via an env var, it's simpler to just point RIPGREP_CONFIG_PATH straight at
# the repo-tracked copy.
$env:RIPGREP_CONFIG_PATH = Join-Path (Split-Path $PSScriptRoot -Parent) "ripgrep\.ripgreprc"

# --- Prompt (Oh My Posh) --------------------------------------------------
# RPS1/PROMPT_RULER equivalent: theme file lives next to this profile.
# See its header comment for the ruler-line caveat (the "filler" property
# is used to draw the dashed separator + right-aligned timestamp, and
# wasn't visually verified before being written).

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$PSScriptRoot\oh-my-posh-theme.json" | Invoke-Expression
}

# --- zoxide: smarter cd that learns your frequent directories ------------

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}

# --- PSReadLine: tab-completion / suggestions -----------------------------

if (Get-Module -ListAvailable -Name PSReadLine) {
    # Inline history suggestion (flyline's inline suggestion), shown as
    # ghost text after the cursor. Accepted by RightArrow/End by default
    # (PSReadLine's ForwardChar already calls AcceptSuggestion at end of
    # line) - Tab is rebound below to also accept it.
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -HistoryNoDuplicates
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd

    # Fuzzy-ish history search: PSReadLine's HistorySearchBackward/Forward
    # already match on whatever's typed so far (not full fuzzy matching
    # like flyline's Ctrl+R, but the closest built-in equivalent) - bind
    # to Ctrl+r/Ctrl+s to mirror the bash muscle memory.
    Set-PSReadLineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
    Set-PSReadLineKeyHandler -Key Ctrl+s -Function ForwardSearchHistory

    # Tab: prefer accepting the inline history suggestion (same job as
    # flyline's "Tab autocompletes from history first"); otherwise fall
    # through to PowerShell's native tab-completion cycling.
    Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
        param($key, $arg)

        $lineBefore = $null; $cursorBefore = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$lineBefore, [ref]$cursorBefore)

        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptSuggestion($key, $arg)

        $lineAfter = $null; $cursorAfter = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$lineAfter, [ref]$cursorAfter)

        if ($lineAfter -eq $lineBefore) {
            # No inline suggestion was accepted - fall back to normal tab completion.
            [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext($key, $arg)
        }
    }

    # Cycling forward/backward through tab-completion candidates (flyline's
    # tabCompletionNextSuggestion/tabCompletionPrevSuggestion) is NOT
    # rebound onto Ctrl+D/Ctrl+U here, unlike the bash/flyline version.
    # Tried that first and it broke on verification: PSReadLine has no
    # "only while a completion cycle is active" context the way flyline
    # does, so Ctrl+D/Ctrl+U would unconditionally stop deleting a
    # char/killing to line-start - a real regression, not just a cosmetic
    # difference. PSReadLine already binds Tab/Shift+Tab to
    # TabCompleteNext/TabCompletePrevious by default, so forward/backward
    # cycling works out of the box without touching Ctrl+D/Ctrl+U at all.
}

# --- fzf / ripgrep integration, with a Space-as-leader mirroring your ----
# --- Neovim <leader>ff / <leader>gg muscle memory ------------------------

if ((Get-Command fzf -ErrorAction SilentlyContinue) -and (Get-Module -ListAvailable -Name PSReadLine)) {

    # Find a file under the CWD (via fd) and drop `nvim -- <file>` into the
    # command line - mirrors flyline_fzf_find_files from bash/.flyline.sh.
    function Invoke-FzfFindFile {
        $file = fd --type f --hidden --exclude .git . 2>$null | fzf --preview "bat --style=numbers --color=always {}"
        if (-not $file) { return }
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$env:EDITOR -- `"$file`"")
    }

    # Live ripgrep search under the CWD, drops `nvim +<line> -- <file>`
    # into the command line - mirrors flyline_fzf_live_grep from bash.
    function Invoke-FzfLiveGrep {
        $result = rg --line-number --no-heading --color=always . 2>$null | fzf --ansi --delimiter ":" `
            --preview "bat --style=numbers --color=always --highlight-line {2} {1}" `
            --preview-window "+{2}-/2" `
            --bind "change:reload:rg --line-number --no-heading --color=always {q} 2>nul || exit 0" `
            --disabled
        if (-not $result) { return }
        $parts = $result -split ":", 3
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$env:EDITOR +$($parts[1]) -- `"$($parts[0])`"")
    }

    # Space only acts as the leader when the buffer is empty (mirrors
    # flyline's bufferIsEmpty gate) - otherwise it's just a normal space,
    # same feel as Neovim's spacebar leader not colliding with typing one.
    $script:PwshLeaderActive = $false

    Set-PSReadLineKeyHandler -Key Spacebar -ScriptBlock {
        param($key, $arg)
        $line = $null; $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ([string]::IsNullOrEmpty($line)) {
            $script:PwshLeaderActive = $true
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::SelfInsert($key, $arg)
        }
    }

    # leader+f / leader+g rather than a literal double-tap, same caveat as
    # the bash version: there's no way to distinguish a 2nd f/g press from
    # a 1st from leader state alone.
    Set-PSReadLineKeyHandler -Key f -ScriptBlock {
        param($key, $arg)
        if ($script:PwshLeaderActive) {
            $script:PwshLeaderActive = $false
            Invoke-FzfFindFile
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::SelfInsert($key, $arg)
        }
    }

    Set-PSReadLineKeyHandler -Key g -ScriptBlock {
        param($key, $arg)
        if ($script:PwshLeaderActive) {
            $script:PwshLeaderActive = $false
            Invoke-FzfLiveGrep
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::SelfInsert($key, $arg)
        }
    }
}
