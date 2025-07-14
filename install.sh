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

# URLs for downloading the script and version
GIFIFY_URL="https://raw.githubusercontent.com/pidoshva/gifify/main/gifify.sh"
VERSION_URL="https://raw.githubusercontent.com/pidoshva/gifify/main/VERSION"

# Check remote version
REMOTE_VERSION=$(curl -fsSL "$VERSION_URL")
LOCAL_VERSION="none"
[ -f "$GIFIFY_DIR/VERSION" ] && LOCAL_VERSION=$(cat "$GIFIFY_DIR/VERSION")

if [ "$REMOTE_VERSION" != "$LOCAL_VERSION" ]; then
    echo "Installing gifify version $REMOTE_VERSION..."
    curl -fsSL "$GIFIFY_URL" -o "$GIFIFY_DIR/gifify.sh"
    echo "$REMOTE_VERSION" > "$GIFIFY_DIR/VERSION"
else
    echo "gifify is up to date (version $LOCAL_VERSION)"
fi


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
