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
      # claude-code 2.1.308 lost its bundled root store on macOS
      # (UNABLE_TO_GET_ISSUER_CERT_LOCALLY); point it at the nix-darwin bundle. Drop
      # once upstream ships a fix (2.1.303 and earlier didn't need it).
      NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
    };
  };

  # Same fix for the engram launchd agents (engram-daily-log shells out to claude);
  # sessionVariables don't reach launchd.
  engram.agents.caBundle = "/etc/ssl/certs/ca-certificates.crt";

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
        # k3 has no medium level, so the global default would leave it without thinking.
        modelThinkingLevels."kimi-coding/k3" = "high";
      };

      models = {
        "$schema" = "https://pi.dev/schemas/models.schema.json";
        inherit providers;
      };
    };
  };
}
