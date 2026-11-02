{ lib, ... }:
let
  pi = import ../modules/home/pi/model.nix lib;

  # Single source for both the provider catalog and the models pi offers,
  # so a model added here is selectable without a second edit.
  providers = {
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

    # Cloud gateway: these ids are custom to the gateway, so pi has no built-in
    # metadata for them. Window sizes and reasoning are declared here; reasoning
    # defaults to false, which would disable thinking. Cost is zero: the company
    # pays, spend isn't tracked in pi, and the aliases have no published price.
    polaris = {
      baseUrl = "https://llm-gateway.polaris.pingidentity.com";
      api = "anthropic-messages";
      apiKey = "$POLARIS_AUTH_TOKEN";
      authHeader = true;
      models = map (m: m // { cost = { input = 0; output = 0; cacheRead = 0; cacheWrite = 0; }; }) [
        (pi.mkModel {
          id = "anthropic.Polaris.Model.Smart.High";
          reasoning = true;
          contextWindow = 380000;
          maxTokens = 32768;
        })
        (pi.mkModel {
          id = "anthropic.Polaris.Model.Smart.Medium";
          reasoning = true;
          contextWindow = 380000;
          maxTokens = 32768;
        })
        (pi.mkModel {
          id = "anthropic.Polaris.Model.Smart.Low";
          reasoning = true;
          contextWindow = 380000;
          maxTokens = 32768;
        })
        (pi.mkModel {
          id = "anthropic.Claude.Sonnet";
          reasoning = true;
          contextWindow = 1000000;
          maxTokens = 128000;
        })
        (pi.mkModel {
          id = "anthropic.Claude.Haiku";
          reasoning = true;
          contextWindow = 200000;
          maxTokens = 64000;
        })
        (pi.mkModel {
          # Window sizes assumed from Terra/Luna; the gateway doesn't publish them.
          id = "anthropic.OpenAI.Sol";
          contextWindow = 1000000;
          maxTokens = 128000;
        })
        (pi.mkModel {
          id = "anthropic.OpenAI.Terra";
          contextWindow = 1000000;
          maxTokens = 128000;
        })
        (pi.mkModel {
          id = "anthropic.OpenAI.Luna";
          contextWindow = 1000000;
          maxTokens = 128000;
        })
        (pi.mkModel {
          id = "anthropic.Zai.GLM53Flash";
          reasoning = true;
          contextWindow = 380000;
          maxTokens = 32768;
        })
      ];
    };
  };
in
{
  imports = [ ../modules/home/work.nix ];

  programs = {
    pi-coding-agent = {
      settings = {
        defaultProvider = "omlx";
        defaultModel = "Qwen3.8-27B-oQ4e-mtp";
        # omlx first and polaris between the shared strata and k3 in pi's model picker.
        enabledModels = lib.mkMerge [
          (lib.mkBefore (pi.mkEnabledModels [ "omlx" ] providers))
          (lib.mkOrder 1200 (pi.mkEnabledModels [ "polaris" ] providers))
        ];
        modelThinkingLevels = {
          # The Smart aliases name their own level; match it instead of the global medium.
          "polaris/anthropic.Polaris.Model.Smart.High" = "high";
          "polaris/anthropic.Polaris.Model.Smart.Medium" = "medium";
          "polaris/anthropic.Polaris.Model.Smart.Low" = "low";
        };
      };

      models = {
        inherit providers;
      };
    };
  };
}
