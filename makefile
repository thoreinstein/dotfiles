.PHONY: all zsh tmux nvim-base nvim starship git kitty install clean create-dirs

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

kitty:
	mkdir -p $(HOME)/.config
	$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) kitty

# Install all configurations
install: create-dirs zsh tmux nvim starship git bin kitty
	@echo "All dotfiles have been installed"

# Clean up (unstow everything)
clean:
	$(STOW) $(STOW_FLAGS) -D -t $(HOME) zsh tmux .config nvim git bin starship kitty
	@echo "All dotfiles have been unlinked"
