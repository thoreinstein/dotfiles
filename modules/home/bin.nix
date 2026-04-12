{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "ghclone" (builtins.readFile ../../bin/.bin/ghclone))
    (pkgs.writeShellScriptBin "git-cleanup" (builtins.readFile ../../bin/.bin/git-cleanup))
    (pkgs.writeShellScriptBin "ts" (builtins.readFile ../../bin/.bin/ts))
    (pkgs.writeShellScriptBin "test_ts" (builtins.readFile ../../bin/.bin/test_ts.sh))
  ];
}
