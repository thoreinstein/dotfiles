// @ts-nocheck -- Pi provides this API only when loading extensions.
import { execFile } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Before each run started by a prompt, add `recall`'s pointers to related engram memories and
// vault notes as a message. before_agent_start fires after the prompt is submitted, so typing is
// never blocked; the run starts at most ~4s later. Any failure adds nothing.
export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", (event, ctx) => {
    if (event.messageType !== "user") return;
    return new Promise((resolve) => {
      const child = execFile(
        "recall",
        ["--session", ctx.sessionManager.getSessionId()],
        { cwd: ctx.cwd, timeout: 4000 },
        (err, stdout) => {
          const text = err ? "" : stdout.trim();
          resolve(text ? { message: { customType: "recall", content: text, display: true } } : undefined);
        },
      );
      child.stdin?.on("error", () => {});
      child.stdin?.end(event.prompt);
    });
  });
}
