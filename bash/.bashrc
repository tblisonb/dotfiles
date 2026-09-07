#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Enable the flyline readline replacement (https://github.com/HalFrgrd/flyline)
# if it's been built/installed. Prefers a proper system install (e.g. once
# the AUR package installs cleanly); falls back to the manually-built copy.
enable flyline 2>/dev/null || enable -f "$HOME/.local/lib/bash/libflyline.so" flyline 2>/dev/null

source ~/.bash_git

# Aliases and functions live in ~/.bash_aliases so this file stays portable
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Flyline (readline replacement) config, only takes effect once flyline is
# enabled - see bash/.flyline.sh for how to install/enable it.
if [ -f ~/.flyline.sh ]; then
    . ~/.flyline.sh
fi

# zoxide: smarter cd that learns your frequent directories
eval "$(zoxide init bash --cmd cd)"

PROMPT_COMMAND='PS1_CMD1=$(__git_ps1 " (%s)")'; PS1='\[\e[38;5;45m\]\u\[\e[38;5;145m\]@\[\e[38;5;69m\]\H\[\e[38;5;145m\]:\[\e[38;5;186m\]\w\[\e[0m\] \[\e[38;5;216m\][\[\e[38;5;216m\]\!\[\e[38;5;216m\]]\[\e[38;5;84m\]${PS1_CMD1}\n\[\e[38;5;202m\]\$\[\e[97m\] \[\e[0m\]'

# Flyline right prompt / ruler: time now lives in RPS1 (ISO 8601) since PS1
# no longer carries it, and PROMPT_RULER draws a separator between commands
# in place of the leading blank line PS1 used to have.
export RPS1='\e[01;33m\D{%Y-%m-%dT%H:%M:%S}\n<\e[00m'
export PROMPT_RULER='-'

export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=10000
export HISTFILESIZE=20000
shopt -s histappend
PROMPT_COMMAND="$PROMPT_COMMAND; history -a"

# Editor / pager
export EDITOR=nvim
export LESS='-R'

# ripgrep
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

neofetch
. "$HOME/.cargo/env"
export PATH="$HOME/.local/bin:$PATH"

# Deduplicate PATH (in case this file gets sourced more than once)
dedup_path() {
    if [ -n "$PATH" ]; then
        old_PATH=$PATH:; PATH=
        while [ -n "$old_PATH" ]; do
            x=${old_PATH%%:*}
            case $PATH: in
                *:"$x":*) ;;
                *) PATH=$PATH:$x ;;
            esac
            old_PATH=${old_PATH#*:}
        done
        PATH=${PATH#:}
    fi
    unset old_PATH x
}
dedup_path
