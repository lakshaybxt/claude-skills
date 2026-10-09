---
name: code-review
description: Review code changes (a diff, a file, a pull request, or a pasted snippet) for bugs, security issues, performance problems and maintainability, and return prioritized, actionable feedback. Use when the user says "review this", "code review", "check my code", "review my PR", "look over this diff", or invokes /code-review. Strong on Java/Spring Boot and React/JavaScript, but works for any language.
---

# Code Review

Give a review a senior engineer would be glad to receive: correct, specific, prioritized, and short enough to act on.

## Inputs

The user may give you any of these:

- A pasted snippet or attached file
- A path in the working directory
- A git diff (`git diff`, `git diff main...HEAD`, or a patch file)
- A pull request description

If the scope is unclear, review what was provided and say what you covered. Do not ask questions unless the target is truly missing.

## Steps

1. **Understand the intent.** Read the change and work out what it is trying to do before judging how it does it. If the intent is unclear, state your assumption in one line.
2. **Run the lint helper when files are on disk.** If the code is available as files and the language is supported, run `scripts/lint.sh <path>` and fold real findings into the review. Skip this step for pasted snippets, and never claim lint passed if you did not run it.
3. **Read `references/checklist.md`** and apply the sections that fit the language and change type. Do not paste the checklist back at the user.
4. **Review in this order:** correctness and bugs, security, error handling, performance, tests, then readability and style. Stop worrying about style if there are serious problems above it.
5. **Write the review** using the output format below.

## Output format

```markdown
## Summary
Two or three sentences: what the change does and your overall verdict
(approve / approve with comments / changes requested).

## Must fix
Issues that cause bugs, security holes, data loss, or broken behavior.
- `path/File.java:42`: what is wrong, why it matters, and a concrete fix
  (short code snippet when it helps).

## Should fix
Real problems that are not blocking: weak error handling, missing tests,
performance issues, confusing design.

## Nits
Naming, formatting, small readability points. Keep this list short.

## What's good
One or two specific things done well.

## Questions
Anything you could not judge without more context.
```

Leave out any section that has nothing in it, except Summary.

## Rules

- Be specific. Cite file and line, or quote the exact snippet. "Could be cleaner" is not feedback.
- Explain the why in one sentence, then give the fix. Show a corrected snippet for anything non-obvious.
- Prioritize. Put the three most important issues first. Do not bury a security bug under twenty nits.
- Only report what you actually found in the code you were given. If something depends on code you cannot see, put it under Questions instead of asserting it.
- Do not rewrite the whole file. Suggest the smallest change that fixes the problem.
- Respect the existing style and conventions of the codebase over your own preferences.
- Do not flag a style preference as a bug. Label opinions as opinions.
- Never include secrets you spot in the review text. Say "hardcoded credential at line N" and tell the user to rotate it.
- If the code is good, say so briefly. Do not invent issues to look thorough.
