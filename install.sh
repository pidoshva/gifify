#!/bin/bash
set -e

echo "Installing gifify..."

# Detect package manager for ffmpeg installation
install_ffmpeg() {
    if command -v brew >/dev/null; then
        echo "Installing ffmpeg with Homebrew..."
        brew install ffmpeg
    elif command -v apt-get >/dev/null; then
        echo "Installing ffmpeg with apt-get..."
        sudo apt-get update && sudo apt-get install -y ffmpeg
    else
        echo "No supported package manager found. Please install ffmpeg manually." >&2
        return 1
    fi
}

if ! command -v ffmpeg >/dev/null; then
    echo "ffmpeg not found."
    install_ffmpeg || exit 1
fi

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
