.PHONY: all zsh tmux nvim starship git install clean create-dirs

STOW := stow
STOW_FLAGS := --verbose

all: install

# Create target directories if they don't exist
create-dirs:
	mkdir -p $(HOME)/.config

# Stow configurations
zsh:
	$(STOW) $(STOW_FLAGS) -t $(HOME) zsh

tmux:
	$(STOW) $(STOW_FLAGS) -t $(HOME) tmux

nvim:
	$(STOW) $(STOW_FLAGS) -t $(HOME) nvim

starship:
	$(STOW) $(STOW_FLAGS) -t $(HOME)/.config -d starship -S .

git:
	$(STOW) $(STOW_FLAGS) -t $(HOME) git

# Install all configurations
install: create-dirs zsh tmux nvim starship git
	@echo "All dotfiles have been installed"

# Clean up (unstow everything)
clean:
	$(STOW) $(STOW_FLAGS) -D -t $(HOME) zsh tmux nvim git
	$(STOW) $(STOW_FLAGS) -D -t $(HOME)/.config -d starship -S .
	@echo "All dotfiles have been unlinked"