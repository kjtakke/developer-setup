#!/usr/bin/env bash

# This installation script sets up a development environment on both
# Debian‑based Linux and macOS systems. It installs and configures
# NeoVim, Zsh with Oh‑My‑Zsh and Starship, Tmux, Nerd Fonts, and
# custom Git helper functions. Configuration files are pulled from
# public repositories and applied consistently to both Bash and Zsh
# shells.

set -e

# Helper: append a line to a file only if it does not already exist.
# Arguments:
#   $1 – The file to modify
#   $2 – The exact line to append
append_if_not_exists() {
  local file="$1"
  local line="$2"
  # Create file if it does not exist
  [[ -f "$file" ]] || touch "$file"
  # Use grep to check for the line; -F for fixed string, -x for whole line match
  if ! grep -Fxq "$line" "$file"; then
    echo "$line" >> "$file"
  fi
}

# Detect the operating system. We primarily handle Debian‑based Linux
# distributions and macOS. Abort on other platforms.
OS="$(uname)"
case "$OS" in
  Linux)
    PLATFORM="linux"
    ;;
  Darwin)
    PLATFORM="darwin"
    ;;
  *)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

# Ensure we have a package manager and install the base dependencies.
install_base_packages_linux() {
  echo "Updating package lists and installing base packages for Linux…"
  # Determine whether sudo is available. Some environments may not have it.
  local APT="apt"
  if command -v sudo >/dev/null; then
    APT="sudo apt"
  fi
  if ! command -v apt >/dev/null; then
    echo "apt command not found; skipping package installation."
    return
  fi
  # Skip apt operations if we neither have sudo nor root privileges
  if ! command -v sudo >/dev/null && [[ $(id -u) -ne 0 ]]; then
    echo "Insufficient privileges to run apt; skipping package installation."
    return
  fi
  $APT update -y
  $APT install -y \
    curl wget git unzip \
    ripgrep shellcheck zsh tmux xclip \
    gcc make build-essential
  # Install Python tooling via pipx and apt for Python packages
  $APT install -y pipx
  pipx ensurepath
  # Python utilities – installed via pipx for consistency across platforms
  pipx install pynvim || true
  pipx install pylint || true
  # Node.js – install from NodeSource for a recent version
  if ! command -v node >/dev/null; then
    echo "Installing Node.js…"
    if command -v sudo >/dev/null; then
      curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    else
      curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    fi
    $APT install -y nodejs
  fi
  # Install npm language servers
  sudo npm install -g pyright bash-language-server tree-sitter-cli
}

install_base_packages_darwin() {
  echo "Installing base packages for macOS…"
  # Check for Homebrew and install it if missing
  if ! command -v brew >/dev/null; then
    echo "Homebrew not found; installing…"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # After installation brew may not be in PATH; add it temporarily
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || true)"
    eval "$(/usr/local/bin/brew shellenv 2>/dev/null || true)"
  fi
  brew update
  # Install packages via Homebrew
  brew install \
    curl wget git unzip \
    ripgrep shellcheck zsh tmux \
    node pipx
  # Ensure pipx’s path is activated
  pipx ensurepath
  # Install Python utilities via pipx
  pipx install pynvim || true
  pipx install pylint || true
  # Install npm language servers
  npm install -g pyright bash-language-server tree-sitter-cli
}

# Install NeoVim. On Linux we download the prebuilt tarball. On macOS we
# install via Homebrew. We then set up plugin manager, configuration
# files, and Python/Node language support.
install_neovim() {
  echo "Setting up NeoVim…"
  if [[ "$PLATFORM" == "linux" ]]; then
    # Download and extract NeoVim
    NVIM_TARBALL="nvim-linux-x86_64.tar.gz"
    curl -L -o "$NVIM_TARBALL" "https://github.com/neovim/neovim/releases/download/stable/${NVIM_TARBALL}"
    # Extract NeoVim tarball. Use sudo if available; otherwise install to
    # ~/.local instead of /opt.
    if command -v sudo >/dev/null; then
      sudo rm -rf /opt/nvim
      sudo tar -C /opt -xzf "$NVIM_TARBALL"
      NVIM_BIN="/opt/nvim-linux-x86_64/bin/nvim"
    else
      rm -rf "$HOME/.local/nvim"
      mkdir -p "$HOME/.local"
      tar -C "$HOME/.local" -xzf "$NVIM_TARBALL"
      NVIM_BIN="$HOME/.local/nvim-linux-x86_64/bin/nvim"
    fi
    rm "$NVIM_TARBALL"
  else
    # On macOS simply install via brew; brew provides the binary
    brew install neovim
    NVIM_BIN="$(brew --prefix)/bin/nvim"
  fi
  # Ensure nvim alias exists in both shells
  append_if_not_exists "$HOME/.bashrc" "alias nvim='$NVIM_BIN'"
  append_if_not_exists "$HOME/.zshrc"  "alias nvim='$NVIM_BIN'"
  # Install lazy.nvim plugin manager and copy configuration
  mkdir -p "$HOME/.config/nvim/lua/plugins"
  # Install lazy.nvim plugin manager only if it is not already present
  if [[ ! -d "$HOME/.local/share/nvim/lazy/lazy.nvim" ]]; then
    git clone https://github.com/folke/lazy.nvim "$HOME/.local/share/nvim/lazy/lazy.nvim"
  fi
  # Clone the user’s NeoVim configuration repository
  TEMP_NVIM_DIR="$(mktemp -d)"
  git clone https://github.com/kjtakke/neovim.git "$TEMP_NVIM_DIR"
  # Copy configuration files
  cp -f "$TEMP_NVIM_DIR/init.lua" "$HOME/.config/nvim/init.lua"
  mkdir -p "$HOME/.config/nvim/search"
  cp -f "$TEMP_NVIM_DIR/search/nsearch.txt" "$HOME/.config/nvim/nsearch.txt"
  cp -f "$TEMP_NVIM_DIR/lazy-lock.json" "$HOME/.config/nvim/lazy-lock.json"
  mkdir -p "$HOME/.config/nvim/lua"
  cp -f "$TEMP_NVIM_DIR/lua/cmp.lua.bak" "$HOME/.config/nvim/lua/cmp.lua.bak"
  cp -f "$TEMP_NVIM_DIR/lua/init.lua" "$HOME/.config/nvim/lua/init.lua"
  cp -f "$TEMP_NVIM_DIR/lua/lsp.lua" "$HOME/.config/nvim/lua/lsp.lua"
  mkdir -p "$HOME/.config/nvim/lua/plugins"
  cp -f "$TEMP_NVIM_DIR/lua/plugins/init.lua" "$HOME/.config/nvim/lua/plugins/init.lua"
  # Install GitHub Copilot plugin
  mkdir -p "$HOME/.config/nvim/pack/github/start"
  # Install Copilot plugin only if the directory does not already exist
  if [[ ! -d "$HOME/.config/nvim/pack/github/start/copilot.vim" ]]; then
    git clone https://github.com/github/copilot.vim.git "$HOME/.config/nvim/pack/github/start/copilot.vim"
  fi
  rm -rf "$TEMP_NVIM_DIR"
}

# Configure Zsh with Oh‑My‑Zsh, Starship, and plugins. Also configure
# Bash to use Starship. This ensures both shells benefit from similar
# prompt enhancements. For fonts, we download a Nerd Font and install it
# into the appropriate directory. Finally, we set Zsh as the default
# shell.
configure_shells() {
  echo "Configuring Zsh, Oh‑My‑Zsh, Starship, and shell plugins…"
  # Ensure zsh is available; if not, skip Zsh configuration entirely
  if ! command -v zsh >/dev/null; then
    echo "Zsh is not installed; skipping Zsh configuration."
    return
  fi
  # Install Oh‑My‑Zsh in unattended mode
  export RUNZSH=no
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
  fi
  # Install Starship prompt if available; ignore failures
  if ! command -v starship >/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y || true
  fi
  # Clone Zsh plugins into custom directory
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  mkdir -p "$ZSH_CUSTOM/plugins"
  # zsh‑autosuggestions
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" || true
  # zsh‑syntax‑highlighting
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" || true
  # fast‑syntax‑highlighting
  git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" || true
  # zsh‑autocomplete
  git clone https://github.com/marlonrichert/zsh-autocomplete.git "$ZSH_CUSTOM/plugins/zsh-autocomplete" || true
  # Prepare ~/.zshrc with desired configuration
  append_if_not_exists "$HOME/.zshrc" "export ZSH=\"$HOME/.oh-my-zsh\""
  append_if_not_exists "$HOME/.zshrc" "ZSH_THEME=\"agnoster\""
  # Set plugin list (avoid duplicates by defining the entire line). If a
  # plugins= line already exists, remove it first. On macOS sed
  # requires an argument for the extension, so use -i.bak and delete
  # the backup afterwards. On Linux -i works without a suffix.
  if grep -q '^plugins=' "$HOME/.zshrc"; then
    if [[ "$PLATFORM" == 'darwin' ]]; then
      sed -i.bak '/^plugins=/d' "$HOME/.zshrc"
      rm -f "$HOME/.zshrc.bak"
    else
      sed -i '/^plugins=/d' "$HOME/.zshrc"
    fi
  fi
  echo "plugins=(git zsh-autosuggestions fast-syntax-highlighting zsh-syntax-highlighting)" >> "$HOME/.zshrc"
  # Ensure starship initialisation appears in .zshrc and .bashrc
  append_if_not_exists "$HOME/.bashrc" 'eval "$(starship init bash)"'
  append_if_not_exists "$HOME/.zshrc" 'eval "$(starship init zsh)"'
  # Load zsh-autocomplete last
  append_if_not_exists "$HOME/.zshrc" "source $ZSH_CUSTOM/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
  # Generate starship preset configuration
  mkdir -p "$HOME/.config"
  # Generate starship preset configuration if starship is available
  if command -v starship >/dev/null; then
    starship preset gruvbox-rainbow -o "$HOME/.config/starship.toml" || true
  fi
  # Install Nerd Font (DroidSansMono) into appropriate directory
  if [[ "$PLATFORM" == "linux" ]]; then
    FONT_DIR="$HOME/.fonts"
  else
    FONT_DIR="$HOME/Library/Fonts"
  fi
  mkdir -p "$FONT_DIR"
  TEMP_FONT_DIR="$(mktemp -d)"
  FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/DroidSansMono.zip"
  curl -L -o "$TEMP_FONT_DIR/font.zip" "$FONT_URL"
  unzip -o "$TEMP_FONT_DIR/font.zip" -d "$TEMP_FONT_DIR"
  # Copy TTF files into the font directory
  find "$TEMP_FONT_DIR" -type f -name "*.ttf" -exec cp {} "$FONT_DIR" \;
  rm -rf "$TEMP_FONT_DIR"
  # Refresh font cache on Linux
  if [[ "$PLATFORM" == "linux" ]]; then
    fc-cache -fv || true
  fi
  # Set default shell to zsh for the current user
  if [[ "$SHELL" != *"zsh"* ]]; then
    if [[ "$PLATFORM" == "linux" ]]; then
      sudo chsh -s "$(command -v zsh)" "$USER"
    else
      chsh -s "$(command -v zsh)"
    fi
  fi
}

# Configure tmux and helper scripts. This downloads the user’s tmux
# configuration and helper script from GitHub and sources the helper
# script in both shell RC files. It also installs Git helper functions
# from another repository.
configure_tmux_and_git() {
  echo "Setting up tmux configuration and Git helper scripts…"
  # Fetch tmux configuration
  TMUX_TEMP="$(mktemp -d)"
  git clone https://github.com/kjtakke/tmux.git "$TMUX_TEMP"
  # Copy .tmux.conf into home directory
  cp -f "$TMUX_TEMP/.tmux.conf" "$HOME/.tmux.conf"
  # Copy tmux helper script
  cp -f "$TMUX_TEMP/tmux.sh" "$HOME/tmux_helpers.sh"
  chmod +x "$HOME/tmux_helpers.sh"
  rm -rf "$TMUX_TEMP"
  # Source tmux helpers from both shell RC files
  append_if_not_exists "$HOME/.bashrc" "source $HOME/tmux_helpers.sh"
  append_if_not_exists "$HOME/.zshrc"  "source $HOME/tmux_helpers.sh"
  # Clone Git helper scripts repository and copy the script
  GIT_HELPER_TEMP="$(mktemp -d)"
  git clone https://github.com/kjtakke/git-helper-scripts.git "$GIT_HELPER_TEMP"
  cp -f "$GIT_HELPER_TEMP/git-helper.sh" "$HOME/git-helper.sh"
  chmod +x "$HOME/git-helper.sh"
  rm -rf "$GIT_HELPER_TEMP"
  append_if_not_exists "$HOME/.bashrc" "source $HOME/git-helper.sh"
  append_if_not_exists "$HOME/.zshrc"  "source $HOME/git-helper.sh"
}

# Entrypoint for the entire installation
main() {
  if [[ "$PLATFORM" == "linux" ]]; then
    install_base_packages_linux
  else
    install_base_packages_darwin
  fi
  install_neovim
  configure_shells
  configure_tmux_and_git
  echo "\n✅ Installation complete! Please restart your terminal or source your shell configuration files to apply changes."
}

main "$@"
