#
# ~/.bash_aliases
#
# Aliases and functions, kept separate from ~/.bashrc so this file can be
# reused as-is across machines/distros. Sourced from ~/.bashrc.

# Basic aliases
alias ll='ls -l'
alias la='ls -la'
alias sudo='sudo -v; sudo '

# Modern tool replacements
alias more='less'
alias ls='eza --color=auto'
alias grep='rg'
alias cat='bat'
alias find='fd'
alias vi='nvim'
alias vim='nvim'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# Safety nets
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# Distro-aware system update. This is a function rather than a plain alias
# because it has to branch on package manager and optionally include flatpak.
up() {
    local id="" like=""
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        id="$ID"
        like="$ID_LIKE"
    fi

    case "$id $like" in
        *arch*)
            if command -v yay >/dev/null 2>&1; then
                yay -Syu
            else
                sudo pacman -Syu
            fi
            ;;
        *debian*|*ubuntu*)
            sudo nala update && sudo nala upgrade
            ;;
        *suse*)
            sudo zypper dup
            ;;
        *fedora*|*rhel*)
            sudo dnf upgrade --refresh
            ;;
        *)
            echo "up: unrecognized distro (ID=$id ID_LIKE=$like), upgrade manually" >&2
            return 1
            ;;
    esac

    if command -v flatpak >/dev/null 2>&1 \
        && [ -n "$(flatpak list --app --columns=application 2>/dev/null)" ]; then
        flatpak upgrade -y
    fi
}

# Extract almost any archive type: extract archive.tar.gz
extract() {
    if [ -z "$1" ] || [ ! -f "$1" ]; then
        echo "extract: '$1' is not a valid file" >&2
        return 1
    fi

    case "$1" in
        *.tar.bz2) tar xjf "$1" ;;
        *.tar.gz)  tar xzf "$1" ;;
        *.tar.xz)  tar xJf "$1" ;;
        *.tar)     tar xf  "$1" ;;
        *.tbz2)    tar xjf "$1" ;;
        *.tgz)     tar xzf "$1" ;;
        *.bz2)     bunzip2 "$1" ;;
        *.gz)      gunzip  "$1" ;;
        *.zip)     unzip   "$1" ;;
        *.rar)     unrar x "$1" ;;
        *.7z)      7z x    "$1" ;;
        *)         echo "extract: don't know how to extract '$1'" >&2; return 1 ;;
    esac
}

# Copy a file to file.bak before editing it: backup file.txt
backup() {
    if [ -z "$1" ] || [ ! -e "$1" ]; then
        echo "backup: '$1' is not a valid file" >&2
        return 1
    fi
    cp -i "$1" "$1.bak"
}

# Quick weather / public IP lookups
weather() {
    curl -s "wttr.in/${1:-}"
}

myip() {
    curl -s ifconfig.me
    echo
}
