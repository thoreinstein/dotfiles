.PHONY: all zsh tmux nvim-base nvim starship git install clean create-dirs

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

nvim: nvim-base
	@echo "Installing nvim configuration..."
	@mkdir -p $(HOME)/.config
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

# Install all configurations
install: create-dirs tmux nvim git bin fish ghostty ripgrep bat fd eza
	@echo "All dotfiles have been installed"

# Clean up (unstow everything)
clean:
	@echo "Removing all dotfile symlinks..."
	@$(STOW) $(STOW_FLAGS) -D -t $(HOME) zsh tmux .config nvim git bin starship fish ghostty ripgrep bat fd eza
	@echo "All dotfiles have been unlinked"
