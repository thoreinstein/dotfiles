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
        github = {
          url = "https://api.githubcopilot.com/mcp/";
          headers = {
            "Authorization" = "Bearer \${GITHUB_PERSONAL_ACCESS_TOKEN}";
          };
        };
        grep_app = {
          url = "https://mcp.grep.app";
        };
        playwright = {
          command = "docker";
          args = [
            "run"
            "-i"
            "--rm"
            "mcp/playwright"
          ];
        };
        sequential_thinking = {
          command = "docker";
          args = [
            "run"
            "-i"
            "--rm"
            "mcp/sequentialthinking"
          ];
        };
        time = {
          command = "docker";
          args = [
            "run"
            "-i"
            "--rm"
            "mcp/time"
          ];
        };
      };
    };

    pi-coding-agent = {
      settings = {
        defaultProvider = "lm-studio";
        defaultModel = "qwen/qwen3.8-27b";
        subagents = {
          defaultModel = "polaris/anthropic.Polaris.Model.Smart.Medium";
          agentOverrides = {
            scout = {
              model = "polaris/anthropic.Polaris.Model.Smart.Low";
              thinking = "low";
            };
            researcher = {
              model = "polaris/anthropic.Claude.Sonnet";
              thinking = "high";
            };
            worker = {
              model = "polaris/anthropic.Polaris.Model.Smart.Medium";
              thinking = "medium";
            };
            reviewer = {
              model = "polaris/anthropic.Polaris.Model.Smart.High";
              thinking = "high";
            };
            oracle = {
              model = "polaris/anthropic.Claude.Opus";
              thinking = "max";
            };
            delegate = {
              model = "polaris/anthropic.Polaris.Model.Smart.Medium";
              thinking = "medium";
            };
          };
          modelScope = {
            enforce = true;
            strict = true;
            allow = [ "polaris/*" ];
          };
        };
        enabledModels = [
          "qwen/qwen3.8-27b"
          "polaris/anthropic.Polaris.Model.Smart.High"
          "polaris/anthropic.Polaris.Model.Smart.Medium"
          "polaris/anthropic.Polaris.Model.Smart.Low"
          "polaris/anthropic.Claude.Opus"
          "polaris/anthropic.Claude.Sonnet"
          "polaris/anthropic.Claude.Haiku"
          "polaris/anthropic.OpenAI.Sol"
          "polaris/anthropic.OpenAI.Terra"
          "polaris/anthropic.OpenAI.Luna"
          "polaris/anthropic.Zai.GLM5"
        ];
      };

      models.providers = {
        lm-studio = {
          baseUrl = "http://localhost:1234/v1";
          api = "openai-completions";
          apiKey = "local-only";
          models = [
            {
              id = "qwen/qwen3.8-27b@q6_k_xl";
              name = "Qwen3.8-27b";
              reasoning = true;
              input = [
                "text"
                "image"
              ];
              contextWindow = 65536;
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
            { id = "anthropic.Polaris.Model.Smart.High"; }
            { id = "anthropic.Polaris.Model.Smart.Medium"; }
            { id = "anthropic.Polaris.Model.Smart.Low"; }
            { id = "anthropic.Claude.Opus"; }
            { id = "anthropic.Claude.Sonnet"; }
            { id = "anthropic.Claude.Haiku"; }
            { id = "anthropic.OpenAI.Sol"; }
            { id = "anthropic.OpenAI.Terra"; }
            { id = "anthropic.OpenAI.Luna"; }
            { id = "anthropic.Zai.GLM5"; }
          ];
        };
      };
    };
  };
}
