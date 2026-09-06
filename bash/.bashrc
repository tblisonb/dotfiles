#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

source ~/.bash_git

# Aliases and functions live in ~/.bash_aliases so this file stays portable
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# zoxide: smarter cd that learns your frequent directories
eval "$(zoxide init bash --cmd cd)"

PROMPT_COMMAND='PS1_CMD1=$(__git_ps1 " (%s)")'; PS1='\n\[\e[38;5;145m\]\T\[\e[0m\] \[\e[38;5;45m\]\u\[\e[38;5;145m\]@\[\e[38;5;69m\]\H\[\e[38;5;145m\]:\[\e[38;5;186m\]\w\[\e[0m\] \[\e[38;5;216m\][\[\e[38;5;216m\]\!\[\e[38;5;216m\]]\[\e[38;5;84m\]${PS1_CMD1}\n\[\e[38;5;202m\]\$\[\e[97m\] \[\e[0m\]'

export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=10000
export HISTFILESIZE=20000
shopt -s histappend
PROMPT_COMMAND="$PROMPT_COMMAND; history -a"

# Editor / pager
export EDITOR=nvim
export LESS='-R'

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
