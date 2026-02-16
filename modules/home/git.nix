{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    gh
    delta
    git-filter-repo
    git-lfs
  ];

  home.file = {
    ".gitconfig".source = ../../git/.gitconfig;
    ".gitignore_global".source = ../../git/.gitignore_global;
  };
}
