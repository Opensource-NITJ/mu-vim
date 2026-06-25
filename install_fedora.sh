#!/usr/bin/env bash
# =============================================================================
# INSTALL-FEDORA.SH
# =============================================================================
# Unofficial Fedora/RHEL-family port of mu-vim's install_ubuntu.sh
# (https://github.com/Opensource-NITJ/mu-vim). Upstream only supports
# Debian/Ubuntu and macOS, so this re-implements the same steps using dnf.
# Tested logic for: Fedora. Should also work on RHEL/CentOS/Rocky/Alma
# once EPEL is enabled (see EPEL note below) — COPR may not be available
# on pure RHEL without the `copr` dnf plugin / subscription access.
# =============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log_step()    { echo -e "${BLUE}[→]${NC} $1..."; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
log_error()   { echo -e "${RED}[!] ERROR: ${NC}$1"; }

# --- Detect Operating System ---
if [ ! -f /etc/redhat-release ] && [ ! -f /etc/fedora-release ]; then
    log_error "This script is for Fedora/RHEL-family distros only (no /etc/redhat-release or /etc/fedora-release found)."
    exit 1
fi
DISTRO_NAME=$(cat /etc/fedora-release 2>/dev/null || cat /etc/redhat-release)
log_step "Detected: $DISTRO_NAME"

# --- Define Backup Directories ---
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/.config/mu-vim-backup/$TIMESTAMP"

create_backup() {
    local target_path=$1
    local name=$2
    if [[ -e "$target_path" || -L "$target_path" ]]; then
        mkdir -p "$BACKUP_DIR"
        log_warn "Existing $name configuration found at $target_path. Backing up to $BACKUP_DIR/"
        mv "$target_path" "$BACKUP_DIR/"
    fi
}

# --- INSTALL DEPENDENCIES ---
log_step "Refreshing dnf metadata (requires sudo)"
sudo dnf makecache -y

log_step "Installing git, curl, unzip, zsh, dnf-plugins-core"
sudo dnf install -y git curl unzip zsh dnf-plugins-core

# --- Neovim >= 0.10 ---
log_step "Checking Neovim installation"
IS_NEOVIM_OK=false
if command -v nvim &> /dev/null; then
    NVIM_VERSION=$(nvim --version | head -n 1 | awk '{print $2}' | sed 's/v//')
    if awk -v ver="$NVIM_VERSION" 'BEGIN { exit (ver >= 0.10) ? 0 : 1 }'; then
        log_success "Compatible Neovim v$NVIM_VERSION already installed"
        IS_NEOVIM_OK=true
    fi
fi

if [ "$IS_NEOVIM_OK" = false ]; then
    log_step "Installing Neovim via dnf"
    sudo dnf install -y neovim
    # Fedora's repo is usually current enough; if it's still too old
    # (e.g. on RHEL/CentOS), fall back to the prebuilt upstream binary.
    NVIM_VERSION=$(nvim --version | head -n 1 | awk '{print $2}' | sed 's/v//')
    if ! awk -v ver="$NVIM_VERSION" 'BEGIN { exit (ver >= 0.10) ? 0 : 1 }'; then
        log_warn "dnf's neovim ($NVIM_VERSION) is too old. Installing prebuilt binary instead."
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
        sudo tar -C /usr/local -xzf nvim-linux-x86_64.tar.gz --strip-components=1
        rm nvim-linux-x86_64.tar.gz
    fi
    log_success "Neovim installed successfully"
fi

# --- WezTerm (via COPR) ---
if ! command -v wezterm &> /dev/null; then
    log_step "Installing WezTerm via COPR (wezfurlong/wezterm-nightly)"
    sudo dnf copr enable -y wezfurlong/wezterm-nightly
    sudo dnf install -y wezterm || sudo dnf install -y wezterm-common wezterm-mux-server
    if ! command -v wezterm &> /dev/null; then
        log_warn "wezterm binary still missing after install — try 'sudo dnf install wezterm-common' manually."
    else
        log_success "WezTerm installed successfully"
    fi
else
    log_success "WezTerm already installed"
fi

# --- JetBrains Mono Nerd Font ---
FONT_DIR="$HOME/.local/share/fonts"
if [ ! -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]; then
    log_step "Downloading & installing JetBrains Mono Nerd Font"
    mkdir -p "$FONT_DIR"
    TEMP_DIR=$(mktemp -d)
    curl -L -o "$TEMP_DIR/font.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    unzip -o "$TEMP_DIR/font.zip" -d "$FONT_DIR"
    rm -rf "$TEMP_DIR"
    fc-cache -f
    log_success "JetBrains Mono Nerd Font installed"
else
    log_success "JetBrains Mono Nerd Font already installed"
fi

# --- Starship Prompt ---
if ! command -v starship &> /dev/null; then
    log_step "Installing Starship prompt"
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    log_success "Starship prompt installed"
else
    log_success "Starship prompt already installed"
fi

# --- Zsh autosuggestions / syntax highlighting ---
# Native on Fedora. On RHEL/CentOS/Rocky/Alma you likely need EPEL first:
#   sudo dnf install -y epel-release
log_step "Installing Zsh Autosuggestions and Syntax Highlighting"
sudo dnf install -y zsh-autosuggestions zsh-syntax-highlighting
log_success "Zsh modules installed"

# --- CLONE mu-vim SOURCE (so we have the config files to copy) ---
SRC_DIR="$(mktemp -d)/mu-vim"
log_step "Cloning mu-vim configuration source"
git clone --depth 1 https://github.com/Opensource-NITJ/mu-vim "$SRC_DIR"
cd "$SRC_DIR"

# --- PLACE CONFIGURATION FILES ---
log_step "Configuring applications"

# 1. Neovim configuration
create_backup "$HOME/.config/nvim" "Neovim"
mkdir -p "$HOME/.config"
cp -r nvim "$HOME/.config/nvim"
if [[ -f "lazy-lock.json" ]]; then
    cp lazy-lock.json "$HOME/.config/nvim/lazy-lock.json"
fi
log_success "Neovim configuration copied to ~/.config/nvim/"

# 2. WezTerm configuration
create_backup "$HOME/.config/wezterm" "WezTerm (XDG)"
create_backup "$HOME/.wezterm.lua" "WezTerm (Legacy)"
mkdir -p "$HOME/.config/wezterm"
cp wezterm/.wezterm.lua "$HOME/.config/wezterm/wezterm.lua"
log_success "WezTerm configuration copied to ~/.config/wezterm/wezterm.lua"

# 3. Zsh configuration
create_backup "$HOME/.zshrc" "Zsh"
cp zsh/.zshrc "$HOME/.zshrc"
log_success "Zsh configuration copied to ~/.zshrc"

# --- INSTALL COMPLETED ---
echo -e "\n========================================================================="
echo -e " ${GREEN}μ-VIM (Fedora/RHEL) INSTALLATION COMPLETED!${NC}"
echo -e "=========================================================================\n"
echo -e "To complete setting up, review this manual checklist:\n"
echo -e " ${BLUE}[→]${NC} ${YELLOW}Set Zsh as default shell${NC} (if you haven't already):"
echo -e "     chsh -s \$(which zsh)"
echo -e " ${BLUE}[→]${NC} ${YELLOW}Start Neovim${NC} to let lazy.nvim load and compile plugins:"
echo -e "     nvim"
echo -e " ${BLUE}[→]${NC} ${YELLOW}Open Mason (LSP Manager)${NC} inside Neovim and run installations:"
echo -e "     Launch nvim, then type: :Mason"
echo -e " ${BLUE}[→]${NC} ${YELLOW}Learn Neovim keys${NC}:"
echo -e "     Run 'vimtutor' in your terminal or use Vim Tutor Mode in Neovim."
echo -e " ${BLUE}[→]${NC} ${YELLOW}Setup GitHub Copilot${NC}:"
echo -e "     Launch nvim, run: :Copilot auth"
echo -e "     Enable copilot suggestions temporarily with: <leader>cp"
echo -e "\nEnjoy your new developer environment!\n"
