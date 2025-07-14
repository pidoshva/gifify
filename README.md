# Installation

Run the following command to install **gifify**:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/pidoshva/gifify/main/install.sh)"
```

The script verifies that `ffmpeg` is installed (using Homebrew or `apt-get` when possible), downloads the `gifify.sh` script, and sources it from your `~/.zshrc`. After running the installer open a new shell or run `source ~/.zshrc` to use the `gifify` command.

# Development

This repository uses GitHub Actions to run `shellcheck` on every commit.

