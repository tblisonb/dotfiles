#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

source ~/.bash_git

# Basic aliases
alias ll='ls -l'
alias la='ls -la'
alias sudo='sudo -v; sudo '
alias up='sudo sh -c "pacman -Syu; flatpak upgrade -y"'
alias hx='helix'

# Modern CLI tool replacements (eza, bat, fd, ripgrep)
alias ls='eza --color=auto'
alias grep='rg'
alias cat='bat'
alias find='fd'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# Safety nets
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# zoxide: smarter cd that learns your frequent directories
eval "$(zoxide init bash --cmd cd)"

PROMPT_COMMAND='PS1_CMD1=$(__git_ps1 " (%s)")'; PS1='\n\[\e[38;5;145m\]\T\[\e[0m\] \[\e[38;5;45m\]\u\[\e[38;5;145m\]@\[\e[38;5;69m\]\H\[\e[38;5;145m\]:\[\e[38;5;186m\]\w\[\e[0m\] \[\e[38;5;216m\][\[\e[38;5;216m\]\!\[\e[38;5;216m\]]\[\e[38;5;84m\]${PS1_CMD1}\n\[\e[38;5;202m\]\$\[\e[97m\] \[\e[0m\]'

export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=10000
export HISTFILESIZE=20000
shopt -s histappend
PROMPT_COMMAND="$PROMPT_COMMAND; history -a"

neofetch
. "$HOME/.cargo/env"
