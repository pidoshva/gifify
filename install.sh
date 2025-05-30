#!/bin/bash

echo "Installing gifify..."

# Check for ffmpeg and install if missing
if ! command -v ffmpeg &> /dev/null; then
    echo "🔍 ffmpeg not found. Installing via Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed! Please install it manually first."
        exit 1
    fi
    brew install ffmpeg || { echo "Failed to install ffmpeg."; exit 1; }
fi

# Create ~/bin if not exists
BIN_DIR="$HOME/bin"
mkdir -p "$BIN_DIR"

# Copy gifify.sh and rename to 'gifify'
SCRIPT_NAME="gifify.sh"
TARGET_SCRIPT="$BIN_DIR/gifify"

cp "$SCRIPT_NAME" "$TARGET_SCRIPT" || { echo "Failed to copy $SCRIPT_NAME."; exit 1; }
chmod +x "$TARGET_SCRIPT"

# Add ~/bin to PATH if not already present
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "Adding $BIN_DIR to PATH in ~/.zshrc..."
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
fi

echo "gifify installed! Open a new terminal or run 'source ~/.zshrc' to start using it."

