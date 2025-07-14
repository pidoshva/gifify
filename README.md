# Installation

Run the following command to install **gifify**:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/pidoshva/gifify/main/install.sh)"
```

The script checks for `ffmpeg` and installs it if missing (using Homebrew or `apt-get`). It downloads the latest `gifify.sh` and adds it to your `~/.zshrc` so you can start using the function in new terminals. The installer stores a version file in `~/.gifify` and will re-download the script when a newer version is available. After installation run `source ~/.zshrc` or open a new shell and invoke `gifify`.

