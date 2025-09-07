# Dotfiles

Opinionated macOS setup for zsh, Neovim, tmux, and iTerm2.

## Install

1) Clone the repo (no sudo):

```sh
git clone https://github.com/k4ch0w/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

2) Run the installer:

```sh
bash install.sh
```

Notes:
- The script installs Homebrew packages from `Brewfile` and symlinks configs into your `$HOME`.
- iTerm2 preferences are redirected to `$HOME/.config/iterm_config` (macOS only).
- For optional Rust toolchain, run: `WITH_RUST=1 bash install.sh`.

## Contents
- `zshrc` with Oh My Zsh, autosuggestions, syntax highlighting, and Spaceship theme.
- `nvim/` using lazy.nvim with LSP, Treesitter, Telescope, and UI tweaks.
- `tmux.conf` with TPM and sane defaults (truecolor, vi keys, mouse).
- `Brewfile` for core CLI tools and Nerd Font.
