#!/bin/bash

echo "Installing gifify..."

# Install ffmpeg if not already
if ! command -v ffmpeg &> /dev/null; then
	echo "ffmpeg not found. Installing via Homebrew..."
	if ! command  -v brew &> /dev/null; then
		echo "Homebrew is not installed! Install it manually first."
		exit 1
	fi
	brew install ffmpeg
fi

# Create ~/bin directory if not present already
mkdir -p ~/bin

# Copy gifify.sh to ~/bin and make it executable
cp gifify.sh ~/bin/gifify.sh
chmod +x ~/bin/gifify

# Add ~/bin to PATH if not already in there
if [[ ":$PATH :" != *":$HOME/bin:"* ]]; then
	echo 'export PATH="$HOME/bin:$PATH"
	export PATH="$HOME/bin:$PATH"
fi

echo "gifify installed! Run gifify for details."

