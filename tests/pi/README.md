# pi config golden files

Snapshots of each host's merged `programs.pi-coding-agent.settings` and `.models`,
asserted by `checks.aarch64-darwin.pi-config` in `flake.nix`. Local `make check` runs it
(`nix flake check` picks up every `checks.<system>` for the current system), so an edit to
a host file that clobbers the shared baseline in `modules/home/pi/` fails the build instead
of silently shipping. CI (`.github/workflows/check.yml`) runs on `ubuntu-latest` with bare
`nix flake check`, which only evaluates `checks.x86_64-linux` — this check lives under
`checks.aarch64-darwin` and is silently skipped there. Adding a `macos-14` job to
`check.yml` would make it enforced in CI too; that's left as a deliberate choice for the
repo owner given the added runner cost.

These are generated, not hand-written. After an intentional settings change,
regenerate and review the diff. Run this from the repo root (the relative
`tests/pi/$host` paths depend on it), and follow it with `make check` to confirm the
new goldens actually match:

```bash
for h in "Jims-Mac-mini:myers" "mac-1QFL40HG:jimmyers"; do
  IFS=: read -r host user <<< "$h"
  mkdir -p "tests/pi/$host"
  for a in settings models; do
    nix eval --json ".#darwinConfigurations.$host.config.home-manager.users.$user.programs.pi-coding-agent.$a" \
      | nix shell nixpkgs#jq -c jq . > "tests/pi/$host/$a.json"
  done
done
```

(`nix shell nixpkgs#jq` resolves against the registry's nixpkgs, not this flake's locked
input — fine for formatting output, just not hermetic.) The `mkdir -p` matters: without it,
a third host's first run fails the redirect silently rather than erroring loudly.

The diff is the review: if it shows more than you intended to change, the config
is wrong, not the golden.

The `programs.pi-coding-agent` module itself is tested upstream in
home-manager's `tests/modules/programs/pi-coding-agent/`. These files test our
values, not the module.

`pi-config.tar.gz` — the original transcription of the work laptop's imperative
`settings.json` / `models.json` — was never git-tracked and has since been deleted.
`tests/pi/mac-1QFL40HG/` is now the only surviving record of those values.
