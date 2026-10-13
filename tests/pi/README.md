# pi config golden files

Snapshots of each host's merged `programs.pi-coding-agent.settings`, `.models`, and the
`AGENTS.md` that the module deploys, asserted by `checks.aarch64-darwin.pi-config` in
`flake.nix`. Local `make check` runs it
(`nix flake check` picks up every `checks.<system>` for the current system), so an edit to
a host file that clobbers the shared baseline in `modules/home/pi/` fails the build instead
of silently shipping. CI (`.github/workflows/check.yml`) runs on `ubuntu-latest` with bare
`nix flake check`, which only evaluates `checks.x86_64-linux` — this check lives under
`checks.aarch64-darwin` and is silently skipped there. Adding a `macos-14` job to
`check.yml` would make it enforced in CI too; that's left as a deliberate choice for the
repo owner given the added runner cost.

These are generated, not hand-written. After an intentional settings change,
run `make golden` from the repo root (it runs `tests/pi/regen.sh`), review the
diff, and follow it with `make check` to confirm the new goldens actually match.

The diff is the review: if it shows more than you intended to change, the config
is wrong, not the golden.

`AGENTS.md` is snapshotted like the other two. Comparing the deployed file against
`modules/home/pi/AGENTS.md` in the check compares a store path with itself and always
passes, so the check reads the emitted artifact against these snapshots instead. A content
change to `modules/home/pi/AGENTS.md` therefore lands as a golden diff to be reviewed.

The `programs.pi-coding-agent` module itself is tested upstream in
home-manager's `tests/modules/programs/pi-coding-agent/`. These files test our
values, not the module.

`pi-config.tar.gz` — the original transcription of the work laptop's imperative
`settings.json` / `models.json` — was never git-tracked and has since been deleted.
`tests/pi/mac-1QFL40HG/` is now the only surviving record of those values.
