# Installation

Run the following command to install **gifify**:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/pidoshva/gifify/main/install.sh)"
```

The script verifies that `ffmpeg` is installed (using Homebrew or `apt-get` when possible), downloads the latest `gifify.sh`, and sources it from your `~/.zshrc`. After running the installer open a new shell or run `source ~/.zshrc` to use the `gifify` command.

# Versioning

The installer compares the local version stored in `~/.gifify/VERSION` with the version published in this repository. When a new release is available, `install.sh` downloads the updated script automatically.

# Development

This repository uses GitHub Actions to run `shellcheck` and ensure the version in `gifify.sh` matches the `VERSION` file on every commit.

