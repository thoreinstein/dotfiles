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
        defaultProvider = "splash";
        defaultModel = "incoai/Qwen3.6-35B-A3B-Splash";
        enabledModels = [
          "incoai/Qwen3.8-27B-Splash"
          "incoai/Qwen3.6-35B-A3B-Splash"
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
        splash = {
          baseUrl = "http://localhost:8000/v1";
          api = "openai-completions";
          apiKey = "not-needed";
          models = [
            {

              id = "incoai/Qwen3.8-27B-Splash";
              name = "Qwen3.8";
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
            {

              id = "incoai/Qwen3.6-35B-A3B-Splash";
              name = "Qwen3.6";
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
