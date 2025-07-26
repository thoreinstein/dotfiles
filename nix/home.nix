{ config, pkgs, lib, inputs, username, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = username;
  home.homeDirectory = "/Users/${username}";
  
  # This value determines the Home Manager release that your
  # configuration is compatible with.
  home.stateVersion = "24.05";
  
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  
  # Packages to install for this user
  home.packages = with pkgs; [
    # Modern CLI tools (migrating from Brewfile)
    atuin
    bat
    eza
    fd
    fzf
    jq
    ripgrep
    wget
    
    # Development tools
    starship
    direnv
    
    # Security tools
    gnupg
    pinentry_mac
    yubikey-manager
    yubikey-personalization
    
    # Languages and tools
    go
    nodejs
    
    # GNU tools
    coreutils
    stow  # We'll keep this temporarily for the migration
    
    # Fonts
    nerd-fonts.jetbrains-mono
  ];
  
  # Git configuration
  programs.git = {
    enable = true;
    userName = "Jim Myers";
    userEmail = ""; # TODO: Add your email
    signing = {
      key = "0x28E7C0B3D41D890F";
      signByDefault = true;
    };
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.default = "current";
      credential.helper = "osxkeychain";
      gpg.program = "${pkgs.gnupg}/bin/gpg";
    };
    
    aliases = {
      s = "status";
      co = "checkout";
      cb = "checkout -b";
      cm = "commit -m";
      ca = "commit --amend";
      can = "commit --amend --no-edit";
      wa = "!f() { git worktree add --track -b $1 $1 $2; cd $1; }; f";
      wl = "worktree list";
      wr = "worktree remove";
      rewrite = "rebase -i";
      l = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      pr = "!f() { git worktree add ../pr/$1 && cd ../pr/$1 && gh pr checkout $1; }; f";
      feature = "!f() { git worktree add ../feature/$1 && cd ../feature/$1 && gh pr checkout $1; }; f";
      bugfix = "!f() { git worktree add ../bugfix/$1 && cd ../bugfix/$1 && gh pr checkout $1; }; f";
      chore = "!f() { git worktree add ../chore/$1 && cd ../chore/$1 && gh pr checkout $1; }; f";
    };
    
    includes = [
      { path = "~/.gitconfig.local"; }
    ];
  };
  
  # Fish shell
  programs.fish = {
    enable = true;
    loginShellInit = ''
      # Ensure Nix paths are available
      set -gx PATH /etc/profiles/per-user/myers/bin $PATH
      set -gx PATH $HOME/.nix-profile/bin $PATH
    '';
    interactiveShellInit = ''
      # Environment variables
      set -gx GPG_TTY (tty)
      set -gx SSH_AUTH_SOCK (${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)
      ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent
      
      set -gx K9S_CONFIG_DIR $HOME/.config/k9s
      set -gx RIPGREP_CONFIG_PATH "$HOME/.ripgreprc"
      
      # Initialize atuin
      ${pkgs.atuin}/bin/atuin init fish | source
    '';
    
    shellAliases = {
      # Git aliases
      gap = "git add -p";
      gan = "git add -N";
      vim = "nvim";
      
      # Eza aliases (modern ls replacement)
      ls = "eza";
      l = "eza -la";
      ll = "eza -lg";
      la = "eza -la";
      lt = "eza --tree";
      lg = "eza -la --git";
      lh = "eza -la --header";
      ld = "eza -lD";  # directories only
      lf = "eza -lf";  # files only
      lx = "eza -la --sort=extension";
      lk = "eza -la --sort=size";
      lr = "eza -la --sort=modified --reverse";
      
      # Ripgrep aliases
      rga = "rg --text";      # Search all files including binary
      rgl = "rg -l";          # Only show filenames
      rgc = "rg -c";          # Show match counts
      rgi = "rg -i";          # Case-insensitive search
      rgf = "rg --files";     # List files that would be searched
      
      # fd aliases
      fda = "fd --hidden";    # Include hidden files
      fde = "fd --extension"; # Search by file extension
      fdt = "fd --type";      # Search by type (f=file, d=directory, etc)
      fdx = "fd --exec";      # Execute command on results
      fdf = "fd --follow";    # Follow symlinks
      fdd = "fd --type d";    # Find directories only
      fdfe = "fd --type f --extension"; # Find files by extension
    };
  };
  
  # Starship prompt
  programs.starship = {
    enable = true;
    # We'll add the configuration later
  };
  
  # Enable direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  
  # Neovim - just manage the package, keep your existing config
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
  
  # Link your existing nvim configuration
  xdg.configFile."nvim" = {
    source = ../nvim/.config/nvim;
    recursive = true;
  };
  
  # Tmux configuration
  programs.tmux = {
    enable = true;
    mouse = true;
    keyMode = "vi";
    terminal = "tmux-256color";
    prefix = "C-Space";
    baseIndex = 1;
    escapeTime = 0;
    shell = "${pkgs.fish}/bin/fish";
    
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      prefix-highlight
      pain-control
      vim-tmux-navigator
      better-mouse-mode
      extrakto
      {
        plugin = rose-pine;
        extraConfig = ''
          set -g @rose_pine_variant 'main'
          set -g @rose_pine_date_time ""
          set -g @rose_pine_directory 'on'
          set -g @rose_pine_bar_bg_disable 'on'
          set -g @rose_pine_bar_bg_disabled_color_option 'default'
          set -g @rose_pine_show_current_program 'on'
          set -g @rose_pine_show_pane_directory 'on'
          set -g @rose_pine_status_right_prepend_section '#{now_playing} '
        '';
      }
    ];
    
    extraConfig = ''
      # Set default shell and ensure PATH is preserved
      set -g default-shell "${pkgs.fish}/bin/fish"
      set -g default-command "${pkgs.fish}/bin/fish"
      
      # True color support
      set -ag terminal-overrides ",xterm-256color:RGB"
      
      # Unbind default prefix and set new one
      unbind C-b
      bind C-Space send-prefix
      
      # Custom key binding for ts script
      bind -r f run-shell "~/.bin/ts"
      
      # Window and pane settings
      set-window-option -g aggressive-resize on
      setw -g pane-base-index 1
      set -g renumber-windows on
      
      # Plugin configurations
      set -g '@now-playing-status-format' "{icon} {scrollable}"
      set -g '@now-playing-playing-icon' "♪"
      set -g '@now-playing-paused-icon' "⏸"
      set -g '@now-playing-scrollable-format' "{artist} - {title}"
      set -g '@now-playing-scrollable-threshold' 25
      
      # Alt+Number window switching (no prefix)
      bind-key -n M-1 select-window -t 1
      bind-key -n M-2 select-window -t 2
      bind-key -n M-3 select-window -t 3
      bind-key -n M-4 select-window -t 4
      bind-key -n M-5 select-window -t 5
      bind-key -n M-6 select-window -t 6
      bind-key -n M-7 select-window -t 7
      bind-key -n M-8 select-window -t 8
      bind-key -n M-9 select-window -t 9
    '';
  };
}