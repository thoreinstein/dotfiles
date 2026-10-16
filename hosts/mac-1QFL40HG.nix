{ lib, pkgs, ... }:
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
  imports = [ ./mac-1QFL40HG/claude.nix ];

  # codegraph CLI + MCP server (wired for Claude and pi in modules/home/mcp.json).
  # rtk backs Claude's PreToolUse hook and pi-rtk-optimizer; the nixpkgs build has no
  # telemetry endpoint.
  home = {
    packages = [
      pkgs.codegraph
      pkgs.rtk
    ];
    sessionVariables = {
      CODEGRAPH_TELEMETRY = "0";
      # The python.org python3 on PATH ships with no CA bundle, so Python HTTPS (e.g. the
      # security-guidance plugin's review hook) fails CERTIFICATE_VERIFY_FAILED. Use the
      # nix-darwin bundle.
      SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    };
  };

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
        # kimi-coding is a pi built-in provider (auth via /login), so it has no entry in
        # `providers` and is listed by id.
        enabledModels = pi.mkEnabledModels [ "omlx" "strata" "polaris" ] providers
          ++ [ "kimi-coding/k3" ];
      };

      models.providers = providers;
    };
  };
}
