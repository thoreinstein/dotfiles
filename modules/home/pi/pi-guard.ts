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
function check(tokens) {
  const t = strip(tokens);
  if (!t.length) return [];
  const bin = base(t[0]), args = t.slice(1);
  const hits = [];
  if (bin === "git") {
    const sub = subcommand(args, GIT_OPT_ARG);
    if (args.includes("--no-verify")) hits.push(["git-no-verify", "git --no-verify skips hooks"]);
    if (GIT_ASK.has(sub)) hits.push([`git-${sub}`, `git ${sub}`]);
    else if (sub === "branch" && args.some((a) => /^-[dDmM]$/.test(a))) hits.push(["git-branch-delete", "git branch delete/rename"]);
    else if (sub === "worktree" && args.includes("remove")) hits.push(["git-worktree-remove", "git worktree remove"]);
    else if (sub === "reflog" && args.some((a) => a === "expire" || a === "delete")) hits.push(["git-reflog", "git reflog expire/delete"]);
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
  ...[...GIT_ASK].map((s) => [`git-${s}`, `git ${s}`, new RegExp(`\\bgit\\b[\\s\\S]*\\b${s}\\b`)]),
];

function isNested(stage, command) {
  const [raw0, ...rest] = stage;
  const bin = base((strip(stage)[0] ?? ""));
  return NESTED.test(command) || WRAPPERS.has(base(raw0)) || WRAPPERS.has(bin)
    || (bin === "find" && rest.some((a) => /^-(exec|execdir|ok|okdir|delete)$/.test(a)));
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

  pi.on("tool_call", async (event, ctx) => {
    const sid = ctx.sessionManager.getSessionId();
    if (event.toolName === "edit" || event.toolName === "write") runs.delete(sid);
    if (event.toolName !== "bash") return;

    const command = String(event.input.command ?? "");
    const stages = parse(command).flat();
    const hits = stages.flatMap(check);
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
      mkdirSync(dirname(LOG), { recursive: true });
      appendFileSync(LOG, JSON.stringify({
        timestamp: new Date().toISOString(),
        session_id: sid,
        tool: event.toolName,
        args: event.input,
        rules,
        last_user_message: lastUserMessage(ctx),
        agent_message: agentMessage(ctx.sessionManager.getBranch(), event.toolCallId, event.parentToolCallId),
        answer,
        auto: noVerify || !ctx.hasUI,
      }) + "\n");
    } catch (err) {
      // Failing closed beats running an unlogged call.
      return { block: true, reason: `pi-guard could not write ${LOG}: ${err}` };
    }

    if (answer === "deny") return { block: true, reason };
  });
}
