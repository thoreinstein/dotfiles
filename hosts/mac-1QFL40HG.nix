{ lib, ... }:
let
  pi = import ../modules/home/pi/model.nix lib;

  omlx = {
    baseUrl = "http://127.0.0.1:8000/v1";
    api = "openai-completions";
    # Read at request time from oMLX's own config; keeps the key out of nix.
    apiKey = "!jq -r .auth.api_key ~/.omlx/settings.json";
    # Every oMLX model is Qwen; pi can't detect the format from a localhost URL.
    compat.thinkingFormat = "qwen-chat-template";
    models = [
      (pi.mkLocalModel {
        id = "Qwen3.8-27B-oQ4e-mtp";
        name = "Qwen3.8 oQ4e (oMLX)";
        # oMLX serves 262144; capped at half to bound KV-cache memory.
        contextWindow = 131072;
        maxTokens = 32768;
      })
    ];
  };
in
{
  imports = [ ../modules/home/work.nix ];

  programs.pi-coding-agent = {
    settings = {
      defaultProvider = "omlx";
      defaultModel = "Qwen3.8-27B-oQ4e-mtp";
      # First in pi's model picker.
      enabledModels = lib.mkBefore (pi.mkEnabledModels [ "omlx" ] { inherit omlx; });
    };

    models.providers = { inherit omlx; };
  };
}
