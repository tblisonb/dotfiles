#
# ~/.bashrc
#

source ~/.bash_git

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

alias ll='ls -l'
alias la='ls -la'
alias sudo='sudo -v; sudo '
alias up='sudo sh -c "pacman -Syu; flatpak upgrade -y"'
alias hx='helix'

PROMPT_COMMAND='PS1_CMD1=$(__git_ps1 " (%s)")'; PS1='\n\[\e[38;5;145m\]\T\[\e[0m\] \[\e[38;5;45m\]\u\[\e[38;5;145m\]@\[\e[38;5;69m\]\H\[\e[38;5;145m\]:\[\e[38;5;186m\]\w\[\e[0m\] \[\e[38;5;216m\][\[\e[38;5;216m\]\!\[\e[38;5;216m\]]\[\e[38;5;84m\]${PS1_CMD1}\n\[\e[38;5;202m\]\$\[\e[97m\] \[\e[0m\]'

export HISTCONTROL=ignoreboth:erasedups

neofetch
. "$HOME/.cargo/env"
