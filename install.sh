#!/usr/bin/env bash
set -euo pipefail

GIFIFY_DIR="$HOME/.gifify"
REPO_URL="https://raw.githubusercontent.com/pidoshva/gifify/main"

# ── Helpers ─────────────────────────────────────────────────────────

info()  { echo "  $*"; }
error() { echo "Error: $*" >&2; }

detect_rc_file() {
    case "$(basename "${SHELL:-/bin/bash}")" in
        zsh)  echo "$HOME/.zshrc"  ;;
        *)    echo "$HOME/.bashrc" ;;
    esac
}

install_ffmpeg() {
    if command -v brew >/dev/null 2>&1; then
        info "Installing ffmpeg with Homebrew..."
        brew install ffmpeg
    elif command -v apt-get >/dev/null 2>&1; then
        info "Installing ffmpeg with apt-get..."
        sudo apt-get update && sudo apt-get install -y ffmpeg
    elif command -v dnf >/dev/null 2>&1; then
        info "Installing ffmpeg with dnf..."
        sudo dnf install -y ffmpeg
    elif command -v pacman >/dev/null 2>&1; then
        info "Installing ffmpeg with pacman..."
        sudo pacman -S --noconfirm ffmpeg
    else
        error "No supported package manager found. Please install ffmpeg manually."
        return 1
    fi
}

# ── Uninstall ───────────────────────────────────────────────────────

do_uninstall() {
    echo "Uninstalling gifify..."

    if [ -d "$GIFIFY_DIR" ]; then
        rm -rf "$GIFIFY_DIR"
        info "Removed $GIFIFY_DIR"
    fi

# URL for downloading the script
GIFIFY_URL="https://raw.githubusercontent.com/pidoshva/gifify/main/gifify.sh"

echo "Downloading gifify script..."
curl -fsSL "$GIFIFY_URL" -o "$GIFIFY_DIR/gifify.sh"

# Ensure gifify function is loaded in zsh
ZSHRC="$HOME/.zshrc"
SOURCE_LINE="source \"$HOME/.gifify/gifify.sh\""
if ! grep -Fq 'gifify.sh' "$ZSHRC" 2>/dev/null; then
    echo "Adding gifify function to $ZSHRC..."
    echo -e "\n# Load gifify function\n$SOURCE_LINE" >> "$ZSHRC"
fi

# Source the function for current session if running zsh
if [ -n "$ZSH_VERSION" ]; then
# shellcheck disable=SC1090

# URLs for downloading the script and version
GIFIFY_URL="https://raw.githubusercontent.com/pidoshva/gifify/main/gifify.sh"
VERSION_URL="https://raw.githubusercontent.com/pidoshva/gifify/main/VERSION"

    # Also clean the other rc file in case they switched shells
    local rc_files=("$rc_file")
    [ "$rc_file" != "$HOME/.bashrc" ] && rc_files+=("$HOME/.bashrc")
    [ "$rc_file" != "$HOME/.zshrc" ]  && rc_files+=("$HOME/.zshrc")

    for rc in "${rc_files[@]}"; do
        if [ -f "$rc" ] && grep -q 'gifify' "$rc" 2>/dev/null; then
            # Remove the comment line and the source line
            sed -i.bak '/# Load gifify/d;/\.gifify\/gifify\.sh/d' "$rc"
            rm -f "${rc}.bak"
            info "Cleaned $rc"
        fi
    done

    echo "gifify uninstalled."
}

# ── Install ─────────────────────────────────────────────────────────

GIFIFY_DIR="$HOME/.gifify"
mkdir -p "$GIFIFY_DIR"
cp "gifify.sh" "$GIFIFY_DIR/gifify.sh"

# Ensure gifify function is loaded in zsh
ZSHRC="$HOME/.zshrc"
SOURCE_LINE="source \"$HOME/.gifify/gifify.sh\""
if ! grep -Fq 'gifify.sh' "$ZSHRC" 2>/dev/null; then
    echo "Adding gifify function to $ZSHRC..."
    echo -e "\n# Load gifify function\n$SOURCE_LINE" >> "$ZSHRC"
fi

# Source the function for current session if running zsh
if [ -n "$ZSH_VERSION" ]; then

    source "$ZSHRC"
fi

echo "gifify installed! Open a new terminal or run 'source $ZSHRC' to start using it."
