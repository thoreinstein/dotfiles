// @ts-nocheck -- Pi provides this API only when loading extensions.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const MUTATING_GIT =
  /\bgit\s+(?:commit|push|reset|restore|clean|rebase|merge|cherry-pick|revert|worktree\s+remove|branch\s+-[dD])\b/;

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return;

    const command = String(event.input.command ?? "").trim();
    if (!MUTATING_GIT.test(command)) return;

    if (!ctx.hasUI)
      return { block: true, reason: "No UI available to confirm Git change" };

    const choice = await ctx.ui.select(`Run Git change?\n\n  ${command}\n`, [
      "Yes",
      "No",
    ]);
    return choice === "Yes" ? undefined : { block: true, reason: "Denied" };
  });
}
