.PHONY: all zsh tmux nvim-base nvim starship git install clean create-dirs

STOW := stow
STOW_FLAGS := --verbose

all: install

# Create target directories if they don't exist
create-dirs:
	mkdir -p $(HOME)/.config

# Stow configurations
zsh:
	$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) zsh

tmux:
	$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) tmux

# LazyVim base configuration (submodule)
nvim-base:
	mkdir -p $(HOME)/.config
	$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) .config

# Custom Neovim overlays (depends on base)
nvim: nvim-base
	mkdir -p $(HOME)/.config
	$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) nvim

starship:
	mkdir -p $(HOME)/.config
	$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) starship

git:
	$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) git

bin:
	$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) bin

# Install all configurations
install: create-dirs zsh tmux nvim starship git bin
	@echo "All dotfiles have been installed"

# Clean up (unstow everything)
clean:
	$(STOW) $(STOW_FLAGS) -D -t $(HOME) zsh tmux .config nvim git bin starship
	@echo "All dotfiles have been unlinked"