{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "ghclone" (builtins.readFile ../../bin/.bin/ghclone))
    (pkgs.writeShellScriptBin "ts" (builtins.readFile ../../bin/.bin/ts))
    (pkgs.writeShellApplication {
      name = "weekly";
      runtimeInputs = [ pkgs.sqlite ];
      text = builtins.readFile ../../bin/.bin/weekly;
    })
  ];
}
