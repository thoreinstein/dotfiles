#!/usr/bin/env bash
#
# test_pi_guard - self-check for pi-guard's agent_message field.
#
# Usage: test_pi_guard.sh <path to pi-guard.ts>
# Needs node >= 22.18, which imports .ts directly by stripping types.
set -euo pipefail

# HOME points at a scratch dir so the handler test writes its guard-log.jsonl there.
HOME="$(mktemp -d)" node --input-type=module - "$1" <<'EOF'
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";

const { default: guard, agentMessage, bypassReason, check, mcpBypass } = await import(pathToFileURL(resolve(process.argv[2])).href);

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

// commands that discard uncommitted work ask; harmless neighbours don't
const rules = (cmd) => check(cmd.split(" ")).map(([name]) => name);
assert.deepEqual(rules("git checkout -- foo.nix"), ["git-checkout"]);
assert.deepEqual(rules("git checkout ."), ["git-checkout"]);
assert.deepEqual(rules("git stash drop"), ["git-stash-drop"]);
assert.deepEqual(rules("git stash clear"), ["git-stash-drop"]);
assert.deepEqual(rules("git switch --discard-changes main"), ["git-switch-discard"]);
assert.deepEqual(rules("git switch -f main"), ["git-switch-discard"]);
assert.deepEqual(rules("git stash"), []);
assert.deepEqual(rules("git stash pop"), []);
assert.deepEqual(rules("git switch main"), []);

// --amend is called out on its own, ahead of the plain commit prompt
assert.deepEqual(rules("git commit --amend --no-edit"), ["git-amend", "git-commit"]);
assert.deepEqual(rules("git commit -m fix"), ["git-commit"]);

console.log("pi-guard check: ok");

// direct calls to APIs that have an MCP server are found, with host, path and method
const bypass = (cmd) => mcpBypass(cmd).map(({ server, host, path, method }) => `${server} ${method} ${host}${path}`);
assert.deepEqual(bypass("curl -s https://acme.atlassian.net/rest/api/3/issue/OPS-1"),
  ["jira GET acme.atlassian.net/rest/api/3/issue/OPS-1"]);
assert.deepEqual(bypass("curl -X POST -H 'Content-Type: application/json' https://api.atlassian.com/ex/jira/abc/rest/api/3/search?jql=x -d '{}'"),
  ["jira POST api.atlassian.com/ex/jira/abc/rest/api/3/search?jql=x"]);
assert.deepEqual(bypass('curl -H "Authorization: Bearer $FH" https://api.firehydrant.io/v1/incidents'),
  ["firehydrant GET api.firehydrant.io/v1/incidents"]);

// a URL held in a variable earlier in the same command
assert.deepEqual(bypass('URL=https://api.firehydrant.io/v1/incidents; curl -s "$URL?page=2"'),
  ["firehydrant GET api.firehydrant.io/v1/incidents?page=2"]);
assert.deepEqual(bypass("export SITE=acme.atlassian.net && curl -d x https://${SITE}/rest/api/3/issue"),
  ["jira POST acme.atlassian.net/rest/api/3/issue"]);

// wget and httpie
assert.deepEqual(bypass("wget -qO- https://api.firehydrant.io/v1/incidents"), ["firehydrant GET api.firehydrant.io/v1/incidents"]);
assert.deepEqual(bypass("wget --method=DELETE https://acme.atlassian.net/rest/api/3/issue/OPS-1"),
  ["jira DELETE acme.atlassian.net/rest/api/3/issue/OPS-1"]);
assert.deepEqual(bypass("http GET api.firehydrant.io/v1/incidents Authorization:x"), ["firehydrant GET api.firehydrant.io/v1/incidents"]);
assert.deepEqual(bypass("https acme.atlassian.net/rest/api/3/issue summary=hi"), ["jira POST acme.atlassian.net/rest/api/3/issue"]);

// nested in a substitution or a shell wrapper
assert.deepEqual(bypass('echo "$(curl -s https://api.firehydrant.io/v1/alerts)"'), ["firehydrant GET api.firehydrant.io/v1/alerts"]);
assert.deepEqual(bypass("bash -c 'curl https://api.firehydrant.io/v1/alerts'"), ["firehydrant GET api.firehydrant.io/v1/alerts"]);

// other hosts, and commands that only mention a matching host, pass
assert.deepEqual(bypass("curl -s https://api.github.com/repos/x/y"), []);
assert.deepEqual(bypass("curl https://atlassian.net.evil.example/rest"), []);
assert.deepEqual(bypass("echo api.firehydrant.io"), []);
assert.deepEqual(bypass("grep -rn acme.atlassian.net ."), []);
assert.deepEqual(bypass('git commit -m "deny curl to api.firehydrant.io"'), []);
assert.deepEqual(rules("echo api.firehydrant.io"), []);

console.log("pi-guard mcp-bypass: ok");

// the handler denies without prompting and logs host, path, method and session
let handler;
guard({ on: (event, fn) => { if (event === "tool_call") handler = fn; } });
const ctx = {
  hasUI: true,
  ui: { confirm: () => { throw new Error("mcp-bypass must not prompt"); } },
  sessionManager: { getSessionId: () => "sess-1", getBranch: () => [] },
};
const run = (command) => handler({ toolName: "bash", toolCallId: "t1", input: { command } }, ctx);
assert.deepEqual(await run("curl https://acme.atlassian.net/rest/api/3/issue/OPS-1"), { block: true, reason: bypassReason("jira") });
assert.deepEqual(await run("curl -X PATCH https://api.firehydrant.io/v1/incidents/42"), { block: true, reason: bypassReason("firehydrant") });
assert.equal(await run("echo api.firehydrant.io"), undefined);
assert.match(bypassReason("jira"), /jira_getJiraIssue, jira_searchJiraIssuesUsingJql,[\s\S]*stop and tell the user/);
assert.match(bypassReason("firehydrant"), /firehydrant_list-incidents, firehydrant_create-incident,/);

const log = readFileSync(join(homedir(), ".pi", "agent", "guard-log.jsonl"), "utf8").trim().split("\n").map((l) => JSON.parse(l));
assert.equal(log.length, 2);
assert.deepEqual(log.map((e) => [e.session_id, e.rules, e.requests, e.answer, e.auto]), [
  ["sess-1", ["mcp-bypass"], [{ host: "acme.atlassian.net", path: "/rest/api/3/issue/OPS-1", method: "GET" }], "deny", true],
  ["sess-1", ["mcp-bypass"], [{ host: "api.firehydrant.io", path: "/v1/incidents/42", method: "PATCH" }], "deny", true],
]);

console.log("pi-guard mcp-bypass handler: ok");
EOF
