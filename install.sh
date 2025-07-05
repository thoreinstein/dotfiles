#!/usr/bin/env bash

#############################################
# Dotfiles Installation Script
# 
# This script automates the setup of a macOS
# development environment with modern CLI tools
#############################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_REPO="git@github.com:thoreinstein/dotfiles.git"
DOTFILES_REPO_HTTPS="https://github.com/thoreinstein/dotfiles.git"
DOTFILES_DIR="$HOME/src/thoreinstein/dotfiles"
WORK_TREE="main"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
check_os() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi
    log_success "Running on macOS"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Homebrew
install_homebrew() {
    if command_exists brew; then
        log_info "Homebrew is already installed"
        return
    fi

    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH based on architecture
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        # Apple Silicon
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        # Intel
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    log_success "Homebrew installed successfully"
}

# Clone dotfiles repository
clone_dotfiles() {
    if [[ -d "$DOTFILES_DIR" ]]; then
        log_info "Dotfiles directory already exists at $DOTFILES_DIR"
        return
    fi

    log_info "Creating dotfiles directory structure..."
    mkdir -p "$(dirname "$DOTFILES_DIR")"

    log_info "Cloning dotfiles repository..."
    # Try SSH first, fall back to HTTPS
    if git clone "$DOTFILES_REPO" "$DOTFILES_DIR" 2>/dev/null; then
        log_success "Cloned repository using SSH"
    else
        log_warning "SSH clone failed, trying HTTPS..."
        if git clone "$DOTFILES_REPO_HTTPS" "$DOTFILES_DIR"; then
            log_success "Cloned repository using HTTPS"
            log_warning "You may want to switch to SSH later for easier pushing"
        else
            log_error "Failed to clone repository"
            exit 1
        fi
    fi

    # Set up worktree
    cd "$DOTFILES_DIR"
    if [[ ! -d "$WORK_TREE" ]]; then
        git worktree add "$WORK_TREE"
        log_success "Created worktree '$WORK_TREE'"
    fi
}

# Install packages from Brewfile
install_brew_packages() {
    log_info "Installing packages from Brewfile..."
    cd "$DOTFILES_DIR/$WORK_TREE"
    
    if [[ ! -f "Brewfile" ]]; then
        log_error "Brewfile not found"
        exit 1
    fi

    brew bundle install
    log_success "Brew packages installed"
}

# Deploy dotfiles using make
deploy_dotfiles() {
    log_info "Deploying dotfiles..."
    cd "$DOTFILES_DIR/$WORK_TREE"
    
    # Check if GNU Stow is installed (should be from brew bundle)
    if ! command_exists stow; then
        log_error "GNU Stow is not installed"
        exit 1
    fi

    make install
    log_success "Dotfiles deployed"
}

# Install Tmux Plugin Manager
install_tpm() {
    local TPM_DIR="$HOME/.tmux/plugins/tpm"
    
    if [[ -d "$TPM_DIR" ]]; then
        log_info "Tmux Plugin Manager already installed"
        return
    fi

    log_info "Installing Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    log_success "TPM installed"

    log_info "Installing tmux plugins..."
    # Install plugins non-interactively
    "$TPM_DIR/bin/install_plugins"
    log_success "Tmux plugins installed"
}

# Configure Fish shell
configure_fish() {
    log_info "Configuring Fish shell..."
    
    # Add Fish to valid shells if not already there
    if ! grep -q "$(command -v fish)" /etc/shells; then
        log_info "Adding Fish to valid shells..."
        echo "$(command -v fish)" | sudo tee -a /etc/shells
    fi

    # Set Fish as default shell if user confirms
    if [[ "$SHELL" != "$(command -v fish)" ]]; then
        read -p "Do you want to set Fish as your default shell? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            chsh -s "$(command -v fish)"
            log_success "Fish set as default shell (will take effect on next login)"
        else
            log_info "Keeping current shell"
        fi
    else
        log_info "Fish is already the default shell"
    fi
}

# Configure Neovim
configure_neovim() {
    log_info "Configuring Neovim..."
    
    # Trigger plugin installation by running Neovim headlessly
    log_info "Installing Neovim plugins..."
    nvim --headless "+Lazy! sync" +qa
    log_success "Neovim plugins installed"
}

# Post-installation instructions
show_post_install() {
    echo
    echo "========================================"
    echo "       Installation Complete!"
    echo "========================================"
    echo
    echo "Manual steps required:"
    echo
    echo "1. GPG Setup (if using commit signing):"
    echo "   - Import your GPG keys"
    echo "   - Configure git with your signing key"
    echo
    echo "2. Create ~/.tokens file for sensitive data:"
    echo "   - Add API tokens, passwords, etc."
    echo "   - This file is automatically sourced by Fish"
    echo
    echo "3. Restart your terminal or run:"
    echo "   source ~/.config/fish/config.fish"
    echo
    echo "4. In tmux, press Ctrl+Space then I to install plugins"
    echo "   (if automatic installation didn't work)"
    echo
    echo "5. Configure Ghostty terminal settings if needed"
    echo
    echo "========================================"
}

# Main installation flow
main() {
    echo "========================================"
    echo "    Dotfiles Installation Script"
    echo "========================================"
    echo

    # Check OS
    check_os

    # Install Homebrew
    log_info "Step 1/7: Homebrew"
    install_homebrew

    # Clone repository
    log_info "Step 2/7: Clone dotfiles"
    clone_dotfiles

    # Install brew packages
    log_info "Step 3/7: Install packages"
    install_brew_packages

    # Deploy dotfiles
    log_info "Step 4/7: Deploy dotfiles"
    deploy_dotfiles

    # Install TPM
    log_info "Step 5/7: Tmux plugins"
    install_tpm

    # Configure Fish
    log_info "Step 6/7: Fish shell"
    configure_fish

    # Configure Neovim
    log_info "Step 7/7: Neovim"
    configure_neovim

    # Show post-install instructions
    show_post_install
}

# Run main function
main "$@"