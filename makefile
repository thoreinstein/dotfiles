.PHONY: all tmux nvim git install clean create-dirs fish ghostty ripgrep bat fd eza bin starship force

STOW := stow
STOW_FLAGS :=
STOW_RESTOW := --restow 

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

zsh:
	@echo "Installing zsh configuration..."
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) zsh

# Install all configurations
install: create-dirs tmux nvim git bin fish ghostty ripgrep bat fd eza starship zsh
	@echo "All dotfiles have been installed"

# Clean up (unstow everything)
clean:
	@echo "Removing all dotfile symlinks..."
	@$(STOW) $(STOW_FLAGS) -D -t $(HOME) tmux nvim git bin fish ghostty ripgrep bat fd eza starship zsh
	@echo "All dotfiles have been unlinked"

# Force reinstall - remove stale symlinks and restow
force: create-dirs
	@echo "Force reinstalling all dotfiles..."
	@echo "Removing stale dotfile symlinks..."
	@find $(HOME) -maxdepth 1 -type l -lname '*dotfiles*' -delete 2>/dev/null || true
	@find $(HOME)/.config -type l -lname '*dotfiles*' -delete 2>/dev/null || true
	@find $(HOME)/.bin -type l -lname '*dotfiles*' -delete 2>/dev/null || true
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) tmux
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) nvim
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) git
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) bin
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) fish
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) ghostty
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) ripgrep
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) bat
	@$(HOME)/.config/bat/install.sh
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) fd
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) eza
	@$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) starship
	@echo "All dotfiles have been force reinstalled"
