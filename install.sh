#!/usr/bin/env bash
#
# install.sh - bootstrap this dotfiles repo onto a machine.
#
# What it does:
#   1. Clones https://github.com/tblisonb/dotfiles to ~/Applications/dotfiles
#      (if it isn't already there).
#   2. Symlinks the tracked config files/dirs into their real locations,
#      backing up anything real that's already there.
#   3. Best-effort installs the packages the bash config depends on
#      (eza, bat, fd, ripgrep, zoxide, neofetch, ...) using whatever package
#      manager the current distro uses.
#
# Safe to re-run: skips anything already linked/installed.

set -uo pipefail

REPO_URL="https://github.com/tblisonb/dotfiles"
REPO_DIR="$HOME/Applications/dotfiles"
BACKUP_SUFFIX=".bak-$(date +%Y%m%d%H%M%S)"

msg()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

# --- 1. Clone the repo if it's not already present -------------------------

clone_repo() {
    if [ -d "$REPO_DIR/.git" ]; then
        msg "dotfiles repo already present at $REPO_DIR, skipping clone"
        return
    fi

    if [ -e "$REPO_DIR" ]; then
        warn "$REPO_DIR exists but isn't a git repo; move it aside and re-run"
        exit 1
    fi

    msg "cloning $REPO_URL to $REPO_DIR"
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone "$REPO_URL" "$REPO_DIR"
}

# --- 2. Symlink config files/dirs into place --------------------------------

link_path() {
    # link_path <source-in-repo> <target-in-home>
    local src="$1" dest="$2"

    if [ ! -e "$src" ]; then
        warn "source '$src' not found in repo, skipping"
        return
    fi

    if [ -L "$dest" ]; then
        if [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
            msg "already linked: $dest"
            return
        fi
        warn "replacing stale symlink: $dest"
        rm "$dest"
    elif [ -e "$dest" ]; then
        warn "backing up existing $dest -> $dest$BACKUP_SUFFIX"
        mv "$dest" "$dest$BACKUP_SUFFIX"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    msg "linked $dest -> $src"
}

setup_symlinks() {
    # bash: individual dotfiles at $HOME root
    link_path "$REPO_DIR/bash/.bashrc"       "$HOME/.bashrc"
    link_path "$REPO_DIR/bash/.bash_aliases" "$HOME/.bash_aliases"
    link_path "$REPO_DIR/bash/.bash_git"     "$HOME/.bash_git"

    # nvim: whole config directory
    link_path "$REPO_DIR/nvim" "$HOME/.config/nvim"

    # ripgrep / wezterm: individual dotfiles at $HOME root
    link_path "$REPO_DIR/ripgrep/.ripgreprc"   "$HOME/.ripgreprc"
    link_path "$REPO_DIR/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"
}

# --- 3. Install packages the bash config depends on -------------------------

DISTRO_ID=""
DISTRO_LIKE=""

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID="$ID"
        DISTRO_LIKE="$ID_LIKE"
    fi
}

install_packages() {
    detect_distro
    local combo="$DISTRO_ID $DISTRO_LIKE"

    case "$combo" in
        *arch*)
            msg "installing packages via pacman"
            sudo pacman -Syu --needed --noconfirm \
                eza bat fd ripgrep zoxide neofetch unzip p7zip \
                || warn "pacman install had failures, check output above"
            ;;
        *debian*|*ubuntu*)
            msg "installing packages via apt"
            sudo apt-get update
            sudo apt-get install -y \
                eza bat fd-find ripgrep zoxide neofetch nala unzip p7zip-full \
                || warn "apt install had failures, check output above"
            ;;
        *suse*)
            msg "installing packages via zypper"
            sudo zypper --non-interactive install \
                eza bat fd ripgrep zoxide neofetch unzip p7zip \
                || warn "zypper install had failures, check output above"
            ;;
        *fedora*|*rhel*)
            msg "installing packages via dnf"
            sudo dnf install -y \
                eza bat fd-find ripgrep zoxide neofetch unzip p7zip \
                || warn "dnf install had failures, check output above"
            ;;
        *)
            warn "unrecognized distro (ID=$DISTRO_ID ID_LIKE=$DISTRO_LIKE)," \
                 "install eza/bat/fd/ripgrep/zoxide/neofetch manually"
            ;;
    esac
}

# Some distros ship bat/fd under different binary names (batcat/fdfind) to
# avoid clashing with unrelated packages. The bash config assumes `bat` and
# `fd` are on PATH, so paper over that with a symlink in ~/.local/bin.
fixup_renamed_binaries() {
    mkdir -p "$HOME/.local/bin"

    if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        msg "linked ~/.local/bin/bat -> $(command -v batcat)"
    fi

    if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
        msg "linked ~/.local/bin/fd -> $(command -v fdfind)"
    fi
}

# --- main --------------------------------------------------------------

clone_repo
setup_symlinks
install_packages
fixup_renamed_binaries

msg "done. Start a new shell (or 'source ~/.bashrc') to pick everything up."
