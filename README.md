# claude-skills

A collection of custom [Claude](https://claude.ai) skills I use for day-to-day development work. Each skill is a self-contained folder with a `SKILL.md` that Claude loads when a task matches.

## Skills

| Skill | What it does | Trigger phrases |
|-------|--------------|-----------------|
| [`chat-handoff`](chat-handoff/) | Saves a chat's project state, code changes, decisions and next steps into one markdown file so a fresh chat can continue without re-explaining. | "handoff", "wrap up this chat", "save context", `/handoff` |
| [`code-review`](code-review/) | Reviews code (a snippet, file, diff or PR) for bugs, security, performance and maintainability, and returns prioritized feedback. Runs a lint script when files are on disk. | "review this", "code review", "check my code", `/code-review` |

## Repository structure

```
claude-skills/
├── README.md
├── .gitignore
├── chat-handoff/
│   ├── SKILL.md
│   └── README.md
└── code-review/
    ├── SKILL.md
    ├── references/
    │   └── checklist.md
    └── scripts/
        └── lint.sh
```

Each skill folder follows the same rules:

- The folder name matches the `name:` field in its `SKILL.md`.
- `SKILL.md` is the only required file. It has frontmatter (`name`, `description`) and the instructions Claude follows.
- `references/` holds longer docs Claude reads only when needed.
- `scripts/` holds helper scripts Claude can run.

## How skills work

1. Claude always sees each skill's `name` and `description`.
2. When your request matches a description, Claude reads that skill's `SKILL.md`.
3. While following it, Claude opens files in `references/` or runs files in `scripts/` only if the instructions say to.

This keeps the context window small, because only the skills and files a task needs get loaded.

## Installation

### Claude Code

Personal skills, available in every project:

```bash
git clone <your-repo-url> ~/dev/claude-skills

mkdir -p ~/.claude/skills
ln -s ~/dev/claude-skills/chat-handoff ~/.claude/skills/chat-handoff
ln -s ~/dev/claude-skills/code-review  ~/.claude/skills/code-review
```

Symlinks mean a `git pull` updates your skills immediately. To use a skill in a single project only, copy its folder into that project's `.claude/skills/` instead:

```bash
mkdir -p .claude/skills
cp -r ~/dev/claude-skills/code-review .claude/skills/
```

Restart Claude Code if a new skill doesn't show up.

### claude.ai (web / app)

1. Zip the skill folder so the folder itself is the root of the zip:
   ```bash
   zip -r code-review.zip code-review/
   ```
2. Go to **Settings → Capabilities → Skills** and upload the zip.

Repeat for each skill you want.

## Usage

Just ask in normal words.

- **End of a long chat:** say `handoff`. Claude writes `handoff-<topic>.md`. Download it, then attach it to a new chat and say "Read this handoff and continue from Next Steps."
- **Before a commit or PR:** say `review this` and give Claude the code, file path or diff. In Claude Code, it runs `scripts/lint.sh` on files in your working directory and combines the results with its own review.

## Notes and limitations

- `code-review` currently reviews whatever file, folder or diff you point it at. It does not yet find your changed files from git on its own.
- `lint.sh` only runs linters that are installed (eslint with a project config, ruff or flake8, shellcheck, checkstyle or javac). Tools that are missing are reported as "skipped", not as passed.
- `chat-handoff` cannot save the handoff file into your next chat or Project by itself. You download and attach or upload it.
- Never commit secrets (API keys, tokens) inside a skill or a handoff file.

## Adding a new skill

1. Create a folder with a lowercase, hyphenated name: `my-skill/`.
2. Add `my-skill/SKILL.md` with frontmatter:
   ```markdown
   ---
   name: my-skill
   description: What it does and when to use it. Include the phrases you would actually say.
   ---

   # My Skill

   Steps, output format and rules for Claude to follow.
   ```
3. Add `references/` or `scripts/` only if the skill needs them.
4. Add a row to the Skills table above.
5. Install it using the steps above and test it with a real request.

A good `description` is the most important part: it decides whether Claude picks the skill up at all.

## Packaging (optional)

To build an uploadable zip for every skill at once:

```bash
mkdir -p dist
for d in */; do
  name="${d%/}"
  [ -f "$name/SKILL.md" ] && zip -r "dist/$name.zip" "$name" -x "*.DS_Store"
done
```

Add `dist/` to `.gitignore` if you do not want to commit the zips.
