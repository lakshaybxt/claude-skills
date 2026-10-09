---
name: chat-handoff
description: Create or update a handoff markdown file that captures the current chat's project state, code changes, decisions and next steps, so a fresh chat can continue without re-explaining. Use when the user says "handoff", "wrap up this chat", "save context", "context is almost full", "summarize for a new chat", or invokes /handoff.
---

# Chat Handoff

Produce a single dense markdown file that lets a brand-new chat pick up exactly where this one left off. The reader has zero context, so write for them.

## When this runs

- The user asks for a handoff, wrap-up, or context export.
- The user says the chat is getting long or near its context limit.
- The user attaches an existing handoff file and asks to update it.

## Steps

1. **Check for an existing handoff.** If the user attached or pasted a previous handoff for this topic, update that file instead of starting over. Keep still-valid content, revise what changed, and remove what is stale or done. One file per topic, kept current, never an ever-growing log.
2. **Review the whole conversation.** Pull out only what a future chat needs: facts, decisions, code changes, and open work. Skip pleasantries, dead ends, and anything that was tried and abandoned (unless the failure itself is worth warning about).
3. **Write the file** using the template below. Name it `handoff-<topic-slug>.md` (for example `handoff-gametosa.md`).
4. **Deliver it** to the user as a file, and add one line telling them how to use it: attach it to the new chat (or add it to the Project's knowledge) and say "Read this handoff and continue from Next Steps."

## Template

```markdown
# Handoff: <topic / project name>
Last updated: <date> | Chats covered: <count or short list>

## Overview
What this project/topic is, tech stack, and architecture in 3-6 lines.

## Current State
- Done:
- In progress:
- Broken / known issues:

## Changes Made (code)
Per file or module: path, what changed, why. Name key functions/classes/endpoints.
Include short snippets only when the exact wording matters (signatures, config keys, schema).

## Decisions & Rationale
Choices made and the reason, so they don't get re-debated.

## Conventions
Naming, patterns, libraries to use or avoid, style rules the user has stated.

## Open Questions
Things still undecided or needing the user's input.

## Next Steps
Prioritized list. The first item should be immediately actionable.

## Do NOT
Things the next chat must not change, redo, or assume.
```

## Rules

- Be specific: real file paths, names, versions, commands. Vague summaries are useless to a fresh chat.
- Be dense: target one to two pages. Cut filler so the file leaves most of the new chat's context free.
- Record only what actually happened or what the user stated. Mark anything uncertain as "unverified" rather than presenting it as fact.
- Do not include secrets (API keys, passwords, tokens). Refer to them by name, e.g. "uses GEMINI_API_KEY from .env".
- When updating, change the "Last updated" line and fold in new work instead of appending a separate section per chat.
