# chat-handoff

A Claude skill that saves your chat's context into a single markdown file, so you can start a fresh chat and continue without re-explaining everything.

## The problem

Long chats fill up Claude's context window. Starting a new chat means losing the project background, decisions, and code changes you built up. This skill fixes that by exporting that context into a compact "handoff" file that a new chat can read.

## What it does

When you say **"handoff"**, Claude reviews the whole conversation and writes `handoff-<topic>.md` containing:

- **Overview**: what the project is, stack, architecture
- **Current State**: done, in progress, broken
- **Changes Made**: files touched, key functions, why
- **Decisions & Rationale**: so they don't get re-debated
- **Conventions**: naming, patterns, libraries to use or avoid
- **Open Questions**
- **Next Steps**: prioritized, first item immediately actionable
- **Do NOT**: things the next chat must not change or redo

If you attach an existing handoff file for that topic, the skill updates it instead of creating a new one. One file per topic, always current.

## Folder structure

```
chat-handoff/
├── SKILL.md
└── README.md
```

The folder name must match the `name:` field in `SKILL.md`.

## Installation

### Claude Code

Personal (all projects):

```bash
mkdir -p ~/.claude/skills
cp -r chat-handoff ~/.claude/skills/
```

Project only (shared via git):

```bash
mkdir -p .claude/skills
cp -r chat-handoff .claude/skills/
```

Restart Claude Code if the skill doesn't show up.

### claude.ai (web / app)

1. Zip the folder so `chat-handoff/` is the root of the zip:
   ```bash
   zip -r chat-handoff.zip chat-handoff/
   ```
2. Go to **Settings → Capabilities → Skills** and upload the zip.

## Usage

**At the end of a chat** (ideally when it is around 70-80% full), say any of:

- `handoff`
- `wrap up this chat`
- `save context`
- `/handoff`

Claude generates the file. Download it.

**In the new chat:**

1. Attach the handoff file (or add it to a Project's knowledge).
2. Say: *"Read this handoff and continue from Next Steps."*

## Tips

- Keep one handoff file per topic, for example `handoff-gametosa.md`, `handoff-uigen.md`.
- Use a Claude Project per topic and upload the handoff to its knowledge. Every new chat in that Project then starts with the context loaded, and you only re-upload when the file changes.
- Ask for the handoff before the chat is nearly full, so Claude still has the whole conversation in view.
- Don't put secrets (API keys, tokens) in handoff files. Reference them by name instead.

## Limitations

- Claude cannot save the file into your next chat or Project by itself. You download and attach or upload it yourself.
- The handoff is only as good as the conversation it summarizes. Review it quickly before relying on it.
