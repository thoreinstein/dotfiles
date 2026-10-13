// @ts-nocheck -- Pi provides this API only when loading extensions.
import { execFileSync } from "node:child_process";
import { basename } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Desktop notification (Ghostty OSC 777) whenever pi is waiting on me: a run has fully
// settled, or a blocking prompt opened. TUI only, so `pi -p` output stays clean.
// Replaces ferologics/pi-notify, which fired a fixed "Ready for input" in every mode.

// OSC 777 separates fields with ";" and ends at BEL, so neither may appear in the text.
const clean = (s) => s.replace(/[\x00-\x1f\x7f]+/g, " ").replace(/;/g, ",").trim();
const clip = (s, n) => (s.length > n ? `${s.slice(0, n - 1)}…` : s);

function send(title, body) {
  let seq = `\x1b]777;notify;${clean(title)};${clean(body)}\x07`;
  // tmux passthrough: wrap in DCS and double inner ESC bytes.
  if (process.env.TMUX) seq = `\x1bPtmux;${seq.split("\x1b").join("\x1b\x1b")}\x1b\\`;
  process.stdout.write(seq);
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
    send(`${failed ? "🔴" : "✅"} pi · ${where(ctx.cwd)}`, [clip(summary, 140), ...stats].join(" · "));
  });

  pi.on("ui_prompt_start", async (event, ctx) => {
    if (ctx.mode !== "tui") return;
    send(`❓ pi · ${where(ctx.cwd)}`, clip(event.title || "Waiting for your answer", 140));
  });
}
