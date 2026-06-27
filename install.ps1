# =============================================================================
#                               INSTALL.PS1
# =============================================================================
# Idempotent PowerShell setup script for native Windows environments.
# Requires PowerShell 7+. Installs Scoop, Neovim, Git, Node.js, Python,
# MinGW (gcc/g++), CMake, Starship, JetBrains Mono Nerd Font, and WezTerm.
# =============================================================================

# --- 1. Version Guard ---
# Ensure PowerShell 7+ (pwsh) is running (mu-vim does not support Windows PowerShell 5.1).
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "[!] ERROR: mu-vim installation requires PowerShell 7+." -ForegroundColor Red
    Write-Host "Please download and install the latest PowerShell version from:" -ForegroundColor Yellow
    Write-Host "https://github.com/PowerShell/PowerShell/releases" -ForegroundColor Blue
    Exit
}

# --- 2. Indicators and Output Helpers ---
function Log-Step ($message) {
    Write-Host "[→] $message..." -ForegroundColor Cyan
}

function Log-Success ($message) {
    Write-Host "[✓] $message" -ForegroundColor Green
}

function Log-Warn ($message) {
    Write-Host "[!] $message" -ForegroundColor Yellow
}

function Log-Error ($message) {
    Write-Host "[!] ERROR: $message" -ForegroundColor Red
}

Log-Step "Starting native Windows installer (PowerShell 7+)"

# --- 3. Define Backup Location ---
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $env:USERPROFILE "mu-vim-backup\$timestamp"

function Create-Backup ($targetPath, $name) {
    if (Test-Path $targetPath) {
        if (!(Test-Path $backupDir)) {
            $null = New-Item -Path $backupDir -ItemType Directory -Force
        }
        Log-Warn "Existing $name configuration found. Backing up to $backupDir"
        Move-Item -Path $targetPath -Destination $backupDir -Force
    }
}

# --- 4. Install Scoop (runs in user-space, no admin/UAC required) ---
if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
    Log-Step "Scoop not found. Installing Scoop"
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    if (!(Test-Path "$env:USERPROFILE\scoop")) {
        Log-Error "Scoop installation failed. Aborting."
        Exit
    }
    # Ensure Scoop shims are in PATH for this session
    $scoopShims = "$env:USERPROFILE\scoop\shims"
    if ($env:PATH -notlike "*$scoopShims*") {
        $env:PATH = "$scoopShims;$env:PATH"
    }
    Log-Success "Scoop installed successfully"
} else {
    Log-Success "Scoop already installed"
}

# --- 5. Add standard Scoop buckets ---
Log-Step "Adding Scoop buckets (extras, nerd-fonts)"
scoop bucket add extras 2>$null
scoop bucket add nerd-fonts 2>$null
Log-Success "Scoop buckets ready"

# --- 6. Install Git first (required for repo cloning below) ---
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Log-Step "Installing git via Scoop"
    scoop install git
    Log-Success "git installed"
} else {
    Log-Success "git already installed"
}

# --- 7. Detect or clone source repository ---
# $PSScriptRoot is set when running from a file, but empty when piped via irm | iex.
# If the nvim source files are not present locally, clone the repo to a temp directory.
$sourceDir = $PSScriptRoot
if (!$sourceDir -or !(Test-Path (Join-Path $sourceDir "nvim\init.lua"))) {
    Log-Step "Source files not found locally. Cloning mu-vim repository"
    $cloneTarget = Join-Path $env:TEMP "mu-vim-$timestamp"
    git clone --depth 1 "https://github.com/Opensource-NITJ/mu-vim.git" $cloneTarget
    if ($LASTEXITCODE -ne 0 -or !(Test-Path (Join-Path $cloneTarget "nvim\init.lua"))) {
        Log-Error "Repository clone failed. Check your internet connection and try again."
        Exit
    }
    $sourceDir = $cloneTarget
    Log-Success "Repository cloned to $cloneTarget"
} else {
    Log-Success "Using local source files from $sourceDir"
}

# --- 8. Install tools via Scoop ---
# Mapping: scoop package name -> command used to detect if already installed
$scoopPackages = [ordered]@{
    "neovim"  = "nvim"
    "nodejs"  = "node"      # Required by Copilot, Mason LSPs (pyright, bashls)
    "python"  = "python"    # Required for Python code runner and DAP debugpy
    "starship" = "starship"
    "cmake"   = "cmake"     # Required to build telescope-fzf-native on Windows
    "mingw"   = "gcc"       # Provides gcc, g++, and make for C/C++ compilation
}

foreach ($pkg in $scoopPackages.Keys) {
    $cmd = $scoopPackages[$pkg]
    if (!(Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Log-Step "Installing $pkg via Scoop"
        scoop install $pkg
        if ($LASTEXITCODE -ne 0) {
            Log-Warn "$pkg installation may have failed. Some features may not work."
        } else {
            Log-Success "$pkg installed"
        }
    } else {
        Log-Success "$pkg already installed"
    }
}

# Install JetBrains Mono Nerd Font via Scoop nerd-fonts bucket
if (!(Test-Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\JetBrainsMonoNerdFont*")) {
    Log-Step "Installing JetBrainsMono Nerd Font via Scoop"
    scoop install JetBrainsMono-NF
    Log-Success "JetBrainsMono Nerd Font installed"
} else {
    Log-Success "JetBrainsMono Nerd Font already installed"
}

# --- 9. Install WezTerm via winget (Windows Package Manager) ---
if (!(Get-Command wezterm -ErrorAction SilentlyContinue)) {
    Log-Step "Installing WezTerm via winget"
    winget install --id wez.wezterm --silent --accept-source-agreements --accept-package-agreements
    Log-Success "WezTerm installed"
} else {
    Log-Success "WezTerm already installed"
}

# --- 10. Place Configuration Files ---
Log-Step "Copying configurations to Windows directories"

# 1. Copy Neovim configs to %LOCALAPPDATA%\nvim\
$nvimConfigDir = Join-Path $env:LOCALAPPDATA "nvim"
Create-Backup $nvimConfigDir "Neovim"
$null = New-Item -Path $nvimConfigDir -ItemType Directory -Force
Copy-Item -Path "$sourceDir\nvim\*" -Destination $nvimConfigDir -Recurse -Force
if (Test-Path "$sourceDir\lazy-lock.json") {
    Copy-Item -Path "$sourceDir\lazy-lock.json" -Destination (Join-Path $nvimConfigDir "lazy-lock.json") -Force
}
Log-Success "Neovim config placed at $nvimConfigDir"

# 2. Copy WezTerm config to %USERPROFILE%\.config\wezterm\wezterm.lua
$weztermConfigDir = Join-Path $env:USERPROFILE ".config\wezterm"
Create-Backup $weztermConfigDir "WezTerm"
$null = New-Item -Path $weztermConfigDir -ItemType Directory -Force
Copy-Item -Path "$sourceDir\wezterm\.wezterm.lua" -Destination (Join-Path $weztermConfigDir "wezterm.lua") -Force

# Windows fallback path: %USERPROFILE%\.wezterm.lua
$weztermFallback = Join-Path $env:USERPROFILE ".wezterm.lua"
Create-Backup $weztermFallback "WezTerm (Legacy Fallback)"
Copy-Item -Path "$sourceDir\wezterm\.wezterm.lua" -Destination $weztermFallback -Force
Log-Success "WezTerm config placed at $weztermConfigDir"

# 3. Configure PowerShell Profile
$profileDir = Split-Path $PROFILE -Parent
if (!(Test-Path $profileDir)) {
    $null = New-Item -Path $profileDir -ItemType Directory -Force
}
Create-Backup $PROFILE "PowerShell Profile"
Copy-Item -Path "$sourceDir\powershell\profile.ps1" -Destination $PROFILE -Force
Log-Success "PowerShell profile placed at $PROFILE"

# --- 11. End Checklist ---
Write-Host ""
Write-Host "=========================================================================" -ForegroundColor Green
Write-Host "                   μ-VIM INSTALLATION COMPLETED!" -ForegroundColor Green
Write-Host "=========================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "To complete setup, follow this checklist:" -ForegroundColor White
Write-Host ""
Write-Host " [→] Restart your terminal (or run '. `$PROFILE') to reload PATH changes." -ForegroundColor Cyan
Write-Host " [→] Start Neovim to let lazy.nvim download and compile all plugins:" -ForegroundColor Cyan
Write-Host "     nvim" -ForegroundColor Yellow
Write-Host " [→] Open Mason inside Neovim to verify LSP installations:" -ForegroundColor Cyan
Write-Host "     Launch nvim, then type: :Mason" -ForegroundColor Yellow
Write-Host " [→] Set up GitHub Copilot:" -ForegroundColor Cyan
Write-Host "     Launch nvim, run: :Copilot auth" -ForegroundColor Yellow
Write-Host "     Toggle Copilot suggestions with: <leader>cp" -ForegroundColor Yellow
Write-Host " [→] C/C++ compilation uses MinGW gcc/g++ (installed via Scoop)." -ForegroundColor Cyan
Write-Host "     Run 'gcc --version' to verify it is available." -ForegroundColor Yellow
Write-Host ""
Write-Host "Enjoy your new developer environment!" -ForegroundColor Green
Write-Host ""
