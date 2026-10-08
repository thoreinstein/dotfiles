{ pkgs, ... }:
{
  home.packages = [ pkgs.mise ];

  # mise's `direnv activate` output relies on direnv_load's nested-hook dump
  # protocol, which silently applies only the global config (go) and drops
  # project tools' PATH entries. Shims mode via plain PATH export works.
  home.file.".config/direnv/lib/use_mise.sh".text = ''
    use_mise() {
      eval "$(${pkgs.mise}/bin/mise activate bash --shims)"
    }
  '';
}
