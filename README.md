
# Installation

Run the following command to install **gifify**:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/pidoshva/gifify/main/install.sh)"
```


The script verifies that `ffmpeg` is installed (using Homebrew or `apt-get` when possible), downloads the `gifify.sh` script, and sources it from your `~/.zshrc`. After running the installer open a new shell or run `source ~/.zshrc` to use the `gifify` command.

# Development

This repository uses GitHub Actions to run `shellcheck` on every commit.

=======

The script checks for `ffmpeg` and installs it if missing (using Homebrew or `apt-get`). It downloads the latest `gifify.sh` and adds it to your `~/.zshrc` so you can start using the function in new terminals. The installer stores a version file in `~/.gifify` and will re-download the script when a newer version is available. After installation run `source ~/.zshrc` or open a new shell and invoke `gifify`.

