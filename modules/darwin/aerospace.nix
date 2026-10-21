{ lib, ... }:
let
  # Mirrors AeroSpace's built-in default-config.toml. nix-darwin always passes
  # --config-path, so the built-in defaults never load on their own.
  workspaces = (map toString (lib.range 1 9))
    ++ lib.stringToCharacters "ABCDEFGIMNOPQRSTUVWXYZ";
  perWorkspace = f: lib.listToAttrs (map f workspaces);
in
{
  services.aerospace = {
    enable = true;
    settings = {
      config-version = 2;
      persistent-workspaces = workspaces;

      mode.main.binding = {
        alt-slash = "layout tiles horizontal vertical";
        alt-comma = "layout accordion horizontal vertical";

        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        alt-minus = "resize smart -50";
        alt-equal = "resize smart +50";

        alt-tab = "workspace-back-and-forth";
        alt-shift-tab = "move-workspace-to-monitor --wrap-around next";

        alt-shift-semicolon = "mode service";
      }
      // perWorkspace (ws: lib.nameValuePair "alt-${lib.toLower ws}" "workspace ${ws}")
      // perWorkspace (ws: lib.nameValuePair "alt-shift-${lib.toLower ws}" "move-node-to-workspace ${ws}");

      mode.service.binding = {
        esc = [ "reload-config" "mode main" ];
        r = [ "flatten-workspace-tree" "mode main" ];
        f = [ "layout floating tiling" "mode main" ];
        backspace = [ "close-all-windows-but-current" "mode main" ];

        alt-shift-h = [ "join-with left" "mode main" ];
        alt-shift-j = [ "join-with down" "mode main" ];
        alt-shift-k = [ "join-with up" "mode main" ];
        alt-shift-l = [ "join-with right" "mode main" ];
      };
    };
  };
}
