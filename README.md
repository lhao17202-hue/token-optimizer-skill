# Token Optimizer Skill

A [Claude Code](https://claude.ai/code) skill that compresses SKILL.md files — stripping prose and redundancy while preserving every functional rule, safety constraint, and output format. **Same behavior, fewer tokens.**

## What it does

Skill definitions (SKILL.md) accumulate prose over time — design philosophy, verbose examples, polite padding, redundant emphasis. This adds up: loading 10 skills means loading all that prose into context every session.

Token Optimizer reads a SKILL.md, identifies what's essential (rules, constraints, formats, error paths) and what's not (background, repetition, filler), then produces a compressed version. A 10-item validation checklist guarantees nothing functional is lost.

## Quick start

```bash
# Compress a single skill
# (Claude invokes the token-optimizer skill, then:)
bash scripts/backup.sh ~/.claude/skills/my-skill
# Claude reads, compresses, and writes the optimized SKILL.md

# Restore if needed
bash scripts/restore.sh my-skill ~/.claude/skills/my-skill
```

## File structure

```
token-optimizer/
├── SKILL.md              # Skill definition — the compression rules
├── scripts/
│   ├── backup.sh         # Save original to backups/<skill-name>/
│   ├── token-count.sh    # Count tokens (tiktoken or estimate)
│   └── restore.sh        # Restore original from backup
├── backups/              # Backup storage (gitignored)
├── README.md
└── LICENSE
```

## What gets preserved (always)

| Category | Examples |
|----------|----------|
| Safety rules | Danger blocks, "never do X", permission checks |
| Parameter specs | Names, types, required/optional, valid ranges |
| Output format | JSON schema, required fields, templates |
| Error handling | Fallback paths, edge cases |
| Trigger conditions | Activation phrases and patterns |
| Tool references | Script names, command paths, arguments |
| Conditional logic | "If X then Y", branching rules |

## What gets compressed

| Category | Action |
|----------|--------|
| Design philosophy, background | Delete |
| Greetings, sign-offs | Delete |
| Prose paragraphs | Convert to numbered list |
| Duplicate examples | Keep best one |
| Example commentary | Delete |
| Filler words ("very", "simply", "just") | Delete |
| "See also", "Further reading" | Delete |
| Obvious code comments | Delete |

## Example

**Before** (42 words, ~55 tokens):
> When you encounter an error during the backup process, it is very important that you do not simply ignore it and continue with the operation. Instead, carefully stop what you're doing, read the error message to understand what went wrong, and then report the issue to the user with enough context so they can decide how to proceed.

**After** (15 words, ~20 tokens):
> If backup fails: stop, read the error, report it to the user with full context. Do not continue past a failed backup.

Same rule, 64% fewer tokens. No constraint was lost.

## Validation

After every compression, a 10-point checklist is verified against the original:

- All safety warnings present?
- All required parameters with types?
- Valid ranges and enums preserved?
- Output format intact?
- Error handling present?
- Trigger commands preserved?
- Tool/script names preserved?
- Conditional branches intact?
- "Never"/"always"/"must" rules present?
- No placeholder text introduced?

If any check fails, the missing content is restored from the original before writing.

## Restore

Backups live in `token-optimizer/backups/<skill-name>/`. To undo:

```bash
bash scripts/restore.sh <skill-name> [<target-path>]
```

Even if the original skill directory was deleted or moved, the backup is safe inside this repo.

## Requirements

- Bash (any modern version)
- Python 3 (optional — for exact token counting via `tiktoken`)
- Claude Code or any Claude-powered environment that supports skills

## License

MIT
