{ lib, pkgs, ... }:
let
  pi = import ./pi/model.nix lib;

  # git2go v31 (go/common/pkg/git2go, used by saas/tools/forge) hard-errors
  # outside libgit2 v1.1–v1.3 and nixpkgs ships 1.9.x, so pin 1.3.2 here. The
  # nix darwin fixup phase gives the dylib an absolute install name, so Go
  # binaries linked via pkg-config record a resolvable store path and need no
  # rpath or DYLD_LIBRARY_PATH (the retired @rpath hand-build under
  # /usr/local/libgit2 needed both, and its CGO_LDFLAGS workaround leaked
  # -lgit2 into every cgo binary in the workspace — golangci-lint included).
  # HTTPS stays on Secure Transport (cmake's darwin default, matching the
  # hand-build); libssh2 is nix's 1.11.1 instead of the dead homebrew Cellar
  # path the hand-build pointed at.
  libgit2-for-git2go = pkgs.stdenv.mkDerivation {
    pname = "libgit2";
    version = "1.3.2";
    src = pkgs.fetchFromGitHub {
      owner = "libgit2";
      repo = "libgit2";
      rev = "a6c822e353e01f690728a082fe32f09b01b845c6"; # v1.3.2
      hash = "sha256-Ip0EMT6SRx9qWBelbCY4jsEoBayXF6Ov+SkQLJF6z7Y=";
    };
    nativeBuildInputs = [ pkgs.cmake pkgs.pkg-config ];
    buildInputs = [ pkgs.libssh2 pkgs.openssl pkgs.zlib pkgs.pcre2 ];
    cmakeFlags = [
      "-DUSE_SSH=ON"
      "-DREGEX_BACKEND=pcre2"
      "-DUSE_GSSAPI=OFF"
      "-DBUILD_SHARED_LIBS=ON"
      "-DBUILD_TESTS=OFF"
      # libgit2 1.3's test runner wants python even with BUILD_TESTS=OFF
      "-DBUILD_CLAR=OFF"
      "-DBUILD_CLI=OFF"
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
      (pi.mkModel {
        # Window sizes assumed from GLM53Flash, the other self-hosted model.
        id = "anthropic.Moonshot.KimiK31Pro";
        reasoning = true;
        input = [ "text" "image" ];
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
      libgit2-for-git2go
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

    # nix-darwin's per-user profile (/etc/profiles/per-user/<user>) links only
    # bin/etc/info/share — no lib — so expose the .pc through a stable home
    # path instead. The .pc carries absolute store-path libdir/include, so
    # pkg-config consumers link straight into the store and load the dylib by
    # its absolute install name; see ~/src/forgecloud/.envrc for the consumer.
    file.".local/lib/pkgconfig/libgit2.pc".source = "${libgit2-for-git2go}/lib/pkgconfig/libgit2.pc";

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
        # After omlx (mkBefore, in the host file) in pi's model picker.
        enabledModels = lib.mkOrder 1200 (pi.mkEnabledModels [ "polaris" ] { inherit polaris; });
        # The Smart aliases name their own level; match it instead of the global medium.
        # Kimi has no medium level (off/low/high/max), so the global default would miss.
        modelThinkingLevels = {
          "polaris/anthropic.Polaris.Model.Smart.High" = "high";
          "polaris/anthropic.Polaris.Model.Smart.Medium" = "medium";
          "polaris/anthropic.Polaris.Model.Smart.Low" = "low";
          "polaris/anthropic.Moonshot.KimiK31Pro" = "high";
        };
      };
      models.providers = { inherit polaris; };
    };
  };
}
