.PHONY: all zsh tmux nvim-base nvim starship git install clean create-dirs

STOW := stow
STOW_FLAGS := --verbose

all: install

# Create target directories if they don't exist
create-dirs:
	mkdir -p $(HOME)/.config

tmux:
	$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) tmux

nvim: nvim-base
	mkdir -p $(HOME)/.config
	$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) nvim

git:
	$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) git

bin:
	$(STOW) $(STOW_FLAGS) --adopt -t $(HOME) bin

# Install all configurations
install: create-dirs tmux nvim git bin
	@echo "All dotfiles have been installed"

# Clean up (unstow everything)
clean:
	$(STOW) $(STOW_FLAGS) -D -t $(HOME) zsh tmux .config nvim git bin starship
	@echo "All dotfiles have been unlinked"
