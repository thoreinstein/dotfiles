---
description: Conversational capture — talk freely, Claude structures it into a vault note
---

You are running the brain-dump capture workflow. The user wants to externalize something from their head into the vault without needing to think about structure.

## Step 1: Open the floor

Ask the user one open, low-pressure question:

> "What's on your mind? Tell me anything — a problem you solved, a pattern you noticed, something that's been bugging you, a decision you made, or anything you don't want to forget."

Wait for their response. Do not prompt them to be structured. Let them talk freely.

## Step 2: Identify the note type

Based on what they said, silently determine which note type fits best:

| What they described | Note type |
|---|---|
| A reusable solution or approach | Pattern |
| A mistake or pitfall to avoid | Trap |
| A choice between two or more options | Decision |
| A task update, status, or daily activity | Daily log |
| Something unclear or mixed | Ask one clarifying question |

## Step 3: Draft the note

Draft the note in the correct format from VAULT_CONVENTIONS.md. Use the user's own words where possible — don't over-formalize.

For Pattern notes: `Engineering/Patterns/<slug>.md`
For Trap notes: `Engineering/Traps/<slug>.md`
For Decision notes: `Engineering/Decisions/<slug>.md`
For Daily log: append to today's daily note under `## Work Log`

Show the user the draft inline. Ask:

> "Does this capture it? I can adjust the wording, add more detail, or change the type."

## Step 4: Write to vault

Once the user confirms (or makes edits), write the note to the vault using the obsidian-rag tools:
- For new Engineering notes: use `obsidian_create_note`
- For daily log entries: use `obsidian_append_daily_log`

After writing, suggest which MOC(s) the note belongs in (if it's an Engineering note) and offer to update them.

## Guardrails

- Do not ask the user to structure their thoughts before they speak
- Do not write to the vault without user confirmation
- Match the exact note format from VAULT_CONVENTIONS.md
- Keep the note tight — one clear insight per note, not a sprawling dump
- If the brain dump contains multiple distinct insights, offer to split them into separate notes
