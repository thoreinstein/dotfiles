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
