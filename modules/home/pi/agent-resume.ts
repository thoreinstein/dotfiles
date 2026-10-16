// @ts-nocheck -- Pi provides this API only when loading extensions.
import { execFile } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Record this session for `agent-resume`, so it can be picked back up in the same tmux
// session after a reboot. TUI only: `pi -p` runs must not replace the interactive session.
export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    const file = ctx.sessionManager.getSessionFile();
    if (ctx.mode !== "tui" || !process.env.TMUX || !file) return;
    execFile("agent-resume", ["record", "pi", file, ctx.cwd], () => {});
  });
}
