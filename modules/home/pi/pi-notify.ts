// @ts-nocheck -- Pi provides this API only when loading extensions.
import { execFile, execFileSync } from "node:child_process";
import { accessSync, constants } from "node:fs";
import { basename, delimiter, join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Desktop notification whenever pi is waiting on me: a run has fully settled, or a blocking
// prompt opened. TUI only, so `pi -p` output stays clean.
//
// Delivered with terminal-notifier (a native macOS notification, as the Claude Code
// notifications plugin does), so it shows whether or not the pane, tmux window or terminal
// is in front. The OSC 777 escape it replaces passed through tmux fine, but Ghostty only turns
// that into a desktop notification while its window is unfocused, so a run finishing in
// another tmux window never showed. Clicking the notification brings Ghostty forward and
// selects the pane. OSC 777 stays as the fallback where terminal-notifier is missing.

const GHOSTTY = "com.mitchellh.ghostty";
// macOS system sounds (/System/Library/Sounds), one per outcome.
const SOUND = { done: "Glass", failed: "Basso", question: "Ping" };

const onPath = (name) => (process.env.PATH ?? "").split(delimiter).map((d) => join(d, name))
  .find((p) => { try { accessSync(p, constants.X_OK); return true; } catch { return false; } });
const notifier = onPath("terminal-notifier");
const pane = process.env.TMUX_PANE; // "%12": stable for the pane's life, safe to quote
const tmux = pane && onPath("tmux");

// OSC 777 separates fields with ";" and ends at BEL, so neither may appear in the text.
const clean = (s) => s.replace(/[\x00-\x1f\x7f]+/g, " ").replace(/;/g, ",").trim();
const clip = (s, n) => (s.length > n ? `${s.slice(0, n - 1)}…` : s);

// terminal-notifier arguments for one notification. Exported for the self-test.
export function notifyArgs(kind, title, body, { pane, tmux } = {}) {
  const args = ["-title", title, "-message", body, "-sound", SOUND[kind] ?? SOUND.done, "-group", `pi-${pane ?? process.pid}`, "-activate", GHOSTTY];
  if (pane && tmux) {
    // Select the pane and its window, then point every attached client at that session.
    args.push("-execute", `'${tmux}' select-pane -t '${pane}' && '${tmux}' select-window -t '${pane}' && for c in $('${tmux}' list-clients -F '#{client_name}'); do '${tmux}' switch-client -c "$c" -t '${pane}'; done`);
  }
  return args;
}

function sendOsc(title, body) {
  let seq = `\x1b]777;notify;${clean(title)};${clean(body)}\x07`;
  // tmux passthrough: wrap in DCS and double inner ESC bytes.
  if (process.env.TMUX) seq = `\x1bPtmux;${seq.split("\x1b").join("\x1b\x1b")}\x1b\\`;
  process.stdout.write(seq);
}

export function send(kind, title, body) {
  if (!notifier) return sendOsc(title, body);
  // Fire and forget: a notifier failure must never surface in the TUI.
  execFile(notifier, notifyArgs(kind, title, body, { pane, tmux }), { timeout: 5000 }, () => {});
}

// "dotfiles (main)"; just the directory name outside a git repo.
function where(cwd) {
  try {
    const branch = execFileSync("git", ["-C", cwd, "rev-parse", "--abbrev-ref", "HEAD"], {
      encoding: "utf8", stdio: ["ignore", "pipe", "ignore"], timeout: 2000,
    }).trim();
    return `${basename(cwd)} (${branch})`;
  } catch {
    return basename(cwd);
  }
}

function elapsed(ms) {
  const s = Math.round(ms / 1000);
  return s < 60 ? `${s}s` : `${Math.floor(s / 60)}m ${s % 60}s`;
}

// First line of prose in the final assistant message, without markdown markers.
function firstLine(message) {
  const text = (message?.content ?? []).filter((c) => c.type === "text").map((c) => c.text).join("\n");
  const line = text.split("\n").map((l) => l.replace(/^[#>\-*\s]+/, "").replace(/[*`]/g, "").trim()).find(Boolean);
  return line ?? "";
}

export default function (pi: ExtensionAPI) {
  let startedAt = 0;
  let messages = [];

  pi.on("agent_start", async () => {
    startedAt = Date.now();
    messages = [];
  });

  pi.on("agent_end", async (event) => {
    messages = event.messages ?? [];
  });

  // Fires once per run, after retries, compaction and queued follow-ups are done.
  pi.on("agent_settled", async (event, ctx) => {
    // Aborting means I'm already at the keyboard.
    if (ctx.mode !== "tui" || event.aborted) return;

    const lastUser = messages.map((m) => m.role).lastIndexOf("user");
    const run = messages.slice(lastUser + 1).filter((m) => m.role === "assistant");
    const last = run.at(-1);
    const tools = run.flatMap((m) => m.content ?? []).filter((c) => c.type === "toolCall").length;
    const failed = last?.stopReason === "error";

    const summary = failed ? last.errorMessage || "Run failed" : firstLine(last) || "Ready for input";
    const stats = [startedAt && elapsed(Date.now() - startedAt), tools && `${tools} tool${tools === 1 ? "" : "s"}`].filter(Boolean);
    send(failed ? "failed" : "done", `${failed ? "🔴" : "✅"} pi · ${where(ctx.cwd)}`, [clip(summary, 140), ...stats].join(" · "));
  });

  pi.on("ui_prompt_start", async (event, ctx) => {
    if (ctx.mode !== "tui") return;
    send("question", `❓ pi · ${where(ctx.cwd)}`, clip(event.title || "Waiting for your answer", 140));
  });
}
