# =============================================================================
#                                 .ZSHRC
# =============================================================================
# A minimal, framework-less, and heavily commented zsh configuration.
# Designed for speed, reliability, and helpful editing defaults.
#
# Linked tools: Starship prompt, Zsh Autosuggestions, Zsh Syntax Highlighting.
# =============================================================================

# --- 1. History Settings ---
# Save command history so you can search through previously run commands.
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory      # Append history to file rather than overwrite
setopt sharehistory       # Share command history across all active shells
setopt histignorealldups  # Ignore duplicate commands in history listing
setopt histignorespace    # Ignore commands starting with a space (keeps passwords private)

# --- 2. Key Bindings ---
# Use standard Emacs key bindings in shell (allows Ctrl+A to go to line start, Ctrl+E to end, etc.)
bindkey -e

# --- 3. Autocompletion System ---
# Set up default shell autocomplete behaviors.
autoload -Uz compinit
compinit -d ~/.zcompdump
zstyle ':completion:*' menu select # Use visual select menu for autocomplete tabs
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case-insensitive autocomplete matching

# --- 4. Shell Aliases ---
# Aliasing vim/vi to Neovim. Crucial helper so you always launch Neovim!
alias vim="nvim"
alias vi="nvim"
alias v="nvim"

# Common quick commands
alias ll="ls -lah"
alias la="ls -A"
alias l="ls -CF"
alias gs="git status"

# --- 5. Starship Prompt Initialization ---
# Starship is a customizable, ultra-fast prompt for any shell.
# It is auto-installed by the mu-vim installation scripts.
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# --- 6. Autosuggestions & Syntax Highlighting ---
# Attempts to load Zsh Autosuggestions and Syntax Highlighting by detecting
# standard package paths on Linux (apt) and macOS (brew).
# To enable these, make sure they are installed via your package manager.

# Standard paths to search for plugins
local autosuggest_paths=(
  "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"                # Ubuntu/Debian
  "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"        # macOS (M1/M2/M3)
  "/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh"          # macOS (Intel)
)

local highlight_paths=(
  "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"        # Ubuntu/Debian
  "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" # macOS (M1/M2/M3)
  "/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"  # macOS (Intel)
)

# Source Autosuggestions if found
for p in $autosuggest_paths; do
  if [[ -f "$p" ]]; then
    source "$p"
    break
  fi
done

# Source Syntax Highlighting if found
for p in $highlight_paths; do
  if [[ -f "$p" ]]; then
    source "$p"
    break
  fi
done

# --- 7. Environment Variables ---
# Set Neovim as the default text editor for git commits, visual editing, etc.
export EDITOR="nvim"
export VISUAL="nvim"

# Add custom/local binary paths if they exist
if [[ -d "$HOME/.local/bin" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi
