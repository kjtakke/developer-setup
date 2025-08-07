#!/usr/bin/env bash
#
# Unified installation script for Linux (Debian/Mint) and macOS.
#
# This script installs Neovim, Zsh/Oh My Zsh, Starship, Node.js
# language servers, Nerd Fonts, and copies configuration files into
# place.  It avoids using the `git` command for downloads; instead it
# relies on curl to fetch resources from GitHub.  Helper functions
# defined in external scripts are downloaded and stored under
# `~/bin`, and both `.bashrc` and `.zshrc` are updated to source
# these helpers, configure Starship and set useful aliases.

set -euo pipefail

# Detect the operating system
OS=$(uname -s)

#############################################
# Helper functions
#############################################

# Append a line to a file if the exact line does not already exist.
# Creates the file if it does not exist.  This avoids duplicating
# configuration lines when re‑running the script.
append_line_if_missing() {
  local file="$1"
  local line="$2"
  [[ -f "$file" ]] || touch "$file"
  if ! grep -qxF "$line" "$file"; then
    echo "$line" >> "$file"
  fi
}

# Download a file via curl and write it to the specified destination.
# Creates parent directories as needed.
download_and_place() {
  local url="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  curl -fsSL "$url" -o "$dest"
}

#############################################
# Package installation
#############################################

if [[ "$OS" == "Linux" ]]; then
  # Debian/Mint: update package lists and install core utilities
  sudo apt update
  sudo apt install -y curl zsh ripgrep pylint shellcheck tmux unzip xclip pipx
  # Ensure pipx puts its shims in the PATH
  pipx ensurepath
  # Node.js via NodeSource for up‑to‑date LSP servers
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt install -y nodejs
elif [[ "$OS" == "Darwin" ]]; then
  # macOS: ensure Homebrew is present
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Please install Homebrew first from https://brew.sh" >&2
    exit 1
  fi
  brew update
  brew install curl zsh ripgrep pylint shellcheck tmux unzip node pipx
  pipx ensurepath
else
  echo "Unsupported operating system: $OS" >&2
  exit 1
fi

# Install Python package for Neovim using pipx
pipx install --force pynvim

# Install language servers globally via npm
if [[ "$OS" == "Linux" ]]; then
  sudo npm install -g pyright bash-language-server tree-sitter-cli
else
  npm install -g pyright bash-language-server tree-sitter-cli
fi

# Install Starship prompt【822665154770329†L90-L110】
if [[ "$OS" == "Linux" ]]; then
  # Official install script with automatic install (-y)
  curl -sS https://starship.rs/install.sh | sh -s -- -y
else
  # Homebrew installation on macOS
  brew install starship
fi

# Install Oh My Zsh silently if not already installed
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install Nerd Font (DroidSansMono)
if [[ "$OS" == "Linux" ]]; then
  mkdir -p "$HOME/.fonts"
  ( cd "$HOME/.fonts" && curl -L -O https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/DroidSansMono.zip && unzip -o DroidSansMono.zip && rm -f DroidSansMono.zip )
  fc-cache -fv > /dev/null || true
else
  mkdir -p "$HOME/Library/Fonts"
  ( cd "$HOME/Library/Fonts" && curl -L -O https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/DroidSansMono.zip && unzip -o DroidSansMono.zip && rm -f DroidSansMono.zip )
fi

# Install Neovim
NVIM_BIN="nvim"
if [[ "$OS" == "Linux" ]]; then
  # Use precompiled tarball on Linux
  curl -LO https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz
  sudo rm -rf /opt/nvim-linux64
  sudo tar -C /opt -xzf nvim-linux64.tar.gz
  rm -f nvim-linux64.tar.gz
  NVIM_BIN="/opt/nvim-linux64/bin/nvim"
elif [[ "$OS" == "Darwin" ]]; then
  brew install neovim
  NVIM_BIN=$(command -v nvim)
fi

#############################################
# NeoVim configuration
#############################################

# Create config directories
mkdir -p "$HOME/.config/nvim/lua/plugins"
mkdir -p "$HOME/.local/share/nvim/lazy"

# Download configuration files from the repository
download_and_place https://raw.githubusercontent.com/kjtakke/neovim/master/init.lua "$HOME/.config/nvim/init.lua"
download_and_place https://raw.githubusercontent.com/kjtakke/neovim/master/search/nsearch.txt "$HOME/.config/nvim/nsearch.txt"
download_and_place https://raw.githubusercontent.com/kjtakke/neovim/master/lazy-lock.json "$HOME/.config/nvim/lazy-lock.json"
download_and_place https://raw.githubusercontent.com/kjtakke/neovim/master/lua/cmp.lua.bak "$HOME/.config/nvim/lua/cmp.lua.bak"
download_and_place https://raw.githubusercontent.com/kjtakke/neovim/master/lua/init.lua "$HOME/.config/nvim/lua/init.lua"
download_and_place https://raw.githubusercontent.com/kjtakke/neovim/master/lua/lsp.lua "$HOME/.config/nvim/lua/lsp.lua"
download_and_place https://raw.githubusercontent.com/kjtakke/neovim/master/lua/plugins/init.lua "$HOME/.config/nvim/lua/plugins/init.lua"

# Install lazy.nvim without git by extracting the stable branch archive
LAZY_DIR="$HOME/.local/share/nvim/lazy/lazy.nvim"
rm -rf "$LAZY_DIR"
mkdir -p "$LAZY_DIR"
curl -L https://github.com/folke/lazy.nvim/archive/refs/heads/stable.tar.gz | tar xz --strip-components=1 -C "$LAZY_DIR"

#############################################
# Shell helper scripts and configuration
#############################################

# Ensure ~/bin exists and add it to PATH in both shells
mkdir -p "$HOME/bin"
append_line_if_missing "$HOME/.bashrc" 'export PATH="$HOME/bin:$PATH"'
append_line_if_missing "$HOME/.zshrc"  'export PATH="$HOME/bin:$PATH"'

# Download Git helper script and mark it executable
download_and_place https://raw.githubusercontent.com/kjtakke/git-helper-scripts/main/git-helper.sh "$HOME/bin/git-helper.sh"
chmod +x "$HOME/bin/git-helper.sh"

# Install tmux helper script directly
cat <<'TMUXSCRIPT' > "$HOME/bin/tmux.sh"
#!/bin/bash

# Create aliases for managing tmux sessions without relying on git.
tmux_attach_session() {
  tmux attach-session -t "$1"
}
tmux_new_session() {
  if [[ -z "$1" ]]; then
    echo "❌ Please provide a session name."
    return 1
  fi
  local session_name="$1"
  if [[ -n "$TMUX" ]]; then
    tmux new-session -d -s "$session_name"
    tmux switch-client -t "$session_name"
  else
    tmux new-session -s "$session_name"
  fi
}
tmux_kill_session() {
  if [[ "$1" == "--all" ]]; then
    echo "⚠️  Killing all tmux sessions..."
    tmux list-sessions -F '#S' | while read -r s; do
      tmux kill-session -t "$s"
    done
    return
  fi
  if [[ -z "$1" && -n "$TMUX" ]]; then
    local current
    current=$(tmux display-message -p '#S')
    echo " Killing current tmux session: $current"
    tmux kill-session -t "$current"
    return
  fi
  if [[ -n "$1" ]]; then
    echo " Killing tmux session: $1"
    tmux kill-session -t "$1"
    return
  fi
  echo "❌ No session name provided and not inside a tmux session."
  return 1
}
ta() {
  if ! command -v tmux >/dev/null 2>&1; then
    echo "tmux is not installed. Please install tmux first."
    return 1
  fi
  local first
  first=$(tmux list-sessions -F '#S' 2>/dev/null | head -n 1)
  if [[ -n "$first" ]]; then
    echo "Attaching to tmux session: $first"
    tmux attach -t "$first"
  else
    echo "No tmux sessions found. Creating a new session 'term' in ~"
    tmux new-session -s term -c ~
  fi
}
alias tmux-n="tmux_new_session"
alias tmux-a="tmux_attach_session"
alias tmux-k="tmux_kill_session"
alias n="tmux_new_session"
alias a="tmux_attach_session"
alias k="tmux_kill_session"
TMUXSCRIPT
chmod +x "$HOME/bin/tmux.sh"

# Install tmux configuration
cat <<'EOF' > "$HOME/.tmux.conf"
set -g mouse on
setw -g mode-keys vi
bind-key -T copy-mode-vi v send -X begin-selection
bind-key -T copy-mode-vi y send -X copy-selection
bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel "xclip -selection clipboard -in"
EOF

# Create Starship configuration
mkdir -p "$HOME/.config"
cat <<'EOF' > "$HOME/.config/starship.toml"
format = """
$username $directory$git_branch$git_status$nodejs$python$time
$character
"""

[username]
show_always = true
style_user = "bold fg:green"
format = "[$user]($style)"

[directory]
style = "bold fg:blue"
truncation_length = 3
truncate_to_repo = false
format = " in [$path]($style) "

[git_branch]
symbol = "🌿 "
style = "bold fg:purple"
format = "on [$symbol$branch]($style) "

[git_status]
style = "fg:yellow"
format = "[$all_status]($style)"

[nodejs]
symbol = "⬢ "
style = "fg:green"
format = "via [$symbol$version]($style) "

[python]
symbol = "🐍 "
style = "fg:cyan"
format = "via [$symbol$version]($style) "

[time]
disabled = false
time_format = "%H:%M"
style = "fg:yellow"
format = " [$time]($style)"

[character]
success_symbol = "[❯](bold fg:green) "
error_symbol = "[✗](bold fg:red) "
EOF

# Download zsh plugins from GitHub archives instead of cloning via git
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM/plugins"
declare -A plugin_urls=(
  [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions/archive/refs/heads/master.tar.gz"
  [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting/archive/refs/heads/master.tar.gz"
  [fast-syntax-highlighting]="https://github.com/zdharma-continuum/fast-syntax-highlighting/archive/refs/heads/master.tar.gz"
  [zsh-autocomplete]="https://github.com/marlonrichert/zsh-autocomplete/archive/refs/heads/main.tar.gz"
)
for plugin in "${!plugin_urls[@]}"; do
  dir="$ZSH_CUSTOM/plugins/$plugin"
  url="${plugin_urls[$plugin]}"
  rm -rf "$dir"
  mkdir -p "$dir"
  curl -L "$url" | tar xz --strip-components=1 -C "$dir"
done

# Source helper scripts in shell RC files
append_line_if_missing "$HOME/.bashrc" '[ -f "$HOME/bin/git-helper.sh" ] && source "$HOME/bin/git-helper.sh"'
append_line_if_missing "$HOME/.bashrc" '[ -f "$HOME/bin/tmux.sh" ] && source "$HOME/bin/tmux.sh"'
append_line_if_missing "$HOME/.zshrc"  '[ -f "$HOME/bin/git-helper.sh" ] && source "$HOME/bin/git-helper.sh"'
append_line_if_missing "$HOME/.zshrc"  '[ -f "$HOME/bin/tmux.sh" ] && source "$HOME/bin/tmux.sh"'

# Add alias for Neovim in both shells
append_line_if_missing "$HOME/.bashrc" "alias nvim='$NVIM_BIN'"
append_line_if_missing "$HOME/.zshrc"  "alias nvim='$NVIM_BIN'"

# Initialise Starship in both shells
append_line_if_missing "$HOME/.zshrc" 'eval "$(starship init zsh)"'
append_line_if_missing "$HOME/.bashrc" 'eval "$(starship init bash)"'

# Configure Oh My Zsh theme and plugins
append_line_if_missing "$HOME/.zshrc" 'export ZSH="$HOME/.oh-my-zsh"'
append_line_if_missing "$HOME/.zshrc" 'ZSH_THEME="agnoster"'
append_line_if_missing "$HOME/.zshrc" 'plugins=(git zsh-autosuggestions fast-syntax-highlighting zsh-syntax-highlighting)'
append_line_if_missing "$HOME/.zshrc" 'source ~/.oh-my-zsh/custom/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh'

# Change default shell to zsh if not already
if [[ "$SHELL" != "$(command -v zsh)" ]]; then
  chsh -s "$(command -v zsh)" "$USER" || true
fi

echo "Installation complete. Please restart your terminal session or reload your shell to apply the changes."
