{ pkgs, ... }:
{
  home.packages = [ pkgs.mise ];

  home.file.".config/direnv/lib/use_mise.sh".source = pkgs.runCommand "mise-direnv-lib" { } ''
    ${pkgs.mise}/bin/mise direnv activate > $out
  '';
}
