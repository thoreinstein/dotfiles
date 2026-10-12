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
      models = [
        (pi.mkLocalModel {
          id = "Qwen3.8-27B-oQ4e-mtp";
          name = "Qwen3.8 oQ4e (oMLX)";
          contextWindow = 131072;
          maxTokens = 32768;
        })
      ];
    };

    # strata on the gaming PC (LAN); no API key.
    strata = {
      baseUrl = "http://192.168.4.56:8080/v1";
      api = "openai-completions";
      apiKey = "not-needed";
      models = [
        (pi.mkLocalModel {
          id = "qwen3.8-flash-next-iq3_xxs";
          name = "Qwen3.8 Flash Next IQ3_XXS (strata)";
          contextWindow = 65536;
          maxTokens = 16384;
        })
        (pi.mkLocalModel {
          id = "swift-qwen3.8-flash-next-gsq-rco-iq3_xxs";
          name = "Swift Qwen3.8 Flash Next IQ3_XXS (strata)";
          contextWindow = 65536;
          maxTokens = 16384;
        })
      ];
    };

    # Cloud gateway: pi knows cost and capabilities for these, so only the
    # window sizes are declared.
    polaris = {
      baseUrl = "https://llm-gateway.polaris.pingidentity.com";
      api = "anthropic-messages";
      apiKey = "$POLARIS_AUTH_TOKEN";
      authHeader = true;
      models = [
        (pi.mkModel {
          id = "anthropic.Polaris.Model.Smart.High";
          contextWindow = 380000;
          maxTokens = 32768;
        })
        (pi.mkModel {
          id = "anthropic.Polaris.Model.Smart.Medium";
          contextWindow = 380000;
          maxTokens = 32768;
        })
        (pi.mkModel {
          id = "anthropic.Polaris.Model.Smart.Low";
          contextWindow = 380000;
          maxTokens = 32768;
        })
        (pi.mkModel {
          id = "anthropic.Claude.Sonnet";
          contextWindow = 1000000;
          maxTokens = 128000;
        })
        (pi.mkModel {
          id = "anthropic.Claude.Haiku";
          contextWindow = 200000;
          maxTokens = 64000;
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
          id = "anthropic.Zai.GLM5";
          contextWindow = 380000;
          maxTokens = 32768;
        })
        (pi.mkModel {
          id = "anthropic.Zai.GLM53Flash";
          contextWindow = 380000;
          maxTokens = 32768;
        })
      ];
    };
  };
in
{
  programs = {
    mcp = {
      enable = true;
      servers = {
        context7 = {
          url = "https://mcp.context7.com/mcp";
        };
        exa = {
          url = "https://mcp.exa.ai/mcp?tools=web_search_exa";
        };
        grep_app = {
          url = "https://mcp.grep.app";
        };
      };
    };

    pi-coding-agent = {
      settings = {
        defaultProvider = "omlx";
        defaultModel = "Qwen3.8-27B-oQ4e-mtp";
        enabledModels = pi.mkEnabledModels [ "omlx" "strata" "polaris" ] providers;
      };

      models.providers = providers;
    };
  };
}
