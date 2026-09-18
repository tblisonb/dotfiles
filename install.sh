#!/usr/bin/env bash
#
# install.sh - bootstrap this dotfiles repo onto a machine.
#
# Run this from inside a clone of the repo (e.g. `./install.sh`, or by full
# path); it operates on whatever directory it lives in, wherever that repo
# was cloned to.
#
# What it does:
#   1. Symlinks the tracked config files/dirs into their real locations,
#      backing up anything real that's already there.
#   2. Best-effort installs the packages the bash config depends on
#      (eza, bat, fd, ripgrep, zoxide, neofetch, ...) using whatever package
#      manager the current distro uses.
#
# Safe to re-run: skips anything already linked/installed.

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SUFFIX=".bak-$(date +%Y%m%d%H%M%S)"

msg()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

# --- 1. Symlink config files/dirs into place --------------------------------

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
    link_path "$REPO_DIR/bash/.flyline.sh"   "$HOME/.flyline.sh"

    # nvim: whole config directory
    link_path "$REPO_DIR/nvim" "$HOME/.config/nvim"

    # ripgrep / wezterm: individual dotfiles at $HOME root
    link_path "$REPO_DIR/ripgrep/.ripgreprc"   "$HOME/.ripgreprc"
    link_path "$REPO_DIR/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"
}

# --- 2. Install packages the bash config depends on -------------------------

DISTRO_ID=""
DISTRO_LIKE=""

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID="${ID:-}"
        DISTRO_LIKE="${ID_LIKE:-}"
    fi
}

# eza isn't in the default apt repos on Ubuntu 22.04/jammy (or Debian 12/
# bookworm) - prefer the distro's own copy once it ships one, and only fall
# back to eza's own apt repo (https://github.com/eza-community/eza/blob/main/INSTALL.md)
# when apt genuinely has no candidate for it.
install_eza_debian() {
    if command -v eza >/dev/null 2>&1; then
        msg "eza already on PATH, skipping"
        return
    fi

    if apt-cache show eza >/dev/null 2>&1; then
        sudo apt-get install -y eza || warn "apt install of eza failed, check output above"
        return
    fi

    msg "eza isn't in this release's default repos, adding eza's own apt repo"
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg \
        || { warn "failed to fetch/import eza's apt signing key, skipping eza"; return; }
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
        | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt-get update
    sudo apt-get install -y eza || warn "eza install via its own apt repo failed, check output above"
}

install_packages() {
    detect_distro
    local combo="$DISTRO_ID $DISTRO_LIKE"

    case "$combo" in
        *arch*)
            msg "installing packages via pacman"
            sudo pacman -Syu --needed --noconfirm \
                eza bat fd ripgrep zoxide fzf unzip p7zip \
                || warn "pacman install had failures, check output above"
            ;;
        *debian*|*ubuntu*)
            msg "installing packages via apt"
            sudo apt-get update
            # eza is handled separately below: apt-get install fails the
            # *entire* command (installing nothing at all) if even one
            # package name doesn't resolve, and eza isn't in the default
            # repos before Ubuntu 23.10/Debian 13 (confirmed absent on
            # 22.04/jammy) - it was silently taking bat/fd-find/ripgrep/
            # zoxide/etc. down with it.
            sudo apt-get install -y \
                bat fd-find ripgrep zoxide neofetch fzf nala unzip p7zip-full \
                || warn "apt install had failures, check output above"
            install_eza_debian
            ;;
        *suse*)
            msg "installing packages via zypper"
            sudo zypper --non-interactive install \
                eza bat fd ripgrep zoxide neofetch fzf unzip p7zip \
                || warn "zypper install had failures, check output above"
            ;;
        *fedora*|*rhel*)
            msg "installing packages via dnf"
            sudo dnf install -y \
                eza bat fd-find ripgrep zoxide neofetch fzf unzip p7zip \
                || warn "dnf install had failures, check output above"
            ;;
        *)
            warn "unrecognized distro (ID=$DISTRO_ID ID_LIKE=$DISTRO_LIKE)," \
                 "install eza/bat/fd/ripgrep/zoxide/neofetch manually"
            ;;
    esac
}

# flyline (https://github.com/HalFrgrd/flyline) isn't packaged by any distro
# below, so it's not installed here - it downloads and runs a script, which
# should be reviewed and run by hand once per machine:
#   source <(curl -sSfL https://github.com/HalFrgrd/flyline/releases/latest/download/install.sh)
# bash/.flyline.sh (symlinked above) picks it up automatically once enabled.

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

setup_symlinks
install_packages
fixup_renamed_binaries

msg "done. Start a new shell (or 'source ~/.bashrc') to pick everything up."
