# pi Coding Agent Nix Config Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the pi coding agent's configuration under nix on both hosts, replacing two drifted imperative configs with a shared declarative baseline plus minimal per-host overrides.

**Architecture:** Use the upstream `programs.pi-coding-agent` home-manager module, following the existing `programs.codex` / `programs.opencode` pattern in `hosts/mac-1QFL40HG.nix`. A shared module at `modules/home/pi/` carries everything both machines agree on; each host file supplies only its provider and model. A global `AGENTS.md` lives beside the module as plain Markdown.

**Tech Stack:** nix flakes, nix-darwin, home-manager, `programs.pi-coding-agent` (home-manager upstream), `pkgs.pi-coding-agent` 0.83.0.

**Design spec:** `docs/superpowers/specs/2026-08-07-pi-agent-config-design.md`

## Global Constraints

- **Formatter is `nixpkgs-fmt`** (set in `flake.nix` `formatter`). Never alejandra or nixfmt. Run `make fmt` before committing.
- **2-space indentation** everywhere (`.editorconfig`).
- **New files must be `git add`ed before `make build`.** Flakes only see git-tracked files; an untracked `.nix` file produces `error: Path '...' in the repository ... is not tracked by Git`. This is the single most likely way to get stuck.
- **`make build` must be clean before `make switch`.** Never switch on a failing build.
- **Two hosts, two usernames:** `Jims-Mac-mini` → user `myers`; `mac-1QFL40HG` → user `jimmyers`. Both `aarch64-darwin`, so either host's config can be evaluated from either machine.
- **Do not modify** `~/.pi/agent/auth.json` or `~/.pi/agent/sessions/` — credentials and runtime state.
- **Do not add** `lastChangelogVersion` to any settings block. It is runtime state that pi writes itself.
- **Transcribe Bedrock model IDs verbatim.** `amazon-bedrock/us.anthropic.claude-opus-4-7` is pi's own provider-prefixed naming, not an Anthropic API model ID. Do not "correct" it.
- **Source data:** `pi-config.tar.gz` at the repo root. Extract to a temp dir to read it — never extract into the repo.

### Verification commands used throughout

Inspect the *merged* settings for a host without building or switching:

```bash
nix eval --json \
  '.#darwinConfigurations.Jims-Mac-mini.config.home-manager.users.myers.programs.pi-coding-agent.settings' \
  | python3 -m json.tool
```

Swap `Jims-Mac-mini`/`myers` for `mac-1QFL40HG`/`jimmyers` for the work laptop, and `.settings` for `.models` to inspect the provider config. This is the primary test in every task.

---

### Task 1: Shared module with baseline settings

Creates the module both hosts inherit and wires it into home-manager. After this task, pi is nix-managed on both machines with identical settings and no host-specific provider yet.

**Files:**
- Create: `modules/home/pi/default.nix`
- Modify: `modules/home/default.nix` (add `./pi` to the `imports` list)

**Interfaces:**
- Consumes: nothing.
- Produces: `programs.pi-coding-agent` configured with `enable`, `package`, `extraPackages`, and a `settings` attrset. Tasks 3 and 4 extend `programs.pi-coding-agent.settings` and `.models` from host files; nix merges those into this base.

- [ ] **Step 1: Read the source config**

```bash
D=$(mktemp -d)/pi && mkdir -p "$D" && tar -xzf pi-config.tar.gz -C "$D" && cat "$D/settings.json"
```

Expected: JSON containing `compaction`, `theme`, `packages` (13 entries), `enabledModels` (4 entries), `defaultProvider`, `defaultModel`, and `lastChangelogVersion`. Keep this terminal open — Task 4 needs `models.json` from the same directory.

- [ ] **Step 2: Create the shared module**

Create `modules/home/pi/default.nix`:

```nix
{ pkgs, ... }:
{
  programs.pi-coding-agent = {
    enable = true;

    # The npm: packages below are fetched by pi at runtime and need a package
    # manager on pi's PATH. The module wraps pi with --suffix, so an
    # interactive shell's own bun still takes precedence.
    extraPackages = [ pkgs.nodejs pkgs.bun ];

    settings = {
      compaction = {
        enabled = true;
        reserveTokens = 16384;
        keepRecentTokens = 20000;
      };

      theme = "rose-pine-dawn";
      hideThinkingBlock = true;
      collapseChangelog = true;
      quietStartup = true;
      enableInstallTelemetry = false;
      defaultThinkingLevel = "medium";

      # rose-pine-dawn above depends on the pi-rose-pine entry here.
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

Note there is deliberately no `lastChangelogVersion` and no `defaultProvider`/`defaultModel` — those come from the host files.

- [ ] **Step 3: Wire it into the imports list**

Find the line to add after:

```bash
grep -n "./nixvim" modules/home/default.nix
```

Add `./pi` on its own line immediately after `./nixvim`, matching the surrounding 4-space indentation inside the `imports = [ ... ];` list.

- [ ] **Step 4: Track the new files, then build**

```bash
git add modules/home/pi/default.nix modules/home/default.nix
make build 2>&1 | tail -20
```

Expected: build completes with a list of `building '/nix/store/...'` lines and no `error:`. If you see `Path 'modules/home/pi/default.nix' ... is not tracked by Git`, the `git add` was skipped.

- [ ] **Step 5: Verify the merged settings on both hosts**

```bash
for h in "Jims-Mac-mini:myers" "mac-1QFL40HG:jimmyers"; do
  IFS=: read -r host user <<< "$h"
  echo "=== $host ==="
  nix eval --json ".#darwinConfigurations.$host.config.home-manager.users.$user.programs.pi-coding-agent.settings" | python3 -m json.tool
done
```

Expected on **both** hosts, identically: `theme` is `"rose-pine-dawn"`, `defaultThinkingLevel` is `"medium"`, `compaction` has all three keys, `packages` has 13 entries, `enableInstallTelemetry` is `false`. There must be **no** `lastChangelogVersion` key and **no** `defaultProvider` key yet.

- [ ] **Step 6: Confirm the package and its PATH wrapper**

```bash
nix eval --raw '.#darwinConfigurations.Jims-Mac-mini.config.home-manager.users.myers.programs.pi-coding-agent.package.name'
```

Expected: `pi-coding-agent-0.83.0`. Then confirm `extraPackages` produced a wrapper:

```bash
p=$(nix build --no-link --print-out-paths '.#darwinConfigurations.Jims-Mac-mini.config.home-manager.users.myers.programs.pi-coding-agent.finalPackage' 2>/dev/null \
  || nix build --no-link --print-out-paths 'nixpkgs#pi-coding-agent')
grep -c "bun" "$p/bin/pi" 2>/dev/null || echo "wrapper is binary — inspect with: strings $p/bin/pi | grep bun"
```

Expected: a non-zero match for `bun`, confirming nix's bun is on pi's PATH. (`finalPackage` may not exist on this module; the fallback just shows the unwrapped package, in which case verify after `make switch` in Task 6 instead.)

- [ ] **Step 7: Format and commit**

```bash
make fmt
git add -A modules/home/
git commit -m "$(cat <<'EOF'
pi: codify shared agent settings in nix

pi was configured imperatively on both machines and the two configs had
drifted. Adds modules/home/pi/ using the upstream programs.pi-coding-agent
module, following the existing programs.codex / programs.opencode pattern.

Carries everything both hosts agree on: compaction, Rose Pine Dawn, quiet
startup, telemetry off, thinking level, and all 13 runtime packages. Host
files supply provider and model.

lastChangelogVersion is deliberately omitted — pi writes it at runtime, so
it is state rather than configuration.
EOF
)"
```

---

### Task 2: Global AGENTS.md

Adds machine-wide agent context. Separable from Task 1 because the prose is reviewable on its own — this is the file most likely to get edited by hand later.

**Files:**
- Create: `modules/home/pi/AGENTS.md`
- Modify: `modules/home/pi/default.nix` (add `context = ./AGENTS.md;`)

**Interfaces:**
- Consumes: the `programs.pi-coding-agent` block from Task 1.
- Produces: `~/.pi/agent/AGENTS.md` on both hosts.

- [ ] **Step 1: Write the context file**

Create `modules/home/pi/AGENTS.md`. Every line is a fact an agent cannot infer and will otherwise get wrong. Do not add prompt-style filler ("be concise", "think step by step") — this file applies to every project, so situational advice is wrong most of the time.

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

- [ ] **Step 2: Reference it from the module**

In `modules/home/pi/default.nix`, add this line immediately after the `extraPackages` line:

```nix
    context = ./AGENTS.md;
```

The option's type is `either lines path`, so passing a path makes home-manager copy the file rather than inline its text.

- [ ] **Step 3: Track and build**

```bash
git add modules/home/pi/AGENTS.md modules/home/pi/default.nix
make build 2>&1 | tail -10
```

Expected: clean build, no `error:`.

- [ ] **Step 4: Verify the file resolves to the real content**

```bash
p=$(nix eval --raw '.#darwinConfigurations.Jims-Mac-mini.config.home-manager.users.myers.programs.pi-coding-agent.context')
echo "resolved to: $p"
head -5 "$p"
```

Expected: a `/nix/store/...-AGENTS.md` path whose first lines are `# Agent Notes` and the "Global context for coding agents" sentence. If it prints the literal Markdown text instead of a path, the option received a string — confirm you wrote `./AGENTS.md` and not `"./AGENTS.md"`.

- [ ] **Step 5: Format and commit**

```bash
make fmt
git add -A modules/home/pi/
git commit -m "$(cat <<'EOF'
pi: add global AGENTS.md context

No machine-wide agent context existed for any tool — ~/.claude/CLAUDE.md is
a symlink to the Appiary bootloader outside this repo, and ./CLAUDE.md is
this repo's project notes.

Kept to facts an agent cannot infer and will otherwise get wrong: packages
come from nix rather than brew/npm, two hosts with two usernames, nvim is
declarative through nixvim, git identity lives in ~/.gitconfig.local with
signing on. Deliberately no prompt-style filler — a global file applies to
every project, so situational advice would be wrong most of the time.

Referenced as a path rather than an inline nix string so it stays editable
as plain Markdown.
EOF
)"
```

---

### Task 3: Mac mini host overrides

Gives the mini a working provider. Its current imperative config points at `claude-3-5-haiku-20241022`, retired 2026-02-19, which now returns 404 — so this task is a fix, not just a migration.

**Files:**
- Modify: `hosts/Jims-Mac-mini.nix`

**Interfaces:**
- Consumes: `programs.pi-coding-agent.settings` from Task 1.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Note the current file state**

```bash
cat hosts/Jims-Mac-mini.nix
```

Expected: `_:` followed by a body containing only the comment `# No per-host settings or context yet — add when ready.` You are replacing that placeholder comment.

- [ ] **Step 2: Add the overrides**

Replace the entire contents of `hosts/Jims-Mac-mini.nix` with:

```nix
_:
{
  programs.pi-coding-agent = {
    settings = {
      defaultProvider = "anthropic";
      defaultModel = "claude-opus-5";
    };

    # Explicitly empty so nix owns models.json and the stale `chicago` ollama
    # provider at 192.168.4.56 is cleared. No local models are run on this host.
    models.providers = { };
  };
}
```

No `enabledModels` — the Bedrock entries are work-only and the qwen entries need LM Studio.

- [ ] **Step 3: Build**

```bash
make build 2>&1 | tail -10
```

Expected: clean build. `hosts/Jims-Mac-mini.nix` is already tracked, so no `git add` is needed first.

- [ ] **Step 4: Verify the merge produced base + overrides**

```bash
nix eval --json '.#darwinConfigurations.Jims-Mac-mini.config.home-manager.users.myers.programs.pi-coding-agent.settings' | python3 -m json.tool
```

Expected: the Task 1 baseline **plus** `"defaultProvider": "anthropic"` and `"defaultModel": "claude-opus-5"`. The shared keys (`theme`, `packages`, `compaction`) must still be present — if they vanished, the host file replaced the base instead of merging.

- [ ] **Step 5: Resolve the empty-providers assumption**

This is the one uncertain piece in the design. The module writes `models.json` only when `models != { }`.

```bash
nix eval --json '.#darwinConfigurations.Jims-Mac-mini.config.home-manager.users.myers.programs.pi-coding-agent.models' | python3 -m json.tool
```

Expected: `{"providers": {}}`.

Then confirm the module actually emits the file:

```bash
nix eval --json '.#darwinConfigurations.Jims-Mac-mini.config.home-manager.users.myers.home.file' \
  --apply 'f: builtins.filter (n: builtins.match ".*pi/agent.*" n != null) (builtins.attrNames f)'
```

Expected: a list including `.../\.pi/agent/models.json`, `.../settings.json`, and `.../AGENTS.md`.

**If `models.json` is absent from that list**, the `!= { }` guard did not trip. Fall back: remove the `models.providers = { }` block from the host file, rebuild, and instead delete the stale file by hand after Task 6's switch — `rm ~/.pi/agent/models.json`. If you take this path, drop the `Jims-Mac-mini/models.json` golden and its two `compare` lines in Task 5 as well. Record which path you took in the commit message.

- [ ] **Step 6: Format and commit**

```bash
make fmt
git add hosts/Jims-Mac-mini.nix
git commit -m "$(cat <<'EOF'
pi: point the Mac mini at anthropic / claude-opus-5

This host's imperative config dated from April and set defaultModel to
claude-3-5-haiku-20241022, retired 2026-02-19 and now returning 404 — so
pi could not have worked here regardless.

Uses the anthropic credentials already in ~/.pi/agent/auth.json. models is
set to an explicitly empty providers map so nix owns models.json and the
stale `chicago` ollama provider at 192.168.4.56 goes away; no local models
run on this machine.
EOF
)"
```

---

### Task 4: Work laptop host overrides

Transcribes the LM Studio provider and model list from the tarball — the only genuinely host-specific part of the config.

**Files:**
- Modify: `hosts/mac-1QFL40HG.nix`

**Interfaces:**
- Consumes: `programs.pi-coding-agent.settings` from Task 1.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Re-read the source models.json**

```bash
D=$(mktemp -d)/pi && mkdir -p "$D" && tar -xzf pi-config.tar.gz -C "$D" && cat "$D/models.json"
```

Expected: a single `lm-studio` provider at `http://localhost:1234/v1` with two qwen models. The values below must match this file exactly.

- [ ] **Step 2: Add the pi block**

In `hosts/mac-1QFL40HG.nix`, add a `pi-coding-agent` entry inside the existing top-level `programs = { ... };` attrset. Place it alphabetically after the `opencode` block, matching the file's existing style. Find the insertion point with:

```bash
grep -n "opencode = {" hosts/mac-1QFL40HG.nix
```

Insert:

```nix
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
```

- [ ] **Step 3: Build**

```bash
make build 2>&1 | tail -10
```

Expected: clean build. This evaluates the *mini's* config; Step 4 evaluates the work laptop's.

- [ ] **Step 4: Verify the work laptop's merged config**

```bash
nix eval --json '.#darwinConfigurations.mac-1QFL40HG.config.home-manager.users.jimmyers.programs.pi-coding-agent.settings' | python3 -m json.tool
nix eval --json '.#darwinConfigurations.mac-1QFL40HG.config.home-manager.users.jimmyers.programs.pi-coding-agent.models' | python3 -m json.tool
```

Expected in `settings`: the Task 1 baseline plus `defaultProvider: "lm-studio"`, `defaultModel: "qwen/qwen3-coder-next"`, and the 4-entry `enabledModels` with the `us.anthropic.` IDs intact.

Expected in `models`: `providers.lm-studio` with `baseUrl`, `api`, `apiKey`, and a 2-element `models` list. Confirm `compat.thinkingFormat` is `"qwen-chat-template"` on the 35B entry and that `contextWindow` values are integers, not strings.

- [ ] **Step 5: Diff against the source of truth**

The generated JSON must match the tarball apart from the deliberately-dropped `lastChangelogVersion`:

```bash
D=$(mktemp -d)/pi && mkdir -p "$D" && tar -xzf pi-config.tar.gz -C "$D"
diff <(python3 -c "
import json;d=json.load(open('$D/settings.json'));d.pop('lastChangelogVersion',None);print(json.dumps(d,sort_keys=True,indent=2))
") <(nix eval --json '.#darwinConfigurations.mac-1QFL40HG.config.home-manager.users.jimmyers.programs.pi-coding-agent.settings' \
  | python3 -c "import json,sys;print(json.dumps(json.load(sys.stdin),sort_keys=True,indent=2))") \
  && echo "SETTINGS MATCH"
diff <(python3 -c "
import json;print(json.dumps(json.load(open('$D/models.json')),sort_keys=True,indent=2))
") <(nix eval --json '.#darwinConfigurations.mac-1QFL40HG.config.home-manager.users.jimmyers.programs.pi-coding-agent.models' \
  | python3 -c "import json,sys;print(json.dumps(json.load(sys.stdin),sort_keys=True,indent=2))") \
  && echo "MODELS MATCH"
```

Expected: both `SETTINGS MATCH` and `MODELS MATCH`. Any diff is a transcription error — fix it rather than accepting the difference.

- [ ] **Step 6: Format and commit**

```bash
make fmt
git add hosts/mac-1QFL40HG.nix
git commit -m "$(cat <<'EOF'
pi: add the work laptop's LM Studio provider

The LM Studio endpoint and its two qwen models are the only genuinely
host-specific part of the pi config, alongside the Bedrock entries in
enabledModels which need work AWS credentials.

Model IDs are transcribed verbatim. amazon-bedrock/us.anthropic.* is pi's
own provider-prefixed naming for its Bedrock integration, not an Anthropic
API model ID, so it is deliberately not rewritten. apiKey is the literal
placeholder from the source config, not a secret — the endpoint is
localhost-only.

Verified by diffing the generated JSON against the original settings.json
and models.json.
EOF
)"
```

---

### Task 5: Golden-file checks in `flake.checks`

Turns the per-task `nix eval` verification into a permanent assertion enforced by local `make check`. After this, editing a host file in a way that clobbers the shared baseline fails `make check`. Note: it does *not* fail CI on PRs — see Task 5's Interfaces note below.

The `programs.pi-coding-agent` **module** is already tested upstream (`home-manager/tests/modules/programs/pi-coding-agent/` covers `settings`, `models`, and `context = <path>` via the `nmt` framework). What is untested is whether *our values* are what we intend and whether the two hosts stay correctly differentiated — that is what this check pins.

**Files:**
- Create: `tests/pi/Jims-Mac-mini/settings.json`, `tests/pi/Jims-Mac-mini/models.json`
- Create: `tests/pi/mac-1QFL40HG/settings.json`, `tests/pi/mac-1QFL40HG/models.json`
- Create: `tests/pi/README.md`
- Modify: `flake.nix` (extend the `checks` output)

**Interfaces:**
- Consumes: the merged `programs.pi-coding-agent.settings` / `.models` from Tasks 1, 3, and 4.
- Produces: `checks.aarch64-darwin.pi-config`, run by local `make check`. `.github/workflows/check.yml` runs on `ubuntu-latest` with bare `nix flake check`, which only evaluates `checks.x86_64-linux` — it does not run this check. Adding a `macos-14` job would close that gap; left as a deliberate choice for the repo owner.

- [ ] **Step 1: Add the check to `flake.nix`**

`checks` is currently `forAllSystems (system: { pre-commit-check = ...; })` at `flake.nix:92`. `darwinConfigurations` exist only for `aarch64-darwin`, so the new check **must** be guarded — otherwise `nix flake check --all-systems` fails on the Linux systems. Replace the `checks` block with:

```nix
      # Pre-commit hooks configuration
      checks = forAllSystems (
        system:
        {
          pre-commit-check = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              statix.enable = true;
              deadnix.enable = true;
            };
          };
        }
        # darwinConfigurations only exist for aarch64-darwin.
        // nixpkgs.lib.optionalAttrs (system == "aarch64-darwin") {
          pi-config =
            let
              pkgs = nixpkgs.legacyPackages.${system};
              json = pkgs.formats.json { };
              piOf =
                host: user:
                self.darwinConfigurations.${host}.config.home-manager.users.${user}.programs.pi-coding-agent;
              mini = piOf "Jims-Mac-mini" "myers";
              work = piOf "mac-1QFL40HG" "jimmyers";
            in
            pkgs.runCommand "pi-config-golden" { } ''
              fail=0
              compare() {
                if diff -u "$1" "$2"; then
                  echo "ok   $3"
                else
                  echo "FAIL $3"
                  fail=1
                fi
              }
              compare ${./tests/pi/Jims-Mac-mini/settings.json} \
                      ${json.generate "settings.json" mini.settings} "Jims-Mac-mini settings"
              compare ${./tests/pi/Jims-Mac-mini/models.json} \
                      ${json.generate "models.json" mini.models} "Jims-Mac-mini models"
              compare ${./tests/pi/mac-1QFL40HG/settings.json} \
                      ${json.generate "settings.json" work.settings} "mac-1QFL40HG settings"
              compare ${./tests/pi/mac-1QFL40HG/models.json} \
                      ${json.generate "models.json" work.models} "mac-1QFL40HG models"
              if [ "$fail" -ne 0 ]; then
                echo "pi config drifted from tests/pi goldens. See tests/pi/README.md to regenerate."
                exit 1
              fi
              touch $out
            '';
        }
      );
```

`json.generate` is the same `pkgs.formats.json` generator the home-manager module uses, so the golden files are byte-comparable with what actually lands in `~/.pi/agent/`.

- [ ] **Step 2: Generate the golden files**

`(formats.json {}).generate` pipes `builtins.toJSON` through `jq .`, so `nix eval --json | jq .` reproduces it byte for byte. `jq` isn't in the devShell, so run it from nixpkgs:

```bash
for h in "Jims-Mac-mini:myers" "mac-1QFL40HG:jimmyers"; do
  IFS=: read -r host user <<< "$h"
  mkdir -p "tests/pi/$host"
  for a in settings models; do
    nix eval --json ".#darwinConfigurations.$host.config.home-manager.users.$user.programs.pi-coding-agent.$a" \
      | nix shell nixpkgs#jq -c jq . > "tests/pi/$host/$a.json"
  done
done
find tests/pi -type f | sort
```

Expected: four files. Note this generates goldens *from* the current config — so **read them before trusting them**. That is the whole point of the review gate in Step 4.

- [ ] **Step 3: Document regeneration**

Create `tests/pi/README.md`:

```markdown
# pi config golden files

Snapshots of each host's merged `programs.pi-coding-agent.settings` and `.models`,
asserted by `checks.aarch64-darwin.pi-config` in `flake.nix`. `make check` and CI
both run it, so an edit to a host file that clobbers the shared baseline in
`modules/home/pi/` fails the build instead of silently shipping.

These are generated, not hand-written. After an intentional settings change,
regenerate and review the diff:

```bash
for h in "Jims-Mac-mini:myers" "mac-1QFL40HG:jimmyers"; do
  IFS=: read -r host user <<< "$h"
  for a in settings models; do
    nix eval --json ".#darwinConfigurations.$host.config.home-manager.users.$user.programs.pi-coding-agent.$a" \
      | nix shell nixpkgs#jq -c jq . > "tests/pi/$host/$a.json"
  done
done
```

The diff is the review: if it shows more than you intended to change, the config
is wrong, not the golden.

The `programs.pi-coding-agent` module itself is tested upstream in
home-manager's `tests/modules/programs/pi-coding-agent/`. These files test our
values, not the module.
```

- [ ] **Step 4: Read the goldens before trusting them**

```bash
python3 -m json.tool < tests/pi/Jims-Mac-mini/settings.json
python3 -m json.tool < tests/pi/mac-1QFL40HG/models.json
cat tests/pi/Jims-Mac-mini/models.json
```

Verify by eye, against the design spec:
- Both hosts' `settings` share `theme: "rose-pine-dawn"`, `defaultThinkingLevel: "medium"`, 13 `packages`, the `compaction` block, `enableInstallTelemetry: false`
- Mini `settings`: `defaultProvider: "anthropic"`, `defaultModel: "claude-opus-5"`, **no** `enabledModels`
- Work `settings`: `defaultProvider: "lm-studio"`, `defaultModel: "qwen/qwen3-coder-next"`, 4 `enabledModels` with `us.anthropic.` intact
- Mini `models`: exactly `{"providers": {}}`
- Work `models`: `providers.lm-studio` with two qwen entries, integer `contextWindow`
- **No `lastChangelogVersion` anywhere**

A golden file that contains something you did not intend means the config is wrong. Fix the config and regenerate — never hand-edit a golden to make a check pass.

- [ ] **Step 5: Track everything and run the check**

```bash
git add tests/pi flake.nix
make check 2>&1 | tail -20
```

Expected: `all checks passed!`, and in the build log four `ok   <host> <attr>` lines. If the `pi-config` derivation is skipped entirely, confirm the `optionalAttrs` guard names `aarch64-darwin` exactly.

- [ ] **Step 6: Prove the check actually fails on drift**

A check that cannot fail is worthless. Verify it bites:

```bash
python3 -c "
import json,pathlib
p=pathlib.Path('tests/pi/Jims-Mac-mini/settings.json')
d=json.loads(p.read_text()); d['theme']='deliberately-wrong'
p.write_text(json.dumps(d,indent=2)+'\n')
"
make check 2>&1 | grep -E "FAIL|drifted" | head -5
```

Expected: `FAIL Jims-Mac-mini settings` and the drift message, with `make check` exiting non-zero. Then restore:

```bash
git checkout tests/pi/Jims-Mac-mini/settings.json
make check 2>&1 | tail -3
```

Expected: back to `all checks passed!`.

- [ ] **Step 7: Format and commit**

```bash
make fmt
git add -A tests/pi flake.nix
git commit -m "$(cat <<'EOF'
pi: assert the generated config against golden files

make build proves the config evaluates; it does not prove the values are the
ones intended, or that the two hosts stay correctly differentiated. Adds
checks.aarch64-darwin.pi-config comparing each host's merged settings and
models against snapshots in tests/pi, so a host-file edit that clobbers the
shared baseline in modules/home/pi/ fails make check and CI rather than
shipping silently.

Guarded with optionalAttrs to aarch64-darwin, since darwinConfigurations do
not exist for the Linux systems in the checks matrix and would otherwise
break nix flake check --all-systems.

Uses the same pkgs.formats.json generator as the home-manager module, so the
goldens are byte-comparable with what lands in ~/.pi/agent. The module itself
is already tested upstream in home-manager's tests/modules/programs/
pi-coding-agent — these snapshots test our values, not the module.

Verified the check fails on deliberately-corrupted goldens, not just passes
on correct ones.
EOF
)"
```

---

### Task 6: Apply and verify live

Applies the config, confirms the generated files landed correctly, and removes the transport artifact.

**Files:**
- Delete: `pi-config.tar.gz`

**Interfaces:**
- Consumes: all prior tasks.
- Produces: a working pi on this machine.

- [ ] **Step 1: Run the full gate**

```bash
make fmt
make check 2>&1 | tail -5
```

Expected: `all checks passed!` — this runs the `nixpkgs-fmt`, `statix`, and `deadnix` pre-commit hooks.

- [ ] **Step 2: Record the pre-switch state**

```bash
ls -la ~/.pi/agent/
```

Expected: `settings.json` and `models.json` as **real files** (not symlinks), plus `auth.json` and `sessions/`. Note this — Step 4 confirms the first two became symlinks and the last two did not change.

- [ ] **Step 3: Apply**

```bash
make switch
```

This needs an interactive sudo password. Expected: activation completes, and because `flake.nix:61` sets `backupFileExtension = ".bak"`, home-manager moves the existing real files aside rather than refusing to clobber them.

- [ ] **Step 4: Verify the generated files and the untouched ones**

```bash
echo "=== should be symlinks into /nix/store ==="
ls -la ~/.pi/agent/settings.json ~/.pi/agent/models.json ~/.pi/agent/AGENTS.md
echo "=== originals preserved ==="
ls -la ~/.pi/agent/*.bak
echo "=== must still be real files, unchanged ==="
ls -la ~/.pi/agent/auth.json && ls -d ~/.pi/agent/sessions
echo "=== settings content ==="
python3 -m json.tool < ~/.pi/agent/settings.json
echo "=== no runtime state leaked in ==="
grep -c lastChangelogVersion ~/.pi/agent/settings.json || echo "absent (correct)"
```

Expected: the three managed files are symlinks into `/nix/store`; `settings.json.bak` and `models.json.bak` hold the originals; `auth.json` is still a real file and `sessions/` is untouched; the settings JSON shows `theme: "rose-pine-dawn"`, `defaultProvider: "anthropic"`, `defaultModel: "claude-opus-5"`, 13 `packages`; and `lastChangelogVersion` is absent.

- [ ] **Step 5: Verify the binary and its PATH**

```bash
which pi && pi --version
strings "$(readlink -f "$(which pi)")" 2>/dev/null | grep -o '/nix/store/[a-z0-9]*-bun[^/]*' | head -1
```

Expected: `pi` resolves under `/etc/profiles/per-user/`, `--version` reports `0.83.0`, and a nix bun store path appears — confirming `extraPackages` put it on pi's PATH. Your interactive `bun` should still be `~/.bun/bin/bun`; check with `which bun`.

- [ ] **Step 6: Launch pi once**

Run `pi` interactively. Expected: starts quietly (no changelog wall), renders Rose Pine Dawn — which also proves the `pi-rose-pine` package installed from the `packages` list — and has read `AGENTS.md`. Ask it something that exercises the context, e.g. *"how would I add ripgrep to this machine?"*; a correct answer names the flake rather than `brew install`.

The first launch will fetch all 13 runtime packages and may take a minute. If a `npm:` package fails to install, confirm node and bun are on pi's PATH (Step 5).

- [ ] **Step 7: Remove the transport artifact and commit**

```bash
git rm --cached pi-config.tar.gz 2>/dev/null; rm -f pi-config.tar.gz
git status --short
git commit -q -am "$(cat <<'EOF'
pi: drop the config tarball now that nix owns the values

pi-config.tar.gz was a transport artifact for moving the work laptop's
settings.json and models.json into this repo. Both are now expressed in
nix and verified by diff against it, so the tarball has no further use.
EOF
)"
```

Expected: a clean `git status` afterwards. If `pi-config.tar.gz` was never tracked, the `git rm --cached` is a harmless no-op and `rm` alone removes it.

- [ ] **Step 8: Report what could not be verified here**

The work laptop's config was verified by evaluation only. Note explicitly in the final summary that these remain unconfirmed until someone runs `make switch` on `mac-1QFL40HG`:

- LM Studio actually answering on `localhost:1234`
- The Bedrock entries resolving with work AWS credentials
- pi 0.83.0 replacing the imperative 0.84.1 install without complaint

**Follow-up for whoever runs this on `mac-1QFL40HG`:** `modules/home/zsh.nix:106-118`
prepends `$HOME/.local/share/npm-global/bin` and `$HOME/.bun/bin` ahead of the nix profile
on `PATH`. The work laptop's imperative pi 0.84.1 likely lives under one of those, so after
`make switch`, `which pi` could still resolve to the old imperative binary instead of the
nix-wrapped one — meaning it would read the new nix-managed config but run without the
wrapper's `PI_SKIP_VERSION_CHECK=1`. Before switching, run `which -a pi` and uninstall any
imperative pi found under `~/.local/share/npm-global/bin` or `~/.bun/bin`. This is a
human step for the work laptop; do not fix the PATH order or uninstall anything as part of
this plan.

---

## Notes for the implementer

**If `make build` fails with a type error on `models` or `settings`:** both are `pkgs.formats.json` freeform options, so nested attrsets and lists merge normally — but a *list* in one file cannot merge with a list in another. `packages` and `enabledModels` are each set in exactly one place for this reason. Don't split a list across the shared module and a host file.

**If `theme` renders as the default rather than Rose Pine Dawn:** the theme ships in the `pi-rose-pine` entry of `packages`, fetched at runtime from git. Confirm it installed before suspecting the `theme` setting.

**Expect a pi downgrade on the work laptop**, 0.84.1 → 0.83.0. This is deliberate — see the spec's "On pi's version" section. Do not attempt to override the derivation; `npmDepsHash` is not `overrideAttrs`-safe and pi releases roughly every 2.7 days, so a vendored package definition goes stale within the week. The flake is updated weekly, which is the intended mechanism.
