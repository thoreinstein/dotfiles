_:
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

    opencode = {
      enable = true;
      enableMcpIntegration = true;
      agents = ./mac-1QFL40HG/opencode/agents;
      commands = ./mac-1QFL40HG/opencode/commands;
      settings = {
        autoupdate = false;
        share = "manual";
        disabled_providers = [
          "opencode"
          "google-vertex"
          "google-vertex-anthropic"
        ];
        provider = {
          lmstudio = {
            npm = "@ai-sdk/openai-compatible";
            name = "LM Studio";
            options = {
              baseURL = "http://localhost:1234/v1";
            };
            models = {
              "qwen3.6-35b-a3b" = { };
              "google/gemma-4-26b-a4b" = { };
              "glm-4.7-flash" = { };
            };
          };
        };
        model = "lmstudio/qwen3.6-35b-a3b";
        instructions = [
          "AGENTS.md"
          "CONTRIBUTING.md"
          "docs/*.md"
        ];
        mcp = {
          github = {
            enabled = true;
            type = "remote";
            url = "https://api.githubcopilot.com/mcp/";
            headers = {
              "Authorization" = "Bearer {env:GITHUB_PERSONAL_ACCESS_TOKEN}";
            };
          };
        };
        permission = {
          bash = "allow";
          codesearch = "allow";
          doom_loop = "allow";
          edit = "allow";
          external_directory = "allow";
          glob = "allow";
          grep = "allow";
          list = "allow";
          lsp = "allow";
          read = "allow";
          skill = "allow";
          task = "allow";
          todoread = "allow";
          todowrite = "allow";
          webfetch = "allow";
          websearch = "allow";
        };
      };
      tui = {
        theme = "system";
      };
    };

    pi-coding-agent = {
      settings = {
        defaultProvider = "lm-studio";
        defaultModel = "qwen/qwen3-coder-next";
        enabledModels = [
          "qwen/qwen3.6-35b-a3b"
          "qwen/qwen3-coder-next"
          "amazon-bedrock/us.anthropic.claude-opus-4-7"
          "amazon-bedrock/us.anthropic.claude-sonnet-4-6"
        ];
      };

      models.providers.lm-studio = {
        baseUrl = "http://localhost:1234/v1";
        api = "openai-completions";
        # Placeholder, not a secret — the endpoint is localhost-only.
        apiKey = "local-only";
        models = [
          {
            id = "qwen/qwen3-coder-next";
            name = "Qwen3-Coder-Next";
            reasoning = false;
            input = [ "text" ];
            contextWindow = 131072;
            maxTokens = 16384;
            cost = { input = 0; output = 0; cacheRead = 0; cacheWrite = 0; };
          }
          {
            id = "qwen/qwen3.6-35b-a3b";
            name = "Qwen3.6-35B";
            reasoning = true;
            input = [ "text" ];
            compat.thinkingFormat = "qwen-chat-template";
            contextWindow = 131072;
            maxTokens = 32768;
            cost = { input = 0; output = 0; cacheRead = 0; cacheWrite = 0; };
          }
        ];
      };
    };
  };
}
