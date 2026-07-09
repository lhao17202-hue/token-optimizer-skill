---
name: token-optimizer
description: Use when the user asks to compress, reduce, or optimize a skill's SKILL.md file. Triggers on phrases like "compress this skill", "optimize skill tokens", "reduce skill size", "make the skill smaller", "trim the skill definition", or "token optimize". Also triggers when the user points at a SKILL.md and says "this is too long" or "make this shorter".
---

# Token Optimizer

Compress SKILL.md files by stripping prose while preserving every functional rule, constraint, and safety check. The compressed skill must behave identically to the original — if a rule existed before, it must be findable after.

**Core principle: when in doubt, keep it.** Cutting a borderline sentence saves ~10 tokens. Missing a constraint breaks the skill. Err toward keeping.

## When NOT to use

- User wants to **edit** a skill's rules or behavior — that's a content change, not compression
- User says "make this clearer" or "rewrite this" — they want better wording, not fewer words
- User asks to **add** something to a skill — expanding, not compressing
- The target is not a SKILL.md — this skill only compresses skill definitions, not arbitrary files

## What survives (always)

These categories are untouchable. Do not rewrite, paraphrase, or shorten them:

- **Safety rules** — danger blocks, "never do X", permission checks, `<HARD-GATE>` content
- **Parameter specs** — names, types, required/optional, valid ranges, enums
- **Output format** — JSON schema, required fields, templates, tags that must appear
- **Error handling** — fallback paths, edge cases, what to do when something fails
- **Trigger conditions** — the exact phrases or patterns that activate a skill
- **Tool references** — script names, command paths, argument signatures
- **Conditional logic** — "if X then Y", decision trees, branching rules

## What gets compressed

| Category | Action |
|----------|--------|
| Design philosophy, background stories, "why we built this" | **Delete** — the agent only needs what to do, not why it was decided |
| Greetings, sign-offs, polite padding | **Delete** — "Hello!", "Good luck!", "Happy coding!" |
| Repeated emphasis ("IMPORTANT:", "CRITICAL:", "NOTE:") | **Keep the content if it's a real rule; delete the emphasis wrapper if it's just advice** |
| Prose paragraphs describing a sequence of steps | **Convert to numbered list** — same steps, fewer words |
| Multiple examples of the same pattern | **Keep the best one, delete the rest** |
| Example commentary ("as you can see...", "this shows that...") | **Delete** — let the example speak for itself |
| Adjectives and adverbs that don't constrain behavior | **Delete** — "very", "simply", "just", "carefully", "easily" |
| Redundant sub-headings that split the same topic | **Merge** — "### Overview" + "### Introduction" → one heading |
| Meta-commentary about the skill itself | **Delete** — "This skill helps you...", "The purpose is to..." |
| "See also", "Further reading", "Additional resources" | **Delete** — these are for humans browsing, not agents executing |
| Inline code comments that restate the obvious | **Delete** — keep only comments that explain non-obvious intent |

## Workflow

### 1. Backup

Before touching the target file, save the original to this skill's backup store:

```bash
bash scripts/backup.sh <skill-path>
```

This copies the original SKILL.md into `token-optimizer/backups/<skill-name>/SKILL.md`, preserving it regardless of what happens to the source location. If a backup for that skill already exists, it appends a timestamp to the filename.

### 2. Read the target

Read the full SKILL.md. Understand what this skill does before compressing it — you can't know what's essential without understanding the skill's job.

### 3. Compress

Apply the rules above. Two guidelines:

- **Rules keep their original wording.** Paraphrasing a safety constraint risks shifting its meaning. Copy verbatim from the source.
- **One rule per line.** Don't merge two distinct rules into one sentence. A bullet list where each item is one constraint is more scannable than a dense paragraph — even if the paragraph uses fewer words.

### 4. Validate

Go through this checklist against the ORIGINAL. For each item, verify it appears in the compressed output. If a check fails, restore the missing content from the original.

```
□ All safety warnings and danger blocks present?
□ All required parameters listed with their types?
□ All valid value ranges and enums preserved?
□ Output format specification intact?
□ Error handling paths present?
□ Core trigger commands / invocation syntax preserved?
□ Tool and script names with their arguments preserved?
□ All conditional branches (if X then Y) intact?
□ All "never" / "always" / "must" rules present?
□ No placeholder text, no "[...]", no incomplete sections introduced?
```

**If any checkbox fails**, restore the missing rule from the original before proceeding. The validation is not optional — it is the mechanism that guarantees the compression doesn't break the skill.

### 5. Report

Count tokens before and after. Use `scripts/token-count.sh` if available, otherwise estimate (1 token ≈ 0.75 words for English, 1 token ≈ 1.5 characters for Chinese).

Report concisely:

```
token-optimizer: <skill-name>
  Before: N tokens → After: N tokens (saved N, X%)
  Validation: all 10 checks passed
  Backup: token-optimizer/backups/<skill-name>/SKILL.md
```

## Example

**Before** (42 words, ~55 tokens):
> When you encounter an error during the backup process, it is very important that you do not simply ignore it and continue with the operation. Instead, carefully stop what you're doing, read the error message to understand what went wrong, and then report the issue to the user with enough context so they can decide how to proceed.

**After** (15 words, ~20 tokens):
> If backup fails: stop, read the error, report it to the user with full context. Do not continue past a failed backup.

The rule is identical — stop on error, report it — but the compressed version drops the padding without losing the constraint.

## Common mistakes

- **Rewriting rules instead of trimming them.** "Don't continue past a failed backup" and "Stop on backup failure" seem equivalent, but the original wording was chosen deliberately. Keep it.
- **Merging distinct constraints.** "Stop on error and report it" is one rule about stopping, one about reporting. Two bullets, not one sentence.
- **Deleting "obvious" safety rules.** A rule that seems obvious to you might not be obvious to every agent that loads the skill. If the author included it, assume it mattered.
- **Compressing code blocks.** Code is already minimal. Removing characters from a command or script can break it.

## Batch compression

When asked to compress multiple skills:

1. Glob for all SKILL.md files under the target directory
2. Tell the user how many were found
3. Process one at a time
4. After all done, output a summary table of per-skill savings

## Restore

To undo a compression and restore the original:

```bash
bash scripts/restore.sh <skill-name> [<target-skill-path>]
```

If `<target-skill-path>` is omitted, the script prints where the backup is and asks for confirmation. The backup files live in `token-optimizer/backups/<skill-name>/` — even if the original skill directory was deleted or moved, the backup is safe.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/backup.sh <skill-path>` | Copies original SKILL.md into `backups/<skill-name>/` |
| `scripts/token-count.sh <file>` | Counts tokens (tiktoken if available, else estimates) |
| `scripts/restore.sh <skill-name> [target]` | Restores backup to target location |
