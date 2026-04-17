{ lib, ... }:
{
  programs = {
    gemini-cli.settings = lib.importJSON ./mac-1QFL40HG/gemini-cli/settings.json;

    codex.settings = lib.importTOML ./mac-1QFL40HG/codex/config.toml;

    opencode = {
      enable = true;
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
  };
}
