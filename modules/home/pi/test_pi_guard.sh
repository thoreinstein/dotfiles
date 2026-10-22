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

const { default: guard, CODEGRAPH_NUDGE, MCP_POLICY, agentMessage, bypassReason, check, codeSearch, indexedRepo, mcpBypass, mcpPolicy } = await import(pathToFileURL(resolve(process.argv[2])).href);

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

// rm of paths inside a real temp dir doesn't ask; anything that could land elsewhere does
const fsm = await import("node:fs");
const osm = await import("node:os");
const tmp = fsm.mkdtempSync(join(osm.tmpdir(), "rm-"));
fsm.mkdirSync(join(tmp, "sub"));
fsm.symlinkSync("/", join(tmp, "link"));
assert.deepEqual(rules(`rm -rf ${tmp}/sub`), []);
assert.deepEqual(rules(`rm -rf ${tmp}/sub/*`), []);
assert.deepEqual(rules(`rmdir ${tmp}/sub`), []);
assert.deepEqual(rules(`rm ${tmp}/link`), []); // removes the link, not its target
assert.deepEqual(rules(`rm -rf ${tmp}/link/`), ["rm"]); // trailing / follows the link
assert.deepEqual(rules(`rm -rf ${tmp}/link/Users`), ["rm"]);
assert.deepEqual(rules(`rm -rf ${tmp}/missing/x`), ["rm"]);
assert.deepEqual(rules(`rm -rf ${tmp}/sub src`), ["rm"]);
assert.deepEqual(rules(`rm -rf ${tmp}/../x`), ["rm"]);
assert.deepEqual(rules(`rm -rf ${osm.tmpdir()}/*`), ["rm"]);
assert.deepEqual(rules("rm -rf /tmp"), ["rm"]);
assert.deepEqual(rules("rm -rf /tmp/$X"), ["rm"]);
assert.deepEqual(rules("TMPDIR=/Users rm -rf $TMPDIR/me"), ["rm"]);
assert.deepEqual(rules("rm -rf /tmp/{a,/Users}"), ["rm"]);
assert.deepEqual(rules("rm -rf $tmp"), ["rm"]);
assert.deepEqual(rules("rm -rf"), ["rm"]);
fsm.rmSync(tmp, { recursive: true });

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

// MCP tool names resolve the way the adapter resolves them
const policyOf = (...a) => mcpPolicy(...a)?.tool ?? null;
assert.equal(policyOf("glean_chat"), "glean_chat");
assert.equal(policyOf("glean-chat"), "glean_chat");
assert.equal(policyOf("mcp__glean__chat"), "glean_chat");
assert.equal(policyOf("chat", "glean"), "glean_chat");
assert.equal(policyOf("chat"), "glean_chat");
assert.equal(policyOf("chat", "other"), null);
assert.equal(policyOf("chat", undefined, false), null);
assert.equal(policyOf("glean_search"), null);
assert.equal(policyOf("glean_read_document"), null);

console.log("pi-guard mcp policy: ok");

// glean_chat is denied with no prompt on the proxy and direct paths; search and read_document pass
const GLEAN_CHAT = "Glean chat returns an AI summary, not the source. Use glean_search to find the documents or Slack "
  + 'threads (use app: slack and channel or type: "direct message" for Slack), then glean_read_document on the '
  + "result URLs to get the full content. Quote messages verbatim with their author, timestamp and URL instead "
  + "of paraphrasing.";
let mcpHandler, approval;
let confirms = 0;
guard({
  on: (event, fn) => { if (event === "tool_call") mcpHandler = fn; },
  events: { on: (event, fn) => { if (event === "pi-mcp-adapter:tool-approval-request") approval = fn; } },
});
const mcpCtx = {
  hasUI: true,
  ui: { confirm: async () => { confirms++; return true; } },
  sessionManager: { getSessionId: () => "sess-2", getBranch: () => [] },
};
const callTool = (toolName, input) => mcpHandler({ toolName, toolCallId: "t2", input }, mcpCtx);
const blocked = { block: true, reason: GLEAN_CHAT };
assert.deepEqual(await callTool("mcp", { tool: "glean_chat", args: { message: "what did ops decide?" } }), blocked);
assert.deepEqual(await callTool("mcp", { tool: "chat", server: "glean", args: '{"message":"as a string"}' }), blocked);
assert.deepEqual(await callTool("glean_chat", { message: "direct" }), blocked);
assert.equal(await callTool("mcp", { tool: "glean_search", args: { query: "deploy", app: "slack", channel: "ops" } }), undefined);
assert.equal(await callTool("mcp", { tool: "glean_read_document", args: { urls: ["https://x.slack.com/archives/C1/p1"] } }), undefined);
assert.equal(await callTool("mcp", { search: "glean chat" }), undefined);
assert.equal(confirms, 0);

// the approval backstop denies script calls the hook never saw, and leaves other tools alone
const broker = (prefixedToolName, origin, args = {}) => {
  let handler = null;
  approval({ serverName: "glean", prefixedToolName, originalToolName: prefixedToolName.replace(/^glean_/, ""), args, origin, claim: (h) => { handler = h; return true; } });
  return handler && handler();
};
assert.equal(await broker("glean_chat", "script", { message: "from a script" }), "deny");
assert.equal(broker("glean_search", "script"), null);
assert.equal(broker("glean_read_document", "proxy"), null);

const mcpLog = readFileSync(join(homedir(), ".pi", "agent", "guard-log.jsonl"), "utf8").trim().split("\n").map((l) => JSON.parse(l)).slice(2);
assert.deepEqual(mcpLog.map((e) => [e.session_id, e.tool, e.rules, e.mcp.args.message, e.mcp.origin, e.answer, e.auto]), [
  ["sess-2", "mcp", ["glean-chat"], "what did ops decide?", "proxy", "deny", true],
  ["sess-2", "mcp", ["glean-chat"], "as a string", "proxy", "deny", true],
  ["sess-2", "glean_chat", ["glean-chat"], "direct", "direct", "deny", true],
  ["sess-2", "glean_chat", ["glean-chat"], "from a script", "script", "deny", true],
]);

// a prompt entry asks once: the adapter's approval for the same call doesn't ask again
MCP_POLICY.test_tool = { rule: "test-prompt", action: "prompt", reason: "test tool" };
assert.equal(await callTool("mcp", { tool: "test_tool", args: {} }), undefined);
assert.equal(await broker("test_tool", "proxy"), "allow_once");
assert.equal(confirms, 1);
assert.equal(await broker("test_tool", "script"), "allow_once");
assert.equal(confirms, 2);
delete MCP_POLICY.test_tool;

console.log("pi-guard mcp policy handler: ok");

// Secret reads are denied on the four read tools; every other kind passes
const SECRET_DENY = "Reading Secret values is blocked. If you need to know a Secret exists or what keys it has, tell the user and ask.";
const secretRule = (tool, args) => mcpPolicy(tool, undefined, false, args)?.rule ?? null;
for (const kind of ["Secret", "secret", "SECRETS", "v1/Secret", "secret/db-creds", "pods,secrets"]) {
  assert.equal(secretRule("kubernetes_resources_get", { apiVersion: "v1", kind, name: "x" }), "k8s-secret-read", kind);
  assert.equal(secretRule("kubernetes_resources_list", { apiVersion: "v1", kind }), "k8s-secret-read", kind);
  assert.equal(secretRule("gcp-gke_get_k8s_resource", { resourceType: kind }), "k8s-secret-read", kind);
  assert.equal(secretRule("gcp-gke_describe_k8s_resource", { resourceType: kind, name: "x" }), "k8s-secret-read", kind);
}
for (const kind of ["Pod", "pods", "apps/v1/Deployment", "configmaps", "SecretProviderClass"]) {
  assert.equal(secretRule("kubernetes_resources_get", { apiVersion: "v1", kind }), null, kind);
  assert.equal(secretRule("gcp-gke_get_k8s_resource", { resourceType: kind }), null, kind);
}
assert.deepEqual(await callTool("mcp", { tool: "kubernetes_resources_get", args: { apiVersion: "v1", kind: "Secret", name: "db" } }),
  { block: true, reason: SECRET_DENY });
assert.deepEqual(await callTool("gcp-gke_describe_k8s_resource", { parent: "p", resourceType: "secrets", name: "db" }), { block: true, reason: SECRET_DENY });
assert.equal(await callTool("mcp", { tool: "kubernetes_resources_list", args: { apiVersion: "v1", kind: "Pod" } }), undefined);
assert.equal(await callTool("gcp-gke_get_k8s_resource", { parent: "p", resourceType: "deployments" }), undefined);
assert.equal(await broker("kubernetes_resources_get", "script", { apiVersion: "v1", kind: "Secret" }), "deny");
assert.equal(broker("kubernetes_resources_get", "script", { apiVersion: "v1", kind: "Pod" }), null);

console.log("pi-guard mcp secret reads: ok");

// a bare name shared by two servers takes the strictest matching action, whatever the table order
const bareRule = (tool) => mcpPolicy(tool)?.tool ?? null;
assert.equal(bareRule("search"), "jira_search");
MCP_POLICY.glean_search = { rule: "test-allow", action: "allow" };
assert.equal(bareRule("search"), "jira_search");
assert.equal(mcpPolicy("search", "glean").tool, "glean_search");
delete MCP_POLICY.glean_search;
assert.equal(bareRule("list_alerts"), null);
for (const [first, second] of [["firehydrant_list-alerts", "gcp-monitoring_list_alerts"], ["gcp-monitoring_list_alerts", "firehydrant_list-alerts"]]) {
  MCP_POLICY[first] = { rule: "test-prompt", action: "prompt", reason: "x" };
  MCP_POLICY[second] = { rule: "test-deny", action: "deny", reason: "x" };
  assert.equal(bareRule("list_alerts"), second);
  assert.equal(bareRule("list-alerts"), second);
  delete MCP_POLICY[first];
  delete MCP_POLICY[second];
}

console.log("pi-guard mcp bare-name collisions: ok");

// every entry in the table does what it says through the hook: deny blocks with its reason, prompt asks
assert.equal(MCP_POLICY.glean_memory.reason, "Glean Memory is not used. Use engram (mem_save / mem_search) for memory.");
assert.equal(MCP_POLICY["obsidian-mcp_obsidian_get_daily_note"].reason,
  "Daily/ is generated and read-only. Use mem_save to record work; use obsidian_read_note to read an existing daily note.");
assert.match(MCP_POLICY["gcp-firestore_delete_database"].reason, /tell the user what to delete and why; they will do it\.$/);
assert.match(MCP_POLICY.kubernetes_configuration_view.reason, /kubernetes_configuration_contexts_list/);
assert.match(MCP_POLICY.jira_search.reason, /jira_searchJiraIssuesUsingJql[\s\S]*jira_searchConfluenceUsingCql/);
assert.match(MCP_POLICY["gcp-devknowledge_answer_query"].reason, /gcp-devknowledge_search_documents[\s\S]*gcp-devknowledge_get_documents/);
for (const [tool, entry] of Object.entries(MCP_POLICY)) {
  if (entry.match) continue;
  const before = confirms;
  const result = await callTool("mcp", { tool, args: {} });
  if (entry.action === "deny") assert.deepEqual(result, { block: true, reason: entry.reason }, tool);
  else assert.equal(result, undefined, tool);
  assert.equal(confirms - before, entry.action === "prompt" ? 1 : 0, tool);
}

console.log("pi-guard mcp policy table: ok");

// codegraph nudge: code searches only, never another command's output being filtered
for (const command of ["grep -rn foo .", "rg foo", "find . -name '*.ts'", "fd foo", "ag foo",
  "/usr/bin/grep foo x", "FOO=1 rg foo", "rtk grep foo .", "cd src && rg foo", "rg foo | head"]) {
  assert.equal(codeSearch("bash", { command }), true, command);
}
for (const command of ["ps aux | grep node", "git log | rg fix", "cat x", 'echo "grep foo"', "git grep foo", ""]) {
  assert.equal(codeSearch("bash", { command }), false, command);
}
assert.equal(codeSearch("grep", { pattern: "foo" }), true);
assert.equal(codeSearch("find", { pattern: "*.ts" }), true);
assert.equal(codeSearch("read", { path: "x" }), false);

// only the repo root's .codegraph/ counts; a parent's (like ~/.codegraph) does not
const { mkdtempSync, mkdirSync: mkdir } = await import("node:fs");
const { tmpdir } = await import("node:os");
const scratch = mkdtempSync(join(tmpdir(), "nudge-"));
mkdir(join(scratch, ".codegraph"));
mkdir(join(scratch, "indexed", ".git"), { recursive: true });
mkdir(join(scratch, "indexed", ".codegraph"));
mkdir(join(scratch, "indexed", "src", "deep"), { recursive: true });
mkdir(join(scratch, "plain", ".git"), { recursive: true });
mkdir(join(scratch, "plain", "src"), { recursive: true });
assert.equal(indexedRepo(join(scratch, "indexed")), true);
assert.equal(indexedRepo(join(scratch, "indexed", "src", "deep")), true);
assert.equal(indexedRepo(join(scratch, "plain", "src")), false);
assert.equal(indexedRepo(join(scratch, "nogit")), false);

let resultHandler;
guard({ on: (event, fn) => { if (event === "tool_result") resultHandler = fn; } });
const result = (toolName, input, cwd) =>
  resultHandler({ toolName, input, content: [{ type: "text", text: "out" }] }, { cwd });
const indexed = join(scratch, "indexed", "src");
assert.deepEqual(await result("bash", { command: "rg foo" }, indexed),
  { content: [{ type: "text", text: "out" }, { type: "text", text: CODEGRAPH_NUDGE }] });
assert.deepEqual((await result("grep", { pattern: "foo" }, indexed)).content.at(-1).text, CODEGRAPH_NUDGE);
assert.equal(await result("bash", { command: "ps | grep x" }, indexed), undefined);
assert.equal(await result("bash", { command: "rg foo" }, join(scratch, "plain", "src")), undefined);

console.log("pi-guard codegraph nudge: ok");
EOF
