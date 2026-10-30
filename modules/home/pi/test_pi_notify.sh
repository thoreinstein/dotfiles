#!/usr/bin/env bash
#
# test_pi_notify - self-check for pi-notify's terminal-notifier arguments.
#
# Usage: test_pi_notify.sh <path to pi-notify.ts>
# Needs node >= 22.18, which imports .ts directly by stripping types.
set -euo pipefail

node --input-type=module - "$1" <<'EOF'
import assert from "node:assert/strict";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

const { notifyArgs } = await import(pathToFileURL(resolve(process.argv[2])).href);

const flag = (args, f) => args[args.indexOf(f) + 1];

// Inside tmux: sound per outcome, one group per pane, Ghostty activated, click selects the pane
const a = notifyArgs("done", "✅ pi · dotfiles (main)", "Ready · 12s · 3 tools", { pane: "%7", tmux: "/nix/store/x/bin/tmux" });
assert.equal(flag(a, "-title"), "✅ pi · dotfiles (main)");
assert.equal(flag(a, "-message"), "Ready · 12s · 3 tools");
assert.equal(flag(a, "-sound"), "Glass");
assert.equal(flag(a, "-group"), "pi-%7");
assert.equal(flag(a, "-activate"), "com.mitchellh.ghostty");
const exec = flag(a, "-execute");
assert.match(exec, /^'\/nix\/store\/x\/bin\/tmux' select-pane -t '%7' && /);
assert.match(exec, /select-window -t '%7'/);
assert.match(exec, /switch-client -c "\$c" -t '%7'/);

assert.equal(flag(notifyArgs("failed", "t", "b", { pane: "%1", tmux: "/t" }), "-sound"), "Basso");
assert.equal(flag(notifyArgs("question", "t", "b", { pane: "%1", tmux: "/t" }), "-sound"), "Ping");
assert.equal(flag(notifyArgs("bogus", "t", "b", { pane: "%1", tmux: "/t" }), "-sound"), "Glass");

// Outside tmux: no click action, group falls back to the process
const b = notifyArgs("done", "t", "b", {});
assert.equal(b.includes("-execute"), false);
assert.equal(flag(b, "-group"), `pi-${process.pid}`);
assert.equal(flag(b, "-activate"), "com.mitchellh.ghostty");

// tmux missing from PATH even though TMUX_PANE is set: still no click action
assert.equal(notifyArgs("done", "t", "b", { pane: "%7" }).includes("-execute"), false);

console.log("pi-notify args: ok");
EOF
