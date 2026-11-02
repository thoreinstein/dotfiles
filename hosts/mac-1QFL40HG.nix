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

    # strata on the gaming PC (LAN); no API key.
    strata = {
      baseUrl = "http://chicago.local:8080/v1";
      api = "openai-completions";
      apiKey = "not-needed";
      models = [
        (pi.mkLocalModel {
          id = "swift-qwen3.8-flash-next-gsq-rco-iq3_xxs";
          name = "Qwen3.8 Flash Next IQ3_XXS (strata)";
          contextWindow = 65536;
          maxTokens = 16384;
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
        # kimi-coding is a pi built-in provider (auth via /login), so it has no entry in
        # `providers` and is listed by id.
        enabledModels = pi.mkEnabledModels [ "omlx" "strata" "polaris" ] providers
          ++ [ "kimi-coding/k3" ];
        modelThinkingLevels = {
          # k3 has no medium level, so the global default would leave it without thinking.
          "kimi-coding/k3" = "high";
          # The Smart aliases name their own level; match it instead of the global medium.
          "polaris/anthropic.Polaris.Model.Smart.High" = "high";
          "polaris/anthropic.Polaris.Model.Smart.Medium" = "medium";
          "polaris/anthropic.Polaris.Model.Smart.Low" = "low";
        };
      };

      models = {
        "$schema" = "https://pi.dev/schemas/models.schema.json";
        inherit providers;
      };
    };
  };
}
