{ pkgs, ... }:
{
  programs.git = {
    enable = true;

    signing = {
      signByDefault = true;
      format = "openpgp";
    };

    lfs.enable = true;

    ignores = [
      # macOS
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"
      "._*"
      ".Spotlight-V100"
      ".Trashes"
      ".com.apple.timemachine.donotpresent"

      # Editor files
      ".vscode/"
      ".idea/"
      "*.sublime-project"
      "*.sublime-workspace"
      ".vim/"
      "*.swp"
      "*.swo"
      "*~"

      # Environment
      ".env"
      ".env.local"
      ".env.development.local"
      ".env.test.local"
      ".env.production.local"
      ".envrc"

      # Logs
      "logs"
      "*.log"

      # Dependency directories
      "node_modules/"
      "jspm_packages/"
      "vendor/"
      "venv/"
      ".venv/"
      "__pycache__/"
      "dist/"
      "build/"

      # Cache
      ".npm"
      ".eslintcache"
      ".stylelintcache"
      ".cache/"

      # Secrets
      ".netrc"
      "*.pem"
      "*.key"
      "*.p12"
      "*.pfx"
      "credentials.json"

      ".direnv/"
      ".repo-mix.mxl"
      "roadmap*.json"
    ];

    includes = [
      { path = "~/.gitconfig.local"; }
    ];

    settings = {
      user.name = "Jim Myers";
      core.editor = "nvim";
      init.defaultBranch = "main";
      pull.rebase = true;
      pull.autostash = true;
      push.default = "current";
      credential.helper = "osxkeychain";
      rerere.enabled = true;
      gpg.program = "gpg";

      alias = {
        ca = "commit --amend";
        can = "commit --amend --no-edit";
        cb = "checkout -b";
        cm = "commit -m";
        co = "checkout";
        l = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        mt = "mergetool";
        rewrite = "rebase -i";
        s = "status -sb";
        wl = "worktree list";
        wr = "worktree remove";
        d = "diff --stat";
        pr = "!f() { git worktree add ../pr/$1 && cd ../pr/$1 && gh pr checkout $1; }; f";
        wa = "!f() { git worktree add -b $1 $1 $2; cd $1; }; f";
      };

      merge.tool = "fugitive";
      mergetool.prompt = false;
      mergetool.keepBackup = false;
      "mergetool \"fugitive\"".cmd = ''nvim -f -c "Gvdiffsplit!" "$MERGED"'';
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  home.packages = with pkgs; [
    gh
    git-filter-repo
  ];
}
