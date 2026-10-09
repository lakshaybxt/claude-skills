# code-review

A Claude skill that reviews a diff, file, pull request, or pasted snippet for bugs, security issues, performance problems, and maintainability, then returns prioritized, actionable feedback.

## The problem

Ad-hoc reviews tend to mix style nits with real bugs, skip security and error handling, and give vague advice like "could be cleaner." This skill fixes that by reviewing in a fixed order (correctness first, style last), using a language-aware checklist, and writing findings you can act on: file, line, why it matters, and a concrete fix.

## What it does

When you say **"review this"** (or similar), Claude reviews the code you provided and writes a short report with:

- **Summary**: what the change does and a verdict (approve / approve with comments / changes requested)
- **Must fix**: bugs, security holes, data loss, broken behavior
- **Should fix**: weak error handling, missing tests, performance, confusing design
- **Nits**: naming and small readability points (kept short)
- **What's good**: one or two specific things done well
- **Questions**: anything that could not be judged without more context

Empty sections are omitted. Findings cite a path and line (or quote the snippet) and include a smallest-possible fix.

If the code is on disk, the skill also runs `scripts/lint.sh` and folds real lint findings into the review. Pasted snippets skip lint. Strong on Java/Spring Boot and React/JavaScript, but works for any language.

## Folder structure

```
code-review/
├── SKILL.md
├── README.md
├── references/
│   └── checklist.md
└── scripts/
    └── lint.sh
```

The folder name must match the `name:` field in `SKILL.md`.

## Installation

### Claude Code

Personal (all projects):

```bash
mkdir -p ~/.claude/skills
cp -r code-review ~/.claude/skills/
```

Project only (shared via git):

```bash
mkdir -p .claude/skills
cp -r code-review .claude/skills/
```

Restart Claude Code if the skill doesn't show up.

### claude.ai (web / app)

1. Zip the folder so `code-review/` is the root of the zip:
   ```bash
   zip -r code-review.zip code-review/
   ```
2. Go to **Settings → Capabilities → Skills** and upload the zip.

## Usage

Point Claude at the code, then say any of:

- `review this`
- `code review`
- `check my code`
- `review my PR`
- `look over this diff`
- `/code-review`

**What you can attach or point at:**

- A pasted snippet or attached file
- A path in the working directory
- A git diff (`git diff`, `git diff main...HEAD`, or a patch file)
- A pull request description

If the scope is unclear, Claude reviews what was given and says what it covered. It does not ask questions unless the target is missing.

## Tips

- Prefer a diff or PR over a whole file dump. The review is better when intent and changed lines are visible.
- Ask for a review before you merge, not after you have already rewritten the same area.
- Treat **Must fix** as blocking. Nits are optional; do not let them bury a real bug.
- Lint only runs when files exist on disk and the tools are installed. A skipped linter is not a pass.
- The checklist in `references/checklist.md` is for Claude, not for pasting back at you. Language-specific notes cover Java/Spring Boot, GraphQL, Kafka, React/JS/TS, and SQL migrations.

## Limitations

- Claude can only review the code you provide. Callers, configs, or tests it cannot see go under Questions, not Must fix.
- `scripts/lint.sh` never modifies files. Missing tools are reported as skipped. Java `javac` checks are syntax-level only.
- The review is not a substitute for running the project's own tests and CI.
- Do not expect a full rewrite. The skill suggests the smallest change that fixes the problem.
