# gifify

Convert videos to optimized GIFs using ffmpeg's two-pass palette technique.

gifify produces high-quality GIFs with accurate colors by generating an optimal color palette from the source video, then using it to create the final GIF.

## Features

- Two-pass palette generation for accurate colors
- Multiple resolution presets (1080p, 720p, 480p, 360p)
- Configurable frame rate
- Custom output path support
- Cross-platform ffmpeg detection and installation
- Safe temp files with automatic cleanup
- Works as a shell function (sourced) or standalone script

## Install

**One-liner (curl):**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/pidoshva/gifify/main/install.sh)"
```

**From a local clone:**

```bash
git clone https://github.com/pidoshva/gifify.git
cd gifify
./install.sh
```

**Or with make:**

```bash
make install
```

The installer copies `gifify.sh` to `~/.gifify/` and adds a `source` line to your `.bashrc` or `.zshrc` (auto-detected). If `ffmpeg` is not installed, it will be installed automatically using your system's package manager.

After installing, open a new terminal or run:

```bash
source ~/.bashrc   # or source ~/.zshrc
```

## Usage

```bash
gifify video.mp4                      # Default: 1080p, 15fps
gifify video.mp4 --720p               # 720p resolution
gifify video.mp4 --480p --fps 10      # 480p at 10fps
gifify video.mp4 -o output.gif        # Custom output path
gifify video.mp4 --360p -o small.gif  # 360p with custom output
```

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `-o, --output <path>` | Output file path | `~/Desktop/gifified/<name>.gif` |
| `--fps <n>` | Frames per second | `15` |
| `--1080p` | Scale to 1920px width | (default) |
| `--720p` | Scale to 1280px width | |
| `--480p` | Scale to 854px width | |
| `--360p` | Scale to 640px width | |
| `-h, --help` | Show help | |
| `-v, --version` | Show version | |

## How It Works

1. **Palette generation** -- ffmpeg analyzes the video and generates an optimal 256-color palette using the Lanczos scaling algorithm
2. **GIF creation** -- ffmpeg re-encodes the video using the generated palette for maximum color accuracy

This two-pass approach produces significantly better results than a single-pass conversion.

## Requirements

- **ffmpeg** -- the installer handles this automatically, or install it manually:
  - macOS: `brew install ffmpeg`
  - Ubuntu/Debian: `sudo apt-get install ffmpeg`
  - Fedora: `sudo dnf install ffmpeg`
  - Arch: `sudo pacman -S ffmpeg`

## Output

By default, GIFs are saved to `~/Desktop/gifified/`. Use `-o` to specify a custom path.

## Uninstall

```bash
./install.sh --uninstall
# or
make uninstall
```

This removes `~/.gifify/` and cleans the source line from your shell RC files.

## License

[MIT](LICENSE)
