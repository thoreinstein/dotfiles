// @ts-nocheck -- Pi provides this API only when loading extensions.
import { appendFileSync, existsSync, mkdirSync, realpathSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { basename, dirname, join } from "node:path";
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

// Something inside a temp dir, so cleaning it up needs no yes. Fails closed: the parent must
// resolve on disk (following symlinks) to /tmp or pi's own temp dir, and anything the shell
// could expand or a symlink could redirect ($VAR, `..`, ~, braces, a trailing /) asks. A glob is
// fine below a temp dir, never directly in it: `/tmp/*` would take tmux's socket with it.
const TEMP_DIRS = [...new Set(["/tmp", tmpdir()].flatMap((d) => { try { return [realpathSync(d)]; } catch { return []; } }))];
function isTempPath(p) {
  if (!p.startsWith("/") || p.endsWith("/") || /[$`{}\\~]/.test(p)) return false;
  if (p.split("/").some((s) => s === ".." || s === ".")) return false;
  let parent;
  try { parent = realpathSync(dirname(p)); } catch { return false; }
  return TEMP_DIRS.some((d) => parent.startsWith(`${d}/`) || (parent === d && !/[*?[]/.test(basename(p))));
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
    const paths = args.filter((a) => !a.startsWith("-"));
    if (!paths.length || !paths.every(isTempPath)) hits.push([bin, bin]);
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
// `reason` and never asks. An entry with `match(args)` applies only when it returns true. A tool not
// listed here (or whose entry doesn't match) is allowed: pi sets no adapter `approveTools`.
// Prompts below were audited from each server's tools/list; IRREVERSIBLE and NOTIFIES/PAGES call out
// what can't be undone from pi or reaches other people.

// Kubernetes kinds as these tools take them: `Secret`, `secrets`, `v1/Secret`, `secret/name`, `pods,secrets`.
const isSecretKind = (v) => String(v ?? "").split(/[,\s]+/).some((t) => t.split(/[/.]/).some((p) => /^secrets?$/i.test(p)));
const SECRET = {
  rule: "k8s-secret-read",
  action: "deny",
  match: (args) => isSecretKind(args?.kind) || isSecretKind(args?.resourceType),
  reason: "Reading Secret values is blocked. If you need to know a Secret exists or what keys it has, tell the user and ask.",
};
const DAILY = {
  rule: "obsidian-daily",
  action: "deny",
  reason: "Daily/ is generated and read-only. Use mem_save to record work; use obsidian_read_note to read an existing daily note.",
};
const FIRESTORE_DELETE = {
  rule: "firestore-delete-blocked",
  action: "deny",
  reason: "Deleting Firestore databases and backups is blocked: tell the user what to delete and why; they will do it.",
};

export const MCP_POLICY = {
  glean_chat: {
    rule: "glean-chat",
    action: "deny",
    reason: "Glean chat returns an AI summary, not the source. Use glean_search to find the documents or Slack "
      + 'threads (use app: slack and channel or type: "direct message" for Slack), then glean_read_document on the '
      + "result URLs to get the full content. Quote messages verbatim with their author, timestamp and URL instead "
      + "of paraphrasing.",
  },
  glean_memory: { rule: "glean-memory", action: "deny", reason: "Glean Memory is not used. Use engram (mem_save / mem_search) for memory." },
  glean_upload_artifact: { rule: "glean-artifact", action: "prompt", reason: "publishes content to your Glean Library with a shareable link" },
  glean_update_artifact: { rule: "glean-artifact", action: "prompt", reason: "uploads a new version of a Glean artifact others may be viewing" },
  glean_share_artifact: { rule: "glean-share", action: "prompt", reason: "grants people or departments access to a Glean artifact; notify: true EMAILS them" },

  // jira (Atlassian: Jira + Confluence)
  jira_search: {
    rule: "jira-rovo-search",
    action: "deny",
    reason: "jira_search (Rovo Search) spends Rovo credits and is not used. Use jira_searchJiraIssuesUsingJql for Jira "
      + "issues and jira_searchConfluenceUsingCql for Confluence.",
  },
  jira_createJiraIssue: { rule: "jira-create-issue", action: "prompt", reason: "creates a Jira issue; NOTIFIES the assignee and watchers; no tool can delete it" },
  jira_editJiraIssue: { rule: "jira-edit-issue", action: "prompt", reason: "edits Jira issue fields; NOTIFIES watchers" },
  jira_addCommentToJiraIssue: { rule: "jira-comment", action: "prompt", reason: "adds a Jira comment, or overwrites one when commentId is set; NOTIFIES watchers and @mentions" },
  jira_transitionJiraIssue: { rule: "jira-transition", action: "prompt", reason: "changes Jira issue status; NOTIFIES watchers and can fire workflow automation" },
  jira_addWorklogToJiraIssue: { rule: "jira-worklog", action: "prompt", reason: "logs work time on a Jira issue, or overwrites a worklog when worklogId is set" },
  jira_createIssueLink: { rule: "jira-issue-link", action: "prompt", reason: "links two Jira issues; visible on both" },
  jira_createConfluencePage: { rule: "confluence-create-page", action: "prompt", reason: "publishes a Confluence page or blog post visible to others" },
  jira_updateConfluencePage: { rule: "confluence-update-page", action: "prompt", reason: "overwrites a Confluence page (old version kept in page history)" },
  jira_createConfluenceFooterComment: { rule: "confluence-comment", action: "prompt", reason: "posts a Confluence comment; NOTIFIES page watchers" },
  jira_createConfluenceInlineComment: { rule: "confluence-comment", action: "prompt", reason: "posts an inline Confluence comment; NOTIFIES page watchers" },

  // firehydrant
  "firehydrant_create-incident": { rule: "firehydrant-create-incident", action: "prompt", reason: "opens a FireHydrant incident: PAGES and NOTIFIES responders and starts incident workflows; IRREVERSIBLE" },
  "firehydrant_update-retrospective-field": { rule: "firehydrant-retro", action: "prompt", reason: "overwrites a field in a shared FireHydrant retrospective" },

  // gcp-devknowledge
  "gcp-devknowledge_answer_query": {
    rule: "devknowledge-answer",
    action: "deny",
    reason: "answer_query returns an AI summary, not the source. Use gcp-devknowledge_search_documents to find the docs, "
      + "then gcp-devknowledge_get_documents on the result names to get the full content, and quote it.",
  },

  // gcp-gke
  "gcp-gke_get_k8s_resource": SECRET,
  "gcp-gke_describe_k8s_resource": SECRET,
  "gcp-gke_create_cluster": { rule: "gke-cluster", action: "prompt", reason: "creates a billable GKE cluster" },
  "gcp-gke_update_cluster": { rule: "gke-cluster", action: "prompt", reason: "changes a GKE cluster; some updates recreate nodes" },
  "gcp-gke_cancel_operation": { rule: "gke-operation", action: "prompt", reason: "cancels an in-flight GKE operation; can leave an upgrade or resize half-done" },
  "gcp-gke_create_node_pool": { rule: "gke-node-pool", action: "prompt", reason: "creates a billable GKE node pool" },
  "gcp-gke_update_node_pool": { rule: "gke-node-pool", action: "prompt", reason: "changes a GKE node pool; some updates recreate nodes" },
  "gcp-gke_apply_k8s_manifest": { rule: "gke-k8s-write", action: "prompt", reason: "server-side applies a manifest to a live cluster" },
  "gcp-gke_patch_k8s_resource": { rule: "gke-k8s-write", action: "prompt", reason: "patches a live Kubernetes resource" },
  "gcp-gke_delete_k8s_resource": { rule: "gke-k8s-delete", action: "prompt", reason: "deletes a Kubernetes resource; IRREVERSIBLE" },

  // gcp-firestore
  "gcp-firestore_delete_database": FIRESTORE_DELETE,
  "gcp-firestore_delete_backup": FIRESTORE_DELETE,
  "gcp-firestore_add_document": { rule: "firestore-write", action: "prompt", reason: "writes a Firestore document" },
  "gcp-firestore_update_document": { rule: "firestore-write", action: "prompt", reason: "overwrites a Firestore document" },
  "gcp-firestore_delete_document": { rule: "firestore-delete", action: "prompt", reason: "deletes a Firestore document; IRREVERSIBLE" },
  "gcp-firestore_create_database": { rule: "firestore-database", action: "prompt", reason: "creates a billable Firestore database" },
  "gcp-firestore_update_database": { rule: "firestore-database", action: "prompt", reason: "changes Firestore database config" },
  "gcp-firestore_create_index": { rule: "firestore-index", action: "prompt", reason: "creates a Firestore composite index" },
  "gcp-firestore_delete_index": { rule: "firestore-delete", action: "prompt", reason: "deletes a Firestore index; queries that need it fail; IRREVERSIBLE" },
  "gcp-firestore_create_backup_schedule": { rule: "firestore-backup-schedule", action: "prompt", reason: "creates a Firestore backup schedule" },
  "gcp-firestore_update_backup_schedule": { rule: "firestore-backup-schedule", action: "prompt", reason: "changes a Firestore backup schedule" },
  "gcp-firestore_delete_backup_schedule": { rule: "firestore-delete", action: "prompt", reason: "deletes a Firestore backup schedule; backups stop" },

  // kubernetes
  kubernetes_configuration_view: {
    rule: "k8s-kubeconfig",
    action: "deny",
    reason: "Kubeconfig contents never go into model context. Use kubernetes_configuration_contexts_list to see context names and server URLs.",
  },
  kubernetes_resources_get: SECRET,
  kubernetes_resources_list: SECRET,
  kubernetes_pods_exec: { rule: "k8s-exec", action: "prompt", reason: "runs an arbitrary command inside a pod" },
  kubernetes_pods_run: { rule: "k8s-write", action: "prompt", reason: "starts a pod in the cluster" },
  kubernetes_resources_create_or_update: { rule: "k8s-write", action: "prompt", reason: "server-side applies a manifest; fields it omits are removed" },
  kubernetes_resources_scale: { rule: "k8s-write", action: "prompt", reason: "reads or CHANGES replica count" },
  kubernetes_pods_delete: { rule: "k8s-delete", action: "prompt", reason: "deletes a pod; IRREVERSIBLE" },
  kubernetes_resources_delete: { rule: "k8s-delete", action: "prompt", reason: "deletes a Kubernetes resource; IRREVERSIBLE" },

  // obsidian-mcp
  "obsidian-mcp_obsidian_get_daily_note": DAILY,
  "obsidian-mcp_obsidian_append_daily_log": DAILY,
  "obsidian-mcp_obsidian_create_note": { rule: "obsidian-write", action: "prompt", reason: "creates a vault note" },
  "obsidian-mcp_obsidian_append_note": { rule: "obsidian-write", action: "prompt", reason: "appends to a vault note" },
  "obsidian-mcp_obsidian_move_note": { rule: "obsidian-write", action: "prompt", reason: "moves or renames a note and rewrites links to it in other notes" },
  "obsidian-mcp_obsidian_update_frontmatter": { rule: "obsidian-write", action: "prompt", reason: "edits a note's frontmatter" },
  "obsidian-mcp_obsidian_replace_section": { rule: "obsidian-write", action: "prompt", reason: "overwrites a section of a note" },
  "obsidian-mcp_obsidian_insert_at_heading": { rule: "obsidian-write", action: "prompt", reason: "inserts into a note" },
  "obsidian-mcp_obsidian_replace_in_note": { rule: "obsidian-write", action: "prompt", reason: "edits text in a note" },
};

// The adapter treats `-`, `.` and `_` alike and also accepts `mcp__<server>__<tool>`.
const toolKey = (s) => String(s ?? "").toLowerCase().replace(/^mcp__(.+?)__/, "$1_").replace(/[-.]/g, "_");
const STRICTNESS = { allow: 0, prompt: 1, deny: 2 };

// The policy for a tool name as an agent wrote it and its args, or null. A bare name (`chat`) is
// matched by its `server`, or with no server against every entry, as the adapter resolves it across
// servers; when that matches more than one server's tool the strictest action wins.
export function mcpPolicy(tool, server, bare = true, args = {}) {
  const key = toolKey(tool);
  const names = (want) => Object.keys(MCP_POLICY).filter((k) => want(toolKey(k)));
  let candidates = names((k) => k === key);
  if (!candidates.length && server) candidates = names((k) => k === `${toolKey(server)}_${key}`);
  else if (!candidates.length && bare) candidates = names((k) => k.endsWith(`_${key}`));
  const applies = candidates.filter((k) => !MCP_POLICY[k].match || MCP_POLICY[k].match(args));
  const name = applies.sort((a, b) => STRICTNESS[MCP_POLICY[b].action] - STRICTNESS[MCP_POLICY[a].action])[0];
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

// Code searches that codegraph_explore usually answers better. A search counts only as the first
// stage of a pipeline, so `ps | grep x` filtering another command's output does not.
const SEARCHERS = new Set(["grep", "rg", "find", "fd", "ag"]);
export const CODEGRAPH_NUDGE = 'Indexed repo: codegraph_explore "<symbol or question>" returns source + callers in one call. Prefer it for code questions.';

export function codeSearch(toolName, input) {
  if (toolName === "grep" || toolName === "find") return true;
  if (toolName !== "bash") return false;
  return parse(String(input?.command ?? "")).some((pipeline) => {
    let t = strip(pipeline[0] ?? []);
    if (base(t[0] ?? "") === "rtk") t = t.slice(1);
    return SEARCHERS.has(base(t[0] ?? ""));
  });
}

// True when the git repo holding dir has a .codegraph/ index at its root. ~/.codegraph is
// codegraph's own state dir, so only the repo root counts, not any parent.
export function indexedRepo(dir) {
  for (let d = dir; d && d !== dirname(d); d = dirname(d)) {
    if (existsSync(join(d, ".git"))) return existsSync(join(d, ".codegraph"));
  }
  return false;
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
    const policy = mcpPolicy(request.prefixedToolName, request.serverName, false, request.args ?? {});
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
    const args = mcpArgs(proxied ? event.input.args : event.input);
    const policy = proxied ? mcpPolicy(event.input.tool, event.input.server, true, args) : mcpPolicy(event.toolName, undefined, false, args);
    if (policy) {
      const call = {
        args, origin: proxied ? "proxy" : "direct",
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

  // Nudge, never block: the search result goes through with a pointer to codegraph appended.
  pi.on("tool_result", async (event, ctx) => {
    if (!codeSearch(event.toolName, event.input) || !indexedRepo(ctx.cwd)) return;
    return { content: [...(event.content ?? []), { type: "text", text: CODEGRAPH_NUDGE }] };
  });
}
