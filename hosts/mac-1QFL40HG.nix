{ lib, ... }:
{
  programs.gemini-cli.settings =
    lib.importJSON ./mac-1QFL40HG/gemini-cli/settings.json;

  programs.codex.settings =
    lib.importTOML ./mac-1QFL40HG/codex/config.toml;
}
