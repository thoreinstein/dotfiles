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
    neovim
    tmux
    starship
    direnv
    
    # Security tools
    gnupg
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
  
  # Fish shell (we'll expand this later)
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # We'll migrate the fish config here incrementally
      set -gx GPG_TTY (tty)
      set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
      gpgconf --launch gpg-agent
    '';
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
}