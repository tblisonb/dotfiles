#
# ~/.flyline.sh
#
# Config for flyline (https://github.com/HalFrgrd/flyline), a readline
# replacement. Everything below is a no-op until flyline itself is
# installed and enabled - it isn't packaged by any distro yet, so install
# it yourself once per machine (not scripted here since it downloads and
# runs a script):
#
#   source <(curl -sSfL https://github.com/HalFrgrd/flyline/releases/latest/download/install.sh)
#
# That installer wires up `enable flyline` in your real ~/.bashrc for you.
# Sourced from .bashrc; everything here is gated on flyline actually being
# enabled, so it's safe to source unconditionally.

if command -v flyline >/dev/null 2>&1; then

    # --- Tab completion / suggestions ------------------------------------

    shopt -s extglob
    # Optional extras (change matching behavior shell-wide, so off by default):
    # shopt -s nocaseglob   # case-insensitive glob matching
    # shopt -s globstar     # recursive ** matching
    # shopt -s dotglob      # match hidden files with * and ?

    flyline suggestions set-fuzzy-mode all
    flyline suggestions --auto-suggest true
    # Fuzzy history search (Ctrl+R) and LS_COLORS-styled completions are on
    # by default, nothing to configure there.

    # By default Tab always cycles the tab-completion suggestion list (even
    # when a history-based inline suggestion is also showing), and the only
    # way to accept the inline suggestion is Right/End at the end of the
    # line. Re-split those: Tab prefers accepting the inline suggestion when
    # one's available; otherwise, while a suggestion list is open (with more
    # than one entry - a single entry still just completes on Tab), Tab does
    # nothing and Ctrl+D/Ctrl+U move down/up through the list instead (Enter
    # still accepts the highlighted entry, unchanged). Right/End still also
    # accepts the inline suggestion as before - this only adds Tab as another
    # way to do it.
    # NB: Ctrl+D/Ctrl+U keep their usual delete-char-right/kill-to-line-start
    # meaning everywhere else - these bindings only fire while a suggestion
    # list is actually open.
    flyline key bind Tab 'tabCompletionAvailable+!tabCompletionOneResult=nothing'
    flyline key bind Tab 'inlineSuggestionAvailable+cursorAtEnd=inlineSuggestionAccept'
    flyline key bind Ctrl+d tabCompletionAvailable=tabCompletionNextSuggestion
    flyline key bind Ctrl+u tabCompletionAvailable=tabCompletionPrevSuggestion

    # --- fzf / ripgrep integration ----------------------------------------

    if command -v fzf >/dev/null 2>&1; then
        eval "$(fzf --bash)"

        # Find a file under the CWD (via fd) and open it in $EDITOR.
        flyline_fzf_find_files() {
            local file
            file=$(fd --type f --hidden --exclude .git . 2>/dev/null \
                | fzf --preview 'bat --style=numbers --color=always {} 2>/dev/null || cat {}') || return
            READLINE_LINE="${EDITOR:-nvim} -- \"$file\""
            READLINE_POINT=${#READLINE_LINE}
        }

        # Live ripgrep search under the CWD, opens the match in $EDITOR at that line.
        flyline_fzf_live_grep() {
            local result file line
            result=$(rg --line-number --no-heading --color=always . 2>/dev/null \
                | fzf --ansi --delimiter : \
                    --preview 'bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null || cat {1}' \
                    --preview-window '+{2}-/2' \
                    --bind 'change:reload:rg --line-number --no-heading --color=always {q} 2>/dev/null || true' \
                    --disabled) || return
            file="${result%%:*}"
            line="${result#*:}"; line="${line%%:*}"
            READLINE_LINE="${EDITOR:-nvim} +${line} -- \"$file\""
            READLINE_POINT=${#READLINE_LINE}
        }

        # Leader-key mnemonics echoing your Neovim <leader>ff / <leader>gg.
        # Flyline's leader state can't tell a 2nd "f"/"g" press from a 1st, so
        # this is leader+f / leader+g rather than a literal double-tap.
        # Space is only bound as the leader when the buffer is empty
        # (bufferIsEmpty), so it falls through to a normal space character
        # the rest of the time - same feel as Neovim's spacebar leader in
        # normal mode not colliding with typing a space.
        flyline key bind Space bufferIsEmpty=setLeaderKey
        flyline key bind f 'leaderKeyActive=runBashCommand(flyline_fzf_find_files)+submitOrNewline+unsetLeaderKey'
        flyline key bind g 'leaderKeyActive=runBashCommand(flyline_fzf_live_grep)+submitOrNewline+unsetLeaderKey'
    fi
fi
