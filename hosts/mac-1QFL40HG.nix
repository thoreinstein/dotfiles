_: {
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
        enabledModels = [
          "omlx/Qwen3.8-27B-oQ4e-mtp"
          "strata/qwen3.8-flash-next-iq3_xxs"
          "polaris/anthropic.Polaris.Model.Smart.High"
          "polaris/anthropic.Polaris.Model.Smart.Medium"
          "polaris/anthropic.Polaris.Model.Smart.Low"
          "polaris/anthropic.Claude.Sonnet"
          "polaris/anthropic.Claude.Haiku"
          "polaris/anthropic.OpenAI.Terra"
          "polaris/anthropic.OpenAI.Luna"
          "polaris/anthropic.Zai.GLM5"
          "polaris/anthropic.Zai.GLM53Flash"
        ];
      };

      models.providers = {
        omlx = {
          baseUrl = "http://127.0.0.1:8000/v1";
          api = "openai-completions";
          # Read at request time from oMLX's own config; keeps the key out of nix.
          apiKey = "!jq -r .auth.api_key ~/.omlx/settings.json";
          models = [
            {
              id = "Qwen3.8-27B-oQ4e-mtp";
              name = "Qwen3.8 oQ4e (oMLX)";
              reasoning = true;
              input = [
                "text"
              ];
              contextWindow = 131072;
              maxTokens = 32768;
              cost = {
                input = 0;
                output = 0;
                cacheRead = 0;
                cacheWrite = 0;
              };
            }
          ];
        };

        # strata on the gaming PC (LAN); no API key.
        strata = {
          baseUrl = "http://192.168.4.56:8080/v1";
          api = "openai-completions";
          apiKey = "not-needed";
          models = [
            {
              id = "qwen3.8-flash-next-iq3_xxs";
              name = "Qwen3.8 Flash Next IQ3_XXS (strata)";
              reasoning = true;
              input = [
                "text"
              ];
              contextWindow = 65536;
              maxTokens = 16384;
              cost = {
                input = 0;
                output = 0;
                cacheRead = 0;
                cacheWrite = 0;
              };
            }
          ];
        };

        polaris = {
          baseUrl = "https://llm-gateway.polaris.pingidentity.com";
          api = "anthropic-messages";
          apiKey = "$POLARIS_AUTH_TOKEN";
          authHeader = true;
          models = [
            {
              id = "anthropic.Polaris.Model.Smart.High";
              contextWindow = 380000;
              maxTokens = 32768;
            }
            {
              id = "anthropic.Polaris.Model.Smart.Medium";
              contextWindow = 380000;
              maxTokens = 32768;
            }
            {
              id = "anthropic.Polaris.Model.Smart.Low";
              contextWindow = 380000;
              maxTokens = 32768;
            }
            {
              id = "anthropic.Claude.Sonnet";
              contextWindow = 1000000;
              maxTokens = 128000;
            }
            {
              id = "anthropic.Claude.Haiku";
              contextWindow = 200000;
              maxTokens = 64000;
            }
            {
              id = "anthropic.OpenAI.Terra";
              contextWindow = 1000000;
              maxTokens = 128000;
            }
            {
              id = "anthropic.OpenAI.Luna";
              contextWindow = 1000000;
              maxTokens = 128000;
            }
            {
              id = "anthropic.Zai.GLM5";
              contextWindow = 380000;
              maxTokens = 32768;
            }
            {
              id = "anthropic.Zai.GLM53Flash";
              contextWindow = 380000;
              maxTokens = 32768;
            }
          ];
        };
      };
    };
  };
}
