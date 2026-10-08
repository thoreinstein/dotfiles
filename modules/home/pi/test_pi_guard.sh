#!/usr/bin/env bash
#
# test_pi_guard - self-check for pi-guard's agent_message field.
#
# Usage: test_pi_guard.sh <path to pi-guard.ts>
# Needs node >= 22.18, which imports .ts directly by stripping types.
set -euo pipefail

node --input-type=module - "$1" <<'EOF'
import assert from "node:assert/strict";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

const { agentMessage } = await import(pathToFileURL(resolve(process.argv[2])).href);

const call = (id) => ({ type: "toolCall", id, name: "bash", arguments: {} });
const reply = (...content) => ({ type: "message", message: { role: "assistant", content } });

// short text is kept whole
assert.equal(agentMessage([reply({ type: "text", text: "running it" }, call("a"))], "a"), "running it");

// long text keeps only the last 1,000 characters
const long = "x".repeat(500) + "y".repeat(1000);
const kept = agentMessage([reply({ type: "text", text: long }, call("a"))], "a");
assert.equal(kept.length, 1000);
assert.equal(kept, "y".repeat(1000));

// no text, whitespace-only text, and no matching call all give null
assert.equal(agentMessage([reply(call("a"))], "a"), null);
assert.equal(agentMessage([reply({ type: "text", text: " \n " }, call("a"))], "a"), null);
assert.equal(agentMessage([reply({ type: "text", text: "hi" }, call("a"))], "other"), null);
assert.equal(agentMessage([], "a"), null);

// the message that issued this call wins, not the latest one
const branch = [
  reply({ type: "text", text: "first" }, call("a")),
  { type: "message", message: { role: "toolResult", content: [{ type: "text", text: "out" }] } },
  reply({ type: "text", text: "second" }, call("b")),
];
assert.equal(agentMessage(branch, "a"), "first");

// a call made by another tool is matched through its parent
assert.equal(agentMessage(branch, "b/1", "b"), "second");

// several text blocks join in order
assert.equal(agentMessage([reply({ type: "text", text: "one" }, { type: "text", text: "two" }, call("a"))], "a"), "one\ntwo");

console.log("pi-guard agent_message: ok");
EOF
