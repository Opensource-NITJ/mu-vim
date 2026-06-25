#!/usr/bin/env bash

# =============================================================================
#                                INSTALL.SH
# =============================================================================
# Idempotent setup script for Linux (Ubuntu/Debian) and macOS.
# Automatically installs Neovim >= 0.10, WezTerm, Starship prompt,
# JetBrains Mono Nerd Font, Zsh, and registers XDG configuration directories.
# =============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# --- Terminal Color Definitions ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper logging functions
log_step() {
  echo -e "${BLUE}[→]${NC} $1..."
}

log_success() {
  echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
  echo -e "${RED}[!] ERROR: ${NC}$1"
}

# --- Detect Operating System ---
OS_TYPE=""
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS_TYPE="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  OS_TYPE="macos"
else
  log_error "Unsupported OS type '$OSTYPE'. Only Debian/Ubuntu and macOS are supported."
  exit 1
fi

log_step "Detected Operating System: $OS_TYPE"

# --- Detect WSL (Windows Subsystem for Linux) ---
IS_WSL=false
if [[ "$OS_TYPE" == "linux" ]] && grep -q -i "microsoft" /proc/version 2>/dev/null; then
  IS_WSL=true
  log_step "WSL Environment Detected"
fi

get_windows_home() {
  local win_home=""
  if command -v cmd.exe &>/dev/null; then
    local win_home_raw
    win_home_raw=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')
    if [ -n "$win_home_raw" ] && command -v wslpath &>/dev/null; then
      win_home=$(wslpath "$win_home_raw")
    fi
  fi
  if [ -z "$win_home" ]; then
    if [ -d "/mnt/c/Users/$USER" ]; then
      win_home="/mnt/c/Users/$USER"
    else
      for dir in /mnt/c/Users/*; do
        if [ -d "$dir" ]; then
          local base
          base=$(basename "$dir")
          if [ "$base" != "Public" ] && [ "$base" != "Default" ] && [ "$base" != "All Users" ] && [ "$base" != "desktop.ini" ]; then
            win_home="$dir"
            break
          fi
        fi
      done
    fi
  fi
  echo "$win_home"
}

get_windows_localappdata() {
  local win_lad=""
  if command -v cmd.exe &>/dev/null; then
    local win_lad_raw
    win_lad_raw=$(cmd.exe /c "echo %LOCALAPPDATA%" 2>/dev/null | tr -d '\r')
    if [ -n "$win_lad_raw" ] && command -v wslpath &>/dev/null; then
      win_lad=$(wslpath "$win_lad_raw")
    fi
  fi
  if [ -z "$win_lad" ]; then
    local win_home
    win_home=$(get_windows_home)
    if [ -n "$win_home" ]; then
      win_lad="$win_home/AppData/Local"
    fi
  fi
  echo "$win_lad"
}


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

if [[ "$OS_TYPE" == "linux" ]]; then
  # Ensure we are running on Ubuntu or Debian
  if ! [ -f /etc/debian_version ]; then
    log_error "mu-vim installer only supports Debian/Ubuntu based distributions on Linux."
    exit 1
  fi

  log_step "Updating package lists (requires sudo)"
  # Clean up any previously added broken neovim PPAs that would cause update to fail
  sudo rm -f /etc/apt/sources.list.d/neovim-ppa-*
  sudo apt-get update -y

  # Install Git, Curl, Unzip, Zsh, and add-apt-repository support
  log_step "Installing git, curl, unzip, zsh, software-properties-common, build-essential, clang, nodejs, npm"
  sudo apt-get install -y git curl unzip zsh software-properties-common build-essential clang nodejs npm
  # Install Neovim >= 0.10
  log_step "Checking Neovim installation"
  IS_NEOVIM_OK=false
  if command -v nvim &> /dev/null; then
    NVIM_VERSION=$(nvim --version | head -n 1 | awk '{print $2}' | sed 's/v//')
    # Compare Neovim version to 0.10
    if awk -v ver="$NVIM_VERSION" 'BEGIN { exit (ver >= 0.10) ? 0 : 1 }'; then
      log_success "Compatible Neovim v$NVIM_VERSION already installed"
      IS_NEOVIM_OK=true
    fi
  fi

  if [ "$IS_NEOVIM_OK" = false ]; then
    log_step "Installing Neovim >= 0.10"
    # Detect if Ubuntu or pure Debian
    if grep -q "Ubuntu" /etc/os-release; then
      log_step "Adding Neovim stable PPA"
      if ! sudo add-apt-repository -y ppa:neovim-ppa/stable || ! sudo apt-get update -y || ! sudo apt-get install -y neovim; then
        log_warn "Neovim PPA unavailable or failed. Falling back to pre-built binary."
        # Clean up potentially broken PPA list
        sudo rm -f /etc/apt/sources.list.d/neovim-ppa-*
        sudo apt-get update -y || true
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
        sudo tar -C /usr/local -xzf nvim-linux-x86_64.tar.gz --strip-components=1
        rm nvim-linux-x86_64.tar.gz
      fi
    else
      # Debian fallback: Install pre-built stable binary
      log_step "Installing pre-built Neovim binary for Debian"
      curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
      sudo tar -C /usr/local -xzf nvim-linux-x86_64.tar.gz --strip-components=1
      rm nvim-linux-x86_64.tar.gz
    fi
    log_success "Neovim installed successfully"
  fi

  # Install WezTerm
  if [ "$IS_WSL" = true ]; then
    log_step "WSL environment: Skipping Linux-side WezTerm installation (runs on Windows host)"
  else
    if ! command -v wezterm &> /dev/null; then
      log_step "Installing WezTerm via apt repository"
      curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
      echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
      sudo apt-get update -y
      sudo apt-get install -y wezterm
      log_success "WezTerm installed successfully"
    else
      log_success "WezTerm already installed"
    fi
  fi

  # Install JetBrains Mono Nerd Font
  FONT_DIR="$HOME/.local/share/fonts"
  if [ ! -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]; then
    log_step "Downloading & installing JetBrains Mono Nerd Font"
    mkdir -p "$FONT_DIR"
    TEMP_DIR=$(mktemp -d)
    curl -L -o "$TEMP_DIR/font.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    unzip -o "$TEMP_DIR/font.zip" -d "$FONT_DIR"
    rm -rf "$TEMP_DIR"
    # Rebuild font cache
    fc-cache -f
    log_success "JetBrains Mono Nerd Font installed"
  else
    log_success "JetBrains Mono Nerd Font already installed"
  fi

  # Install Starship Prompt
  if ! command -v starship &> /dev/null; then
    log_step "Installing Starship prompt"
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    log_success "Starship prompt installed"
  else
    log_success "Starship prompt already installed"
  fi

  # Install Zsh completion and highlighting dependencies
  log_step "Installing Zsh Autosuggestions and Syntax Highlighting"
  sudo apt-get install -y zsh-autosuggestions zsh-syntax-highlighting
  log_success "Zsh modules installed"

elif [[ "$OS_TYPE" == "macos" ]]; then
  # Ensure Homebrew is installed
  if ! command -v brew &> /dev/null; then
    log_step "Homebrew not found. Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  log_step "Updating Homebrew formulae"
  brew update

  log_step "Installing git, curl, unzip, zsh, neovim, starship"
  brew install git curl unzip zsh neovim starship

  # Install Zsh autosuggestions & syntax highlighting
  brew install zsh-autosuggestions zsh-syntax-highlighting

  # Install WezTerm
  if ! command -v wezterm &> /dev/null; then
    log_step "Installing WezTerm via Homebrew cask"
    brew install --cask wezterm
  fi

  # Install Nerd Fonts
  log_step "Installing JetBrains Mono Nerd Font"
  brew tap homebrew/cask-fonts || true
  brew install --cask font-jetbrains-mono-nerd-font
  log_success "Dependencies installed via Homebrew"
fi

# --- PLACE CONFIGURATION FILES ---

log_step "Configuring applications"

# 1. Neovim configuration
create_backup "$HOME/.config/nvim" "Neovim"
mkdir -p "$HOME/.config"
cp -r nvim "$HOME/.config/nvim"
# Ensure the stable version lockfile is in place
if [[ -f "lazy-lock.json" ]]; then
  cp lazy-lock.json "$HOME/.config/nvim/lazy-lock.json"
fi
log_success "Neovim configuration copied to ~/.config/nvim/"

# 2. WezTerm configuration
if [ "$IS_WSL" = true ]; then
  win_home=$(get_windows_home)
  if [ -n "$win_home" ]; then
    log_step "WSL detected: Configuring WezTerm on Windows host side"
    win_config_dir="$win_home/.config/wezterm"
    win_config_file="$win_config_dir/wezterm.lua"
    win_legacy_file="$win_home/.wezterm.lua"
    
    # Backup existing Windows configs
    create_backup "$win_config_file" "Windows WezTerm (XDG)"
    create_backup "$win_legacy_file" "Windows WezTerm (Legacy)"
    
    mkdir -p "$win_config_dir"
    
    wsl_distro="${WSL_DISTRO_NAME:-Ubuntu}"
    sed "s/-- config.default_domain = 'WSL:Ubuntu'/config.default_domain = 'WSL:$wsl_distro'/" wezterm/.wezterm.lua > "$win_config_file"
    
    # Check if host has a Radeon GPU
    has_radeon=false
    if command -v powershell.exe &>/dev/null; then
      if powershell.exe -NoProfile -Command "Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name" 2>/dev/null | grep -q -i "radeon"; then
        has_radeon=true
      fi
    fi

    if [ "$has_radeon" = true ]; then
      log_success "Radeon GPU detected: Configuring background image for WezTerm"
      # Copy background image
      if [ -f "assets/image.png" ]; then
        cp "assets/image.png" "$win_config_dir/image.png"
        cp "assets/image.png" "$win_home/image.png"
      fi
      # Insert background image settings before 'return config'
      sed -i '/return config/d' "$win_config_file"
      cat << 'EOF' >> "$win_config_file"
config.background = {
  {
    source = {
      File = wezterm.config_dir .. "/image.png",
    },
    opacity = 0.15,
  },
}

return config
EOF
    else
      log_success "Non-Radeon GPU detected: Utilizing transparent/translucent theme"
    fi

    log_success "WezTerm configuration copied & optimized for Windows host: $win_config_file"
    cp "$win_config_file" "$win_legacy_file"
    log_success "WezTerm configuration fallback copied to legacy path: $win_legacy_file"

    # Create "muvim" launcher command on Windows host side in Microsoft/WindowsApps
    win_lad=$(get_windows_localappdata)
    if [ -n "$win_lad" ]; then
      win_apps_dir="$win_lad/Microsoft/WindowsApps"
      if [ -d "$win_apps_dir" ]; then
        log_step "Creating 'muvim' command on Windows host side"
        cat <<EOF > "$win_apps_dir/muvim.cmd"
@echo off
rem Launch muvim inside WSL Ubuntu via WezTerm GUI or direct wsl terminal
if defined WEZTERM_PANE (
    wsl -d $wsl_distro nvim %*
) else (
    where wezterm >nul 2>nul
    if %ERRORLEVEL% equ 0 (
        start "" wezterm start -- cmd.exe /c wsl -d $wsl_distro nvim %*
    ) else (
        wsl -d $wsl_distro nvim %*
    )
)
EOF
        log_success "Created 'muvim' command on Windows host at: $win_apps_dir/muvim.cmd"
      else
        log_warn "Could not locate WindowsApps directory. Skipping 'muvim' host launcher."
      fi
    else
      log_warn "Could not locate Windows LocalAppData directory. Skipping 'muvim' host launcher."
    fi
  else
    log_warn "Could not locate Windows user profile directory. Skipping Windows-side WezTerm configuration."
  fi
else
  create_backup "$HOME/.config/wezterm" "WezTerm (XDG)"
  create_backup "$HOME/.wezterm.lua" "WezTerm (Legacy)"
  mkdir -p "$HOME/.config/wezterm"
  cp wezterm/.wezterm.lua "$HOME/.config/wezterm/wezterm.lua"
  
  # macOS backup fallback support
  if [[ "$OS_TYPE" == "macos" ]]; then
    # Symlink to ~/.wezterm.lua as a fallback just in case
    ln -sf "$HOME/.config/wezterm/wezterm.lua" "$HOME/.wezterm.lua"
  fi
  log_success "WezTerm configuration copied to ~/.config/wezterm/wezterm.lua"
fi

# 3. Zsh configuration
create_backup "$HOME/.zshrc" "Zsh"
cp zsh/.zshrc "$HOME/.zshrc"
log_success "Zsh configuration copied to ~/.zshrc"

# 4. Create muvim command inside the distro
log_step "Creating 'muvim' shortcut inside the distro"
sudo ln -sf "$(command -v nvim)" /usr/local/bin/muvim || {
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v nvim)" "$HOME/.local/bin/muvim"
}
log_success "Shortcut 'muvim' created inside the distro"

# --- INSTALL COMPLETED ---

echo -e "\n========================================================================="
echo -e "                   ${GREEN}μ-VIM INSTALLATION COMPLETED!${NC}"
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
