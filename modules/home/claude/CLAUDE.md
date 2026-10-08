# The Andrej Kaparthy Rules

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State assumptions explicitly. Uncertain — ask.
- Multiple interpretations exist — present them, don't pick silently.
- Simpler approach exists — say so. Push back when warranted.
- Unclear — stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" not requested.
- No error handling for impossible scenarios.
- 200 lines when 50 works — rewrite.

Ask: "Would senior engineer say overcomplicated?" Yes — simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- Notice unrelated dead code — mention it, don't delete it.

When your changes create orphans:

- Remove imports/variables/functions YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

Test: Every changed line traces directly to user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong criteria — loop independently. Weak criteria ("make it work") — constant clarification.

---

**Guidelines working if:** fewer unnecessary diff changes, fewer rewrites from overcomplication, clarifying questions come before implementation not after mistakes.

## Rules of the Shop

- **Orderly Operations:** Git commands run one at a time. Steady pace prevents mistakes.
- **The Ledger:** All docs and architectural truths in Obsidian vault at `/Users/jimmyers/Documents/second_brain/` (or `/Users/myers/Documents/second_brain/`). Don't clutter workspace.
- **Discipline:** Don't begin work or mark tasks `in_progress` until both agreed on plan.
- **Memory:** Session start — call `mem_search` with keywords from user's first message to surface prior context. Call `mem_save` after every decision, bugfix, pattern, or architecture finding — not just session end.
- **Vault first:** Before asking user about prior work, conventions, or past decisions, search engram (`mem_search`), then the vault via `obsidian_rag_query`. Vault `engram/` folder is a read-only mirror of engram — never edit it. Layout: `reference/VAULT_CONVENTIONS.md`.
- **Headroom:** Long-running or resumed work — call `headroom_retrieve` to surface prior compressed context first.
- **Skills:** Before non-trivial task, check for applicable skill via Skill tool. Skill applies — invoke before any other action.

<!-- CODEGRAPH_START -->

## CodeGraph

In repos indexed by CodeGraph (`.codegraph/` directory at repo root), use it BEFORE grep/find or reading files to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — relevant symbols' verbatim source plus call paths, including dynamic-dispatch hops grep can't follow. Name file or symbol to read current line-numbered source. Listed but deferred — load by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints same output.

No `.codegraph/` directory — skip CodeGraph entirely. Indexing is user's decision.
<!-- CODEGRAPH_END -->

## Environment Constraints

- **Token stack:** RTK (92% CLI filtering) + caveman (output) + token-optimizer MCP (caching) + headroom MCP compress/retrieve (client-side).

@RTK.md
