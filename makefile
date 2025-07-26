.PHONY: all tmux nvim git install clean create-dirs fish ghostty ripgrep bat fd eza bin starship darwin switch

STOW := stow
STOW_FLAGS := 

all: install

# Create target directories if they don't exist
create-dirs:
	@mkdir -p $(HOME)/.config
	@mkdir -p $(HOME)/.bin

tmux:
	@echo "Installing tmux configuration..."
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) tmux

nvim: create-dirs
	@echo "Installing nvim configuration..."
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) nvim

git:
	@echo "Installing git configuration..."
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) git

bin:
	@echo "Installing bin scripts..."
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) bin

fish: create-dirs
	@echo "Installing fish configuration..."
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) fish

ghostty: create-dirs
	@echo "Installing ghostty configuration..."
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) ghostty

ripgrep:
	@echo "Installing ripgrep configuration..."
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) ripgrep

bat:
	@echo "Installing bat configuration..."
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) bat
	@echo "Rebuilding bat cache for themes..."
	@$(HOME)/.config/bat/install.sh

fd:
	@echo "Installing fd configuration..."
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) fd

eza:
	@echo "Installing eza configuration..."
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) eza

starship: create-dirs
	@echo "Installing starship configuration..."
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) starship

# Install all configurations
install: create-dirs tmux nvim git bin fish ghostty ripgrep bat fd eza starship
	@echo "All dotfiles have been installed"

# Clean up (unstow everything)
clean:
	@echo "Removing all dotfile symlinks..."
	@$(STOW) $(STOW_FLAGS) -D -t $(HOME) tmux nvim git bin fish ghostty ripgrep bat fd eza starship
	@echo "All dotfiles have been unlinked"

# Nix darwin commands
darwin: switch

# Auto-detect hostname
HOSTNAME := $(shell hostname -s)

# Build only (no activation)
build:
	@echo "Building nix-darwin configuration for $(HOSTNAME)..."
	@nix build .#darwinConfigurations.$(HOSTNAME).system

switch:
	@echo "Activating nix-darwin configuration for $(HOSTNAME)..."
	@if [ ! -f "/run/current-system/sw/bin/darwin-rebuild" ]; then \
		echo "First time activation - using result/sw/bin/darwin-rebuild"; \
		echo "You'll be prompted for your password."; \
		sudo ./result/sw/bin/darwin-rebuild switch --flake .#$(HOSTNAME); \
	else \
		echo "Using existing darwin-rebuild"; \
		echo "You'll be prompted for your password."; \
		sudo /run/current-system/sw/bin/darwin-rebuild switch --flake .#$(HOSTNAME); \
	fi
