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

    local rc_file
    rc_file="$(detect_rc_file)"

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

do_install() {
    echo "Installing gifify..."

    # 1. Ensure ffmpeg is available
    if ! command -v ffmpeg >/dev/null 2>&1; then
        info "ffmpeg not found."
        install_ffmpeg || exit 1
    fi

    # 2. Create install directory
    mkdir -p "$GIFIFY_DIR"

    # 3. Copy or download gifify.sh
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [ -f "$script_dir/gifify.sh" ]; then
        # Local clone install
        cp "$script_dir/gifify.sh" "$GIFIFY_DIR/gifify.sh"
        info "Copied gifify.sh from local repo"
        # Copy VERSION if present
        if [ -f "$script_dir/VERSION" ]; then
            cp "$script_dir/VERSION" "$GIFIFY_DIR/VERSION"
        fi
    else
        # Remote install (curl pipe)
        info "Downloading gifify.sh..."
        curl -fsSL "$REPO_URL/gifify.sh" -o "$GIFIFY_DIR/gifify.sh"
        curl -fsSL "$REPO_URL/VERSION" -o "$GIFIFY_DIR/VERSION"
    fi

    chmod +x "$GIFIFY_DIR/gifify.sh"

    # 4. Add source line to shell RC file
    local rc_file source_line
    rc_file="$(detect_rc_file)"
    source_line="source \"$GIFIFY_DIR/gifify.sh\""

    if ! grep -Fq 'gifify.sh' "$rc_file" 2>/dev/null; then
        info "Adding gifify to $rc_file..."
        printf '\n# Load gifify\n%s\n' "$source_line" >> "$rc_file"
    else
        info "gifify already configured in $rc_file"
    fi

    echo ""
    echo "gifify installed! Run 'source $rc_file' or open a new terminal to start using it."
    echo "Usage: gifify <video_file> [--720p|--480p|--360p]"
}

# ── Main ────────────────────────────────────────────────────────────

main() {
    case "${1:-}" in
        --uninstall) do_uninstall ;;
        *)           do_install   ;;
    esac
}

main "$@"
