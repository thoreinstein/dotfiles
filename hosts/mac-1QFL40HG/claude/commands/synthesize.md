---
description: Surface unlinked Readwise highlights and connect them to Engineering notes conversationally
---

You are running the Readwise synthesis workflow. The goal is to surface saved highlights that haven't been connected to any Engineering/ knowledge and turn them into linked insights — without making the user do the heavy lifting.

## Step 1: Find unlinked highlights

Search the vault for Readwise highlights that have no wikilinks to Engineering/ notes.

Use `obsidian_list_notes` to enumerate notes in `Readwise/` (Books and Articles subdirectories).
For each Readwise note, use `obsidian_get_links` to check its outgoing links.
A highlight is "unlinked" if it has zero links pointing to `Engineering/` notes.

Start with a sample of 5 unlinked highlights — don't overwhelm the user.

## Step 2: Propose connections

For each unlinked highlight, use `obsidian_rag_query` to find the most semantically similar Engineering/ note.

Present one highlight at a time in this format:

---
**From:** [[Book or Article Title]]
> "The highlight text"

**Connects to:** [[Engineering/Patterns/SomePattern]] — because [one-sentence reason]

Reply: **yes** to link it | **skip** to move on | **new** to draft a new pattern note | **done** to stop
---

Wait for the user's reply before moving to the next highlight.

## Step 3: Act on responses

**yes** — Add a `## Links` section to the Readwise note (or append to existing one) with a wikilink to the Engineering note. Also add a backlink reference in the Engineering note's `## Links` section.

**skip** — Move to the next highlight. No changes.

**new** — Draft a new Pattern or Trap note based on the highlight content. Show the draft and ask for confirmation before writing.

**done** — Stop the loop. Summarize how many connections were made.

## Step 4: Summarize

After the session ends (user says done, or all 5 highlights are handled), report:
- X highlights connected to existing notes
- Y new notes drafted
- Offer to run another batch of 5 if there are more unlinked highlights

## Guardrails

- Never write to the vault without user confirmation (yes / new + confirm)
- Show one highlight at a time — don't dump a list
- Keep proposed connections concrete: "because [specific reason]", not vague "related to"
- If no good Engineering/ match exists, say so rather than forcing a weak link
- Respect the note formats from VAULT_CONVENTIONS.md when writing new notes
