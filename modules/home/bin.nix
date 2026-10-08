{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "ghclone" (builtins.readFile ../../bin/.bin/ghclone))
    (pkgs.writeShellScriptBin "ts" (builtins.readFile ../../bin/.bin/ts))
    (pkgs.writeShellScriptBin "weekly" (builtins.readFile ../../bin/.bin/weekly))
  ];
}
