// @ts-nocheck -- Pi provides this API only when loading extensions.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Local stand-in for ferologics/pi-notify: Ghostty's OSC 777 notification when the agent
// finishes, but only in the TUI. Upstream fires in every mode, so `pi -p` output piped
// to a file or another program picked up the raw escape sequence.
export default function (pi: ExtensionAPI) {
  pi.on("agent_end", async (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    let seq = "\x1b]777;notify;Pi;Ready for input\x07";
    // tmux passthrough: wrap in DCS and double inner ESC bytes.
    if (process.env.TMUX) seq = `\x1bPtmux;${seq.split("\x1b").join("\x1b\x1b")}\x1b\\`;
    process.stdout.write(seq);
  });
}
