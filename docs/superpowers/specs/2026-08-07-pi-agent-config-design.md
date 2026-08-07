# Codifying the pi coding agent into nix — design

## Context

`pi-config.tar.gz` was dropped into the repo: the pi coding-agent config from the work
laptop (`settings.json` + `models.json`, owned by `jimmyers`). pi is currently configured
imperatively on both machines and the two configs have drifted apart — the work laptop is
on pi 0.84.1 with LM Studio and 13 plugins, while the Mac mini's config dates from April
(pi 0.70.6) and points at `claude-3-5-haiku-20241022`, **a model retired 2026-02-19 that
now returns 404**. Neither config is version-controlled.

Goal: bring pi under nix like `programs.codex` and `programs.opencode` already are, with a
shared baseline plus the minimum per-host difference.

## Findings that shaped the design

- **`programs.pi-coding-agent` exists upstream in home-manager** (`modules/programs/pi-coding-agent.nix`).
  It maps directly onto what we have: `settings` → `~/.pi/agent/settings.json`,
  `models` → `models.json`, plus `keybindings`, `context` → `AGENTS.md`, `configDir`,
  `package`, `extraPackages`. No custom module needed.
- **`lastChangelogVersion` is runtime state, not config** — the mini says `0.70.6`, the
  tarball `0.84.1`. pi writes it. It is omitted from nix; the practical cost is that the
  changelog marker doesn't persist, which `quietStartup` and `collapseChangelog` already mask.
- **No secrets involved.** `apiKey: "local-only"` is a placeholder for a localhost endpoint,
  and Bedrock authenticates via AWS env. `~/.pi/agent/auth.json` (anthropic credentials) and
  `sessions/` live in the same directory but are never touched — the module symlinks
  individual files, not the directory. agenix is not needed.
- **Existing files are backed up, not clobbered.** `flake.nix:61` sets
  `backupFileExtension = ".bak"`, so activation moves the mini's real `settings.json` and
  `models.json` aside and symlinks the generated ones.
- **Bedrock model IDs are transcribed verbatim.** `amazon-bedrock/us.anthropic.claude-opus-4-7`
  is pi's own provider-prefixed naming for its Bedrock integration, not an Anthropic API
  model ID. It is not "corrected" to `anthropic.claude-opus-5` form.
- **No global agent context exists on this machine today.** `~/.claude/CLAUDE.md` is a symlink
  to the Appiary bootloader (outside this repo, Claude-Code-specific); `./CLAUDE.md` is this
  repo's project notes. Nothing is machine-global.

## Decisions

| Decision | Choice |
|---|---|
| Scope | Shared base module + per-host overrides |
| Package | nix owns it (`pkgs.pi-coding-agent` 0.83.0) + `extraPackages` |
| Split | Everything shared except the LM Studio bits; drop the mini's ollama provider |
| Mini default | `anthropic` / `claude-opus-5` |
| Global AGENTS.md | Yes, as a path to a repo file |

**On pi's version.** The currently locked nixpkgs (2026-08-05) has 0.83.0, so the work
laptop is initially downgraded from 0.84.1. This is not a packaging gap — nixpkgs tracks pi
closely (master bumped to 0.84.0 on 2026-08-06, one day after upstream's release), and the
flake is updated roughly weekly, which keeps it current enough. Being a few days behind is
accepted deliberately.

**Overriding the derivation to chase latest was considered and rejected.** It isn't a
one-line bump: `src`, `npmDepsHash`, and a `modelData` npm tarball all need hashes, and
`overrideAttrs` doesn't work for `npmDepsHash` — it's a destructured argument to
`buildNpmPackage` (`build-npm-package/default.nix:28,58,71`) consumed before `mkDerivation`,
so overriding it silently does nothing. More decisively, pi shipped 8 releases in the 22 days
to 2026-08-07 (~one every 2.7 days), so a vendored package definition goes stale within the
week. Note also that the nixpkgs wrapper sets `PI_SKIP_VERSION_CHECK 1`, since a
nix-installed pi cannot self-update — that is inherent to nix owning the binary, not a bug.

## Architecture

`modules/home/pi/` as a directory with `default.nix` + `AGENTS.md`, matching how `./nixvim`
is already a directory in `modules/home/default.nix`.

```
modules/home/pi/default.nix   # shared: enable, package, extraPackages, settings, context
modules/home/pi/AGENTS.md     # global agent context (plain Markdown)
modules/home/default.nix      # + ./pi in imports
hosts/Jims-Mac-mini.nix       # anthropic / claude-opus-5, empty providers
hosts/mac-1QFL40HG.nix        # lm-studio provider, qwen default, enabledModels
```

### Shared — `modules/home/pi/default.nix`

```nix
{ pkgs, ... }:
{
  programs.pi-coding-agent = {
    enable = true;
    # The 10 npm: packages below are fetched by pi at runtime and need a
    # package manager on pi's PATH. --suffix, so an interactive shell's
    # own bun still wins.
    extraPackages = [ pkgs.nodejs pkgs.bun ];
    context = ./AGENTS.md;
    settings = {
      compaction = { enabled = true; reserveTokens = 16384; keepRecentTokens = 20000; };
      theme = "rose-pine-dawn";        # needs the pi-rose-pine package below
      hideThinkingBlock = true;
      collapseChangelog = true;
      quietStartup = true;
      enableInstallTelemetry = false;
      defaultThinkingLevel = "medium";
      packages = [
        "git:github.com/apmantza/pi-lens"
        "git:github.com/ferologics/pi-notify"
        "https://github.com/zenobi-us/pi-rose-pine.git"
        "npm:@joemccann/pi-exa"
        "npm:@juicesharp/rpiv-ask-user-question"
        "npm:@narumitw/pi-plan-mode"
        "npm:context-mode"
        "npm:pi-bash-live-view"
        "npm:pi-caveman"
        "npm:pi-continuous-learning"
        "npm:pi-mcp-adapter"
        "npm:pi-rtk-optimizer"
        "npm:pi-memory"
      ];
    };
  };
}
```

`lastChangelogVersion` is intentionally absent — see Findings.

### Mac mini — `hosts/Jims-Mac-mini.nix`

```nix
programs.pi-coding-agent = {
  settings = {
    defaultProvider = "anthropic";
    defaultModel = "claude-opus-5";
  };
  # Explicitly empty: clears the stale `chicago` ollama provider at
  # 192.168.4.56 rather than leaving models.json unmanaged.
  models.providers = { };
};
```

No `enabledModels` — the Bedrock entries are work-only, and the qwen entries need LM Studio.

**Assumption to verify at build time:** the module writes `models.json` only when
`models != { }`, so `models.providers = { }` should produce `{"providers":{}}` and take
ownership of the file. If that turns out not to write (or pi rejects an empty providers
map), fall back to leaving `models` unset and deleting the stale
`~/.pi/agent/models.json` on the mini by hand — the outcome is the same, just imperative.

### Work laptop — `hosts/mac-1QFL40HG.nix`

Added alongside the existing `codex` / `mcp` / `opencode` blocks:

```nix
programs.pi-coding-agent = {
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
```

### Global context — `modules/home/pi/AGENTS.md`

Machine- and user-level facts only. Every line is something an agent cannot infer and will
otherwise get wrong; no prompt-style filler ("be concise", "think step by step"), because a
global file applies to every project and situational advice is wrong most of the time.

```markdown
# Agent Notes

Global context for coding agents on this machine. Machine- and user-level facts only —
anything project-specific belongs in that project's own AGENTS.md or CLAUDE.md.

## Environment

- macOS, managed declaratively with nix-darwin + home-manager. Packages come from nix,
  not Homebrew or global npm. To add a tool, it goes in the flake — don't reach for
  `brew install`, `npm i -g`, or `pip install`.
- Two hosts, two usernames: `myers` (Mac mini) and `jimmyers` (work MacBook). Never
  hardcode `/Users/<name>`; use `$HOME` or the host's configured user.
- Dotfiles live in `~/src/thoreinstein/dotfiles` — a bare repo with per-branch worktrees,
  so the checkout you're in is one worktree among several.

## Tooling

- Editor is Neovim, configured through nixvim. It is fully declarative: there is no
  `lazy.nvim` and no runtime `:PlugInstall` — Neovim changes are nix expressions.
- Terminal is ghostty; multiplexer is tmux.
- Rose Pine theme, JetBrains Mono Nerd Font.

## Git

- Identity lives in `~/.gitconfig.local`, untracked. Don't write `user.name` /
  `user.email` into a repo's own config.
- Commit signing is on. A commit that fails to sign is a configuration problem to
  report, not a reason to pass `--no-gpg-sign`.
```

## Out of scope

- **agenix** — no secrets in this config.
- **`keybindings`** — the tarball has none; pi's defaults stand.
- **Converging bun** — nix's bun 1.3.13 goes on pi's PATH via `extraPackages`; the
  imperative `~/.bun` 1.3.10 stays for interactive use. Unifying them is a separate change.
- **The opencode `AGENTS.md` gap** — `hosts/mac-1QFL40HG.nix:88-92` sets
  `instructions = [ "AGENTS.md" ... ]` and no project `AGENTS.md` exists in this repo
  (it has `CLAUDE.md`). Pre-existing inconsistency, noted but not fixed here.
- **`hosts/mac-1QFL40HG/antigravity-cli/settings.json`** — a stray unreferenced file in the
  host directory, unrelated to pi.

## Verification

Per the repo's loop, after each step:

```bash
make build        # must be clean before switching
```

At the end:

```bash
make fmt
make check        # nixpkgs-fmt, statix, deadnix
make switch
```

Then verify against the live config:

1. **Generated files.** `~/.pi/agent/settings.json`, `models.json`, and `AGENTS.md` are
   symlinks into `/nix/store`. The pre-existing real files are present as `.bak`.
2. **Shared settings applied.** `settings.json` contains `theme: "rose-pine-dawn"`,
   `defaultThinkingLevel: "medium"`, the compaction block, and all 13 `packages`;
   it does **not** contain `lastChangelogVersion`.
3. **Per-host divergence.** On the mini, `defaultProvider` is `anthropic` and
   `defaultModel` is `claude-opus-5`, and `models.json` has an empty `providers` (no
   `chicago`). On the work laptop, `lm-studio` with the two qwen entries and the
   4-entry `enabledModels`.
4. **Untouched files.** `~/.pi/agent/auth.json` and `sessions/` are still real files
   with their original contents.
5. **Package and PATH.** `pi --version` reports 0.83.0. `node` and `bun` resolve from
   pi's wrapped PATH — confirm by grepping the wrapper for the nix bun store path.
6. **Runtime behavior.** Launch pi and confirm it starts quietly, renders Rose Pine
   Dawn (proves the `pi-rose-pine` package installed), and reads AGENTS.md.
7. **Cleanup.** `pi-config.tar.gz` is deleted from the repo.

Manual, needs a human at a terminal: step 6, and confirming the work laptop's
LM Studio provider actually connects on `localhost:1234`.
