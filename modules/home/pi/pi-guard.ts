// @ts-nocheck -- Pi provides this API only when loading extensions.
import { appendFileSync, mkdirSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const LOG = join(homedir(), ".pi", "agent", "guard-log.jsonl");
const LOOP_LIMIT = 3;

// Git subcommands that need a yes: commit, push, rebase, reset, plus everything else that
// rewrites history or discards work.
const GIT_ASK = new Set([
  "commit", "push", "rebase", "reset", "filter-branch", "filter-repo", "update-ref", "replace",
  "cherry-pick", "revert", "merge", "restore", "clean",
  // `git checkout <file>` discards edits and can't be told apart from a branch switch here.
  "checkout",
]);
// Global git options that take their value as the next token.
const GIT_OPT_ARG = new Set(["-C", "-c", "--git-dir", "--work-tree", "--namespace"]);
const TF = new Set(["terraform", "tofu", "terragrunt"]);
// Binaries whose first non-flag argument names the command family (git status vs git log).
const SUBCOMMANDED = new Set([...TF, "git", "gh", "gcloud", "kubectl", "docker", "nix", "make", "npm"]);
const NOISE = new Set(["cd", "export", "set", "source", ".", "true"]);

// Splits a bash command into pipelines of tokens, honouring quotes, so a quoted "rm" or
// "--no-verify" inside a commit message is not mistaken for a command.
function parse(cmd) {
  const commands = [];
  let pipeline = [], tokens = [], word = "", quote = "", inWord = false;
  const endWord = () => { if (inWord) tokens.push(word); word = ""; inWord = false; };
  const endStage = () => { endWord(); if (tokens.length) pipeline.push(tokens); tokens = []; };
  const endCommand = () => { endStage(); if (pipeline.length) commands.push(pipeline); pipeline = []; };
  for (let i = 0; i < cmd.length; i++) {
    const c = cmd[i];
    if (quote) {
      if (c === quote) quote = "";
      else if (c === "\\" && quote === '"' && i + 1 < cmd.length) word += cmd[++i];
      else word += c;
    } else if (c === "'" || c === '"') { quote = c; inWord = true; }
    else if (c === "\\" && i + 1 < cmd.length) { word += cmd[++i]; inWord = true; }
    else if (c === " " || c === "\t") endWord();
    else if (c === "\n" || c === ";") endCommand();
    else if (c === "&" || c === "|") {
      if (cmd[i + 1] === c) { i++; endCommand(); }
      else if (c === "|") endStage();
      else endCommand();
    } else { word += c; inWord = true; }
  }
  endCommand();
  return commands;
}

// Drops env assignments and wrappers so `FOO=1 sudo git commit` reads as `git commit`.
function strip(tokens) {
  let t = tokens;
  while (t.length && (/^\w+=/.test(t[0]) || ["sudo", "command", "env", "time", "nohup"].includes(t[0]))) t = t.slice(1);
  return t;
}

const base = (s) => s.split("/").pop();

function subcommand(args, optWithArg = new Set()) {
  for (let i = 0; i < args.length; i++) {
    if (optWithArg.has(args[i])) i++;
    else if (!args[i].startsWith("-")) return args[i];
  }
}

function family(tokens) {
  const t = strip(tokens);
  if (!t.length) return null;
  const bin = base(t[0]);
  if (NOISE.has(bin)) return null;
  const sub = SUBCOMMANDED.has(bin) ? subcommand(t.slice(1), bin === "git" ? GIT_OPT_ARG : undefined) : undefined;
  return sub ? `${bin} ${sub}` : bin;
}

// Rules that a single command stage trips: [name, why] pairs.
export function check(tokens) {
  const t = strip(tokens);
  if (!t.length) return [];
  const bin = base(t[0]), args = t.slice(1);
  const hits = [];
  if (bin === "git") {
    const sub = subcommand(args, GIT_OPT_ARG);
    if (args.includes("--no-verify")) hits.push(["git-no-verify", "git --no-verify skips hooks"]);
    if (sub === "commit" && args.includes("--amend")) hits.push(["git-amend", "git commit --amend REWRITES THE LAST COMMIT"]);
    if (GIT_ASK.has(sub)) hits.push([`git-${sub}`, `git ${sub}`]);
    else if (sub === "branch" && args.some((a) => /^-[dDmM]$/.test(a))) hits.push(["git-branch-delete", "git branch delete/rename"]);
    else if (sub === "worktree" && args.includes("remove")) hits.push(["git-worktree-remove", "git worktree remove"]);
    else if (sub === "reflog" && args.some((a) => a === "expire" || a === "delete")) hits.push(["git-reflog", "git reflog expire/delete"]);
    else if (sub === "stash" && args.some((a) => a === "drop" || a === "clear")) hits.push(["git-stash-drop", "git stash drop/clear"]);
    else if (sub === "switch" && args.some((a) => a === "--discard-changes" || a === "-f" || a === "--force")) hits.push(["git-switch-discard", "git switch that discards changes"]);
  } else if (bin === "rm" || bin === "rmdir") {
    hits.push([bin, bin]);
  } else if (TF.has(bin)) {
    if (args.includes("destroy")) hits.push(["terraform-destroy", `${bin} destroy`]);
    const i = args.indexOf("state");
    if (i >= 0 && args[i + 1] === "rm") hits.push(["terraform-state-rm", `${bin} state rm`]);
  } else if (bin === "gcloud" || bin === "gh") {
    const method = args.findIndex((a) => a === "-X" || a === "--method");
    if (args.some((a) => a === "delete" || a === "destroy" || a === "rm")
      || (method >= 0 && String(args[method + 1]).toUpperCase() === "DELETE"))
      hits.push([`${bin}-delete`, `${bin} subcommand that deletes`]);
  }
  return hits;
}

// The tokenizer cannot see inside another command, so when one is nested (a shell or exec
// wrapper, `find -exec`, `$(...)`, backticks, process substitution) the rules also run as
// regexes over the raw string, quotes included. This over-asks rather than letting one through.
const WRAPPERS = new Set([
  "bash", "sh", "zsh", "dash", "ksh", "fish", "eval", "exec", "xargs", "timeout", "nice", "ionice",
  "watch", "env", "ssh", "parallel", "su", "doas", "flock", "stdbuf", "setsid", "script", "busybox",
]);
const NESTED = /\$\(|`|<\(|>\(/;
const RAW_RULES = [
  ["git-no-verify", "git --no-verify skips hooks", /\bgit\b[\s\S]*--no-verify/],
  ["rm", "rm", /(^|[\s;&|(`"'])rm\b/],
  ["find-delete", "find -delete", /\bfind\b[\s\S]*\s-delete\b/],
  ["rmdir", "rmdir", /(^|[\s;&|(`"'])rmdir\b/],
  ["terraform-destroy", "terraform destroy", /\b(terraform|tofu|terragrunt)\b[\s\S]*\bdestroy\b/],
  ["terraform-state-rm", "terraform state rm", /\b(terraform|tofu|terragrunt)\b[\s\S]*\bstate\s+rm\b/],
  ["gcloud-delete", "gcloud subcommand that deletes", /\bgcloud\b[\s\S]*\b(delete|destroy|rm)\b/],
  ["gh-delete", "gh subcommand that deletes", /\bgh\b[\s\S]*(\b(delete|destroy|rm)\b|(-X|--method)\s*=?\s*DELETE)/i],
  ["git-amend", "git commit --amend REWRITES THE LAST COMMIT", /\bgit\b[\s\S]*\bcommit\b[\s\S]*--amend\b/],
  ["git-stash-drop", "git stash drop/clear", /\bgit\b[\s\S]*\bstash\s+(drop|clear)\b/],
  ["git-switch-discard", "git switch that discards changes", /\bgit\b[\s\S]*\bswitch\b[\s\S]*(--discard-changes|\s-f\b|--force)/],
  ...[...GIT_ASK].map((s) => [`git-${s}`, `git ${s}`, new RegExp(`\\bgit\\b[\\s\\S]*\\b${s}\\b`)]),
];

function isNested(stage, command) {
  const [raw0, ...rest] = stage;
  const bin = base((strip(stage)[0] ?? ""));
  return NESTED.test(command) || WRAPPERS.has(base(raw0)) || WRAPPERS.has(bin)
    || (bin === "find" && rest.some((a) => /^-(exec|execdir|ok|okdir|delete)$/.test(a)));
}

// Direct HTTP calls to APIs that have an MCP server, so the agent uses the tools instead.
// Tool names are what the pi MCP adapter exposes (server-prefixed) for the `jira` and
// `firehydrant` servers in modules/home/mcp.json, taken from each server's tools/list.
const HTTP_CLIENTS = new Set(["curl", "wget", "http", "https"]);
const MCP_TOOLS = {
  jira: [
    "jira_getJiraIssue", "jira_searchJiraIssuesUsingJql", "jira_createJiraIssue", "jira_editJiraIssue",
    "jira_addCommentToJiraIssue", "jira_getTransitionsForJiraIssue", "jira_transitionJiraIssue",
    "jira_getJiraIssueRemoteIssueLinks", "jira_getVisibleJiraProjects", "jira_getJiraProjectIssueTypesMetadata",
    "jira_getJiraIssueTypeMetaWithFields", "jira_lookupJiraAccountId", "jira_addWorklogToJiraIssue",
    "jira_getIssueLinkTypes", "jira_createIssueLink",
  ],
  firehydrant: [
    "firehydrant_list-incidents", "firehydrant_create-incident", "firehydrant_list-retros-by-incident",
    "firehydrant_update-retrospective-field", "firehydrant_list-alerts",
  ],
};
const API_NAME = { jira: "Atlassian (Jira)", firehydrant: "FireHydrant" };

function mcpServer(host) {
  if (host === "api.atlassian.com" || host.endsWith(".atlassian.net")) return "jira";
  if (host === "api.firehydrant.io") return "firehydrant";
  return null;
}

export function bypassReason(server) {
  return `Denied by pi-guard (mcp-bypass): do not call the ${API_NAME[server]} API directly. `
    + `Use the ${server} MCP tools through the mcp tool, e.g. mcp({ tool: "${MCP_TOOLS[server][0]}", args: { ... } }): `
    + `${MCP_TOOLS[server].join(", ")}. If none of these can do the job, stop and tell the user what you `
    + "needed instead of finding another route to the API.";
}

function toUrl(arg) {
  const a = arg.replace(/^--url=/, "");
  try {
    if (/^https?:\/\//i.test(a)) return new URL(a);
    if (!a.startsWith("-") && /^[\w.-]+\.[a-z]{2,}(:\d+)?([/?]|$)/i.test(a)) return new URL(`https://${a}`);
  } catch {}
  return null;
}

function httpMethod(client, args) {
  const flagValue = (flags) => {
    for (let i = 0; i < args.length; i++) {
      for (const f of flags) {
        if (args[i] === f) return args[i + 1];
        if (args[i].startsWith(`${f}=`)) return args[i].slice(f.length + 1);
        if (f === "-X" && args[i].startsWith("-X") && args[i].length > 2) return args[i].slice(2);
      }
    }
  };
  if (client === "curl") {
    const explicit = flagValue(["-X", "--request"]);
    if (explicit) return explicit.toUpperCase();
    if (args.some((a) => a === "-I" || a === "--head")) return "HEAD";
    if (args.some((a) => a === "-G" || a === "--get")) return "GET";
    if (args.some((a) => a === "-T" || a === "--upload-file")) return "PUT";
    if (args.some((a) => /^(-d|-F|--data(-\w+)?|--json|--form(-string)?)(=|$)/.test(a) || /^-[dF]./.test(a))) return "POST";
    return "GET";
  }
  if (client === "wget") {
    const explicit = flagValue(["--method"]);
    if (explicit) return explicit.toUpperCase();
    return args.some((a) => /^--post-(data|file)(=|$)/.test(a)) ? "POST" : "GET";
  }
  // httpie: http [flags] [METHOD] URL [ITEM...]; data items (key=value, key:=json) make it a POST.
  const positional = args.filter((a) => !a.startsWith("-"));
  if (/^[A-Z]+$/.test(positional[0] ?? "")) return positional[0];
  return positional.slice(1).some((a) => /^[^=:]+(:=|=(?!=))/.test(a)) ? "POST" : "GET";
}

// Requests in a bash command that go to a host covered by MCP_TOOLS: [{ server, host, path, method }].
// URLs held in a variable assigned earlier in the same command are expanded. Command
// substitutions, backticks and strings handed to a shell wrapper (`bash -c "..."`) are parsed as
// commands too; a quoted string given to anything else (`echo "curl ..."`) is not.
export function mcpBypass(command, vars = new Map(), depth = 0) {
  const expand = (s) => s.replace(/\$\{(\w+)\}|\$(\w+)/g, (m, a, b) => vars.get(a ?? b) ?? m);
  const found = [];
  for (const stage of parse(command.replace(/\$\(|`|<\(|>\(|\)/g, "\n")).flat()) {
    let t = stage;
    if (["export", "local", "declare", "readonly"].includes(t[0])) t = t.slice(1);
    for (const tok of t) {
      const m = /^(\w+)=([\s\S]*)$/.exec(tok);
      if (!m) break;
      vars.set(m[1], expand(m[2]));
    }
    const s = strip(stage);
    const wrapped = WRAPPERS.has(base(s[0] ?? ""));
    if (depth < 3) {
      for (const tok of s.slice(1)) {
        if (tok.includes("\n") || (wrapped && /\s/.test(tok))) found.push(...mcpBypass(tok, vars, depth + 1));
      }
    }
    const i = s.findIndex((a, j) => HTTP_CLIENTS.has(base(a)) && (j === 0 || wrapped));
    if (i < 0) continue;
    const client = base(s[i]) === "https" ? "http" : base(s[i]);
    const args = s.slice(i + 1).map(expand);
    for (const url of args.map(toUrl).filter(Boolean)) {
      const server = mcpServer(url.hostname.toLowerCase());
      if (server) found.push({ server, host: url.hostname, path: url.pathname + url.search, method: httpMethod(client, args) });
    }
  }
  return found;
}

// Policy for MCP tool calls, keyed on the tool name the pi MCP adapter resolves (`<server>_<tool>`).
// action: "allow" passes silently, "prompt" asks like a risky bash command, "deny" blocks with
// `reason` and never asks. A tool not listed here is left to the adapter.
export const MCP_POLICY = {
  glean_chat: {
    rule: "glean-chat",
    action: "deny",
    reason: "Glean chat returns an AI summary, not the source. Use glean_search to find the documents or Slack "
      + 'threads (use app: slack and channel or type: "direct message" for Slack), then glean_read_document on the '
      + "result URLs to get the full content. Quote messages verbatim with their author, timestamp and URL instead "
      + "of paraphrasing.",
  },
};

// The adapter treats `-`, `.` and `_` alike and also accepts `mcp__<server>__<tool>`.
const toolKey = (s) => String(s ?? "").toLowerCase().replace(/^mcp__(.+?)__/, "$1_").replace(/[-.]/g, "_");

// The policy for a tool name as an agent wrote it, or null. A bare name (`chat`) is matched by its
// `server`, or with no server against every entry, as the adapter resolves it across servers.
export function mcpPolicy(tool, server, bare = true) {
  const key = toolKey(tool);
  const find = (want) => Object.keys(MCP_POLICY).find(want);
  const name = find((k) => toolKey(k) === key)
    ?? (server ? find((k) => toolKey(k) === `${toolKey(server)}_${key}`) : bare ? find((k) => toolKey(k).endsWith(`_${key}`)) : undefined);
  return name ? { tool: name, ...MCP_POLICY[name] } : null;
}

function mcpArgs(args) {
  if (typeof args !== "string") return args ?? {};
  try { return JSON.parse(args); } catch { return { raw: args }; }
}

function appendLog(entry) {
  mkdirSync(dirname(LOG), { recursive: true });
  appendFileSync(LOG, JSON.stringify({ timestamp: new Date().toISOString(), ...entry }) + "\n");
}

function userText(entry) {
  const c = entry.message.content;
  return typeof c === "string" ? c : c.filter((b) => b.type === "text").map((b) => b.text).join("\n");
}

function lastUserMessage(ctx) {
  let latest = null;
  for (const e of ctx.sessionManager.getBranch()) {
    if (e.type === "message" && e.message.role === "user" && (!latest || e.timestamp >= latest.timestamp)) latest = e;
  }
  return latest ? userText(latest) : "";
}

const AGENT_MESSAGE_MAX = 1000;

// The text the assistant wrote in the same message as this tool call, last 1,000 characters,
// or null when that message has none. Calls made by another tool (a codemode script) never appear
// in the transcript, so they are matched through their parent call.
export function agentMessage(branch, toolCallId, parentToolCallId) {
  const id = parentToolCallId ?? toolCallId;
  for (const e of branch) {
    if (e.type !== "message" || e.message.role !== "assistant" || !Array.isArray(e.message.content)) continue;
    const blocks = e.message.content;
    if (!blocks.some((b) => b.type === "toolCall" && b.id === id)) continue;
    const text = blocks.filter((b) => b.type === "text").map((b) => b.text).join("\n").trim();
    return text ? text.slice(-AGENT_MESSAGE_MAX) : null;
  }
  return null;
}

export default function (pi: ExtensionAPI) {
  // Per-session run of identical command families; edits and writes count as progress.
  const runs = new Map();
  // The latest tool call, for MCP calls that reach only the adapter's approval event (no ctx there).
  let last = null;
  // MCP calls let through on a yes here, so the adapter's approval event doesn't ask again.
  const approved = new Map();

  // Applies an MCP_POLICY entry and logs it. Returns [answer, reason], answer "allow" or "deny".
  async function decideMcp(policy, call, ctx, entry) {
    if (policy.action === "allow") return ["allow"];
    let answer, reason;
    if (policy.action === "deny") [answer, reason] = ["deny", policy.reason];
    else if (!ctx?.hasUI) [answer, reason] = ["deny", "Denied by pi-guard: this MCP call needs confirmation and no UI is available."];
    else {
      const ok = await ctx.ui.confirm("pi-guard", `${policy.reason ?? policy.rule}\n\n${policy.tool} ${JSON.stringify(call.args)}`);
      [answer, reason] = [ok ? "allow" : "deny", "Denied by user via pi-guard."];
    }
    try {
      appendLog({
        ...entry,
        rules: [policy.rule],
        last_user_message: ctx ? lastUserMessage(ctx) : null,
        agent_message: ctx ? agentMessage(ctx.sessionManager.getBranch(), call.toolCallId, call.parentToolCallId) : null,
        mcp: { tool: policy.tool, args: call.args, origin: call.origin },
        answer,
        auto: policy.action === "deny" || !ctx?.hasUI,
      });
    } catch (err) {
      return ["deny", `pi-guard could not write ${LOG}: ${err}`];
    }
    return [answer, reason];
  }

  // Backstop for MCP calls pi's tool_call hook never sees (mcpScript, and any direct tool call
  // the hook missed). It can only allow or deny: the agent gets the adapter's own denial text.
  pi.events?.on("pi-mcp-adapter:tool-approval-request", (request) => {
    const policy = mcpPolicy(request.prefixedToolName, request.serverName, false);
    if (!policy || policy.action === "allow") return;
    const yes = approved.get(policy.tool) ?? 0;
    if (yes && (request.origin === "proxy" || request.origin === "direct")) {
      approved.set(policy.tool, yes - 1);
      request.claim(() => "allow_once");
      return;
    }
    request.claim(async () => {
      const call = { args: request.args ?? {}, origin: request.origin, toolCallId: last?.toolCallId, parentToolCallId: last?.parentToolCallId };
      const [answer] = await decideMcp(policy, call, last?.ctx, {
        session_id: last?.sid ?? null, tool: request.prefixedToolName, args: request.args,
      });
      return answer === "allow" ? "allow_once" : "deny";
    });
  });

  pi.on("tool_call", async (event, ctx) => {
    const sid = ctx.sessionManager.getSessionId();
    last = { sid, ctx, toolCallId: event.toolCallId, parentToolCallId: event.parentToolCallId };
    if (event.toolName === "edit" || event.toolName === "write") runs.delete(sid);

    // MCP calls through the `mcp` proxy tool, or a direct tool registered under its own name.
    const proxied = event.toolName === "mcp" && event.input?.tool;
    const policy = proxied ? mcpPolicy(event.input.tool, event.input.server) : mcpPolicy(event.toolName, undefined, false);
    if (policy) {
      const call = {
        args: mcpArgs(proxied ? event.input.args : event.input), origin: proxied ? "proxy" : "direct",
        toolCallId: event.toolCallId, parentToolCallId: event.parentToolCallId,
      };
      const [answer, reason] = await decideMcp(policy, call, ctx, { session_id: sid, tool: event.toolName, args: event.input });
      if (answer === "deny") return { block: true, reason };
      if (policy.action === "prompt") approved.set(policy.tool, (approved.get(policy.tool) ?? 0) + 1);
      return;
    }
    if (event.toolName !== "bash") return;

    const command = String(event.input.command ?? "");
    const stages = parse(command).flat();
    const hits = stages.flatMap(check);
    const requests = mcpBypass(command);
    if (requests.length) hits.push(["mcp-bypass", "direct call to an API that has an MCP server"]);
    if (stages.some((s) => isNested(s, command)) || NESTED.test(command)) {
      for (const [name, why, re] of RAW_RULES) {
        if (re.test(command) && !hits.some(([n]) => n === name)) hits.push([name, why]);
      }
    }

    const first = parse(command).map((p) => family(p[0])).find(Boolean);
    const run = runs.get(sid) ?? { key: null, count: 0 };
    if (first) {
      if (first === run.key) run.count++;
      else { run.key = first; run.count = 1; }
      runs.set(sid, run);
    }
    const looping = first && run.count > LOOP_LIMIT;
    if (looping) hits.push(["loop", `"${first}" ran ${run.count - 1} times in a row`]);
    if (!hits.length) return;

    const rules = hits.map(([name]) => name);
    const noVerify = rules.includes("git-no-verify");
    let answer, reason;
    if (noVerify) {
      answer = "deny";
      reason = "Denied by pi-guard: --no-verify is never allowed. Hooks must run; fix what the hook reports instead of skipping it.";
    } else if (requests.length) {
      answer = "deny";
      reason = [...new Set(requests.map((r) => r.server))].map(bypassReason).join("\n\n");
    } else if (!ctx.hasUI) {
      answer = "deny";
      reason = "Denied by pi-guard: this command needs confirmation and no UI is available.";
    } else {
      const ok = await ctx.ui.confirm("pi-guard", `${hits.map(([, why]) => why).join("; ")}\n\n${command}`);
      answer = ok ? "allow" : "deny";
      reason = "Denied by user via pi-guard.";
    }

    // A denied loop keeps its count so the retry asks again; an allowed one starts a new window.
    if (looping && answer === "allow") run.count = 0;

    try {
      appendLog({
        session_id: sid,
        tool: event.toolName,
        args: event.input,
        rules,
        last_user_message: lastUserMessage(ctx),
        agent_message: agentMessage(ctx.sessionManager.getBranch(), event.toolCallId, event.parentToolCallId),
        ...(requests.length && { requests: requests.map(({ host, path, method }) => ({ host, path, method })) }),
        answer,
        auto: noVerify || requests.length > 0 || !ctx.hasUI,
      });
    } catch (err) {
      // Failing closed beats running an unlogged call.
      return { block: true, reason: `pi-guard could not write ${LOG}: ${err}` };
    }

    if (answer === "deny") return { block: true, reason };
  });
}
