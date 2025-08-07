# Developer Setup Scripts

This repository provides two scripts for quickly setting up a modern terminal‑based development environment on either Debian/Mint or macOS. Both scripts install NeoVim, Zsh with Oh My Zsh, Starship, Tmux, language servers, Nerd Fonts and a collection of useful helper functions.

## Contents

| Script | Purpose | Use when… |
| --- | --- | --- |
| **install.sh** | Clones your configuration repositories and installs all required packages. Uses the `git` command to fetch your NeoVim, tmux and helper scripts from GitHub. | You are happy to use `git` for configuration and want the latest versions of your own repositories. |
| **install_nogit.sh** | Performs the same setup without relying on `git`. Instead it downloads individual files via `curl` and extracts plugin archives. This is useful on systems where `git` is unavailable or you prefer not to run `git` during installation. | You need a fully self‑contained installer that does not invoke `git`. |

Both scripts work on:

- **Debian‑based Linux distributions** (e.g. Ubuntu, Linux Mint) using `apt` for package management.
    
- **macOS** using Homebrew (`brew`) for package management.
    

## Features

- **NeoVim**: Installs the latest stable release of NeoVim and configures it with your settings and plugins.
    
- **Zsh and Oh My Zsh**: Installs Zsh, Oh My Zsh and a curated set of plugins including auto‑suggestions, syntax highlighting and autocomplete.
    
- **Starship prompt**: Configures a colourful, informative prompt across both Bash and Zsh using Starship[starship.rs](https://starship.rs/#:~:text=1).
    
- **Language servers**: Installs Python support (`pynvim`) and a set of LSP servers such as `pyright`, `bash-language-server` and `tree-sitter-cli` via npm.
    
- **Nerd Fonts**: Downloads and installs the Droid Sans Mono Nerd Font for powerline and glyph support.
    
- **Tmux**: Provides a basic `.tmux.conf` and a helper script for creating, attaching and killing sessions.
    
- **Git helper functions**: Makes available a rich collection of custom Git commands and aliases to simplify everyday workflows.
    

## Prerequisites

- A supported operating system (Debian/Mint or macOS).
    
- Administrator privileges (the scripts use `sudo` on Linux and Homebrew on macOS).
    
- An active internet connection to download packages and configuration files.
    

## Usage

Clone this repository or download the script you wish to run. Then execute it using Bash:

```bash
# For the git‑based installer
bash install.sh
# For the no‑git installer
bash install_nogit.sh`
```
Alternatively, you can fetch `install.sh` via `curl` and pipe it to Bash in one step:

```bash
`curl -sSL https://raw.githubusercontent.com/kjtakke/developer-setup/main/install.sh | bash`
```
After the script completes, restart your terminal session or reload your shell configuration (`source ~/.bashrc` or `source ~/.zshrc`) to apply the changes.

## How it works

1.  **Package installation** – The script detects your OS and uses either `apt` (on Linux) or `brew` (on macOS) to install core utilities such as `ripgrep`, `pylint`, `shellcheck`, `tmux`, `node` and `pipx`. It also installs Python support for NeoVim via `pipx`.
    
2.  **NeoVim setup** – The latest NeoVim build is downloaded. Configuration files (`init.lua`, `lazy-lock.json` and Lua modules) are either cloned from your repository or downloaded via `curl`, depending on the script. The Lazy.nvim plugin manager is installed without using `git`.
    
3.  **Shell environment** – Zsh and Oh My Zsh are installed along with Starship. Plugins for auto‑suggestions, syntax highlighting and autocomplete are downloaded as tarballs when using `install_nogit.sh`. The script updates `.zshrc` and `.bashrc` to include `~/bin` in `PATH`, source the helper scripts and initialise Starship.
    
4.  **Helper functions** – Git helper functions and tmux helpers are stored under `~/bin` and sourced automatically. You can run `git-help` for a summary of available Git commands.
    

## Updating and Re‑running

Both scripts are idempotent. Running them multiple times will not duplicate lines in your shell configuration. You can re‑run the scripts to pick up updates to your configuration or to ensure packages are installed on a new machine.

## Licence

### MIT Licence

This project is released under the MIT licence. In keeping with the permissive nature of the licence, you may use, copy, modify and distribute the scripts for any purpose, including commercial use, provided that the following conditions are met:

```vbnet
MIT LicenseCopyright (c) 2025 kjtakkePermission is hereby granted, free of charge, to any person obtaining a copyof this software and associated documentation files (the “Software”), to dealin the Software without restriction, including without limitation the rightsto use, copy, modify, merge, publish, distribute, sublicense, and/or sellcopies of the Software, and to permit persons to whom the Software isfurnished to do so, subject to the following conditions:The above copyright notice and this permission notice shall be included inall copies or substantial portions of the Software.THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS ORIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THEAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHERLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS INTHE SOFTWARE.`
```

The full text of the MIT licence above is provided as a convenience. By  
including the copyright notice and permission terms in your redistributions,  
you satisfy the legal requirements of the licence. For more information  
about the licence, refer to the official MIT licence documentation.
