{ lib, pkgs, ... }:
let
  pi = import ./pi/model.nix lib;

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
in
{
  # Everything only the work machine needs. Lists and attrs merge into the shared modules.
  home = {
    packages = with pkgs; [
      codefresh
      # `gcloud components install` can't write to the nix store; declare components here.
      (google-cloud-sdk.withExtraComponents (
        with google-cloud-sdk.components;
        [
          gcloud-crc32c
          gke-gcloud-auth-plugin
        ]
      ))
      k9s
      (writeShellApplication {
        name = "gauth";
        # gcloud comes from PATH: the SDK above, with extra components.
        runtimeInputs = [ fzf coreutils gawk ];
        text = builtins.readFile ../../bin/.bin/gauth;
      })
    ];

    sessionVariables.K9S_CONFIG_DIR = "$HOME/.config/k9s";

    file = {
      ".pi/agent/skills/standup/SKILL.md".source = ./pi/skills/standup/SKILL.md;
      ".finicky.js".source = ./finicky.js;
      # Not programs.k9s: on darwin it writes to Library/Application Support, which K9S_CONFIG_DIR bypasses.
      ".config/k9s/config.yaml".source = ./k9s/config.yaml;
      ".config/k9s/aliases.yaml".source = ./k9s/aliases.yaml;
      ".config/k9s/skins/rose-pine.yaml".source = ./k9s/rose-pine.yaml;
    };
  };

  mcpServers = {
    jira = {
      type = "http";
      url = "https://mcp.atlassian.com/v1/mcp";
    };
    glean = {
      type = "http";
      url = "https://pingidentity-be.glean.com/mcp/default";
    };
    firehydrant = {
      type = "stdio";
      command = "bash";
      args = [
        "-c"
        ''exec npx -y firehydrant-mcp@0.0.4 start --transport stdio --api-key "$FIREHYDRANT_API_KEY"''
      ];
    };
  };

  programs = {
    starship.settings.custom.gcloud = {
      command = "echo $PROJECT_NAME";
      when = ''[ -n "$PROJECT_NAME" ]'';
      symbol = "󱇶 ";
      style = "bold blue";
      format = "[$symbol($output)]($style) ";
    };

    claude-code = {
      settings = {
        permissions.allow = [
          "mcp__jira__*"
          "mcp__glean__*"
          "mcp__firehydrant__*"
          "mcp__plugin_aic-ai_firehydrant__*"
        ];
        enabledPlugins = {
          "aic-ai@aic-ai" = true;
          "polaris@polaris" = true;
        };
      };
      skills.standup = ./pi/skills/standup/SKILL.md;
    };

    pi-coding-agent = {
      settings = {
        # Between the shared strata (default order) and k3 (mkAfter) in pi's model picker.
        enabledModels = lib.mkOrder 1200 (pi.mkEnabledModels [ "polaris" ] { inherit polaris; });
        # The Smart aliases name their own level; match it instead of the global medium.
        modelThinkingLevels = {
          "polaris/anthropic.Polaris.Model.Smart.High" = "high";
          "polaris/anthropic.Polaris.Model.Smart.Medium" = "medium";
          "polaris/anthropic.Polaris.Model.Smart.Low" = "low";
        };
      };
      models.providers = { inherit polaris; };
    };
  };
}
