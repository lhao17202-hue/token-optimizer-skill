#!/usr/bin/env bash
# backup.sh — Save original SKILL.md to token-optimizer/backups/<skill-name>/
#
# Usage: bash backup.sh <path-to-skill-directory-or-SKILL.md>
#
# Example:
#   bash backup.sh ~/.claude/skills/annotate-code
#   bash backup.sh ~/.claude/skills/annotate-code/SKILL.md

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: backup.sh <path-to-skill>"
    echo "  path-to-skill: either a skill directory or a direct SKILL.md path"
    exit 1
fi

TARGET="$1"

# Resolve to absolute path (handle relative paths like ".")
if command -v realpath >/dev/null 2>&1; then
    TARGET="$(realpath "$TARGET")"
elif command -v readlink >/dev/null 2>&1; then
    TARGET="$(readlink -f "$TARGET")"
fi

# Resolve to the SKILL.md file
if [ -d "$TARGET" ]; then
    SKILL_FILE="$TARGET/SKILL.md"
elif [ -f "$TARGET" ]; then
    SKILL_FILE="$TARGET"
else
    echo "Error: '$TARGET' is neither a directory nor a file"
    exit 1
fi

if [ ! -f "$SKILL_FILE" ]; then
    echo "Error: SKILL.md not found at '$SKILL_FILE'"
    exit 1
fi

# Determine skill name from parent directory
SKILL_DIR="$(dirname "$SKILL_FILE")"
SKILL_NAME="$(basename "$SKILL_DIR")"

# Determine backup root: token-optimizer/backups/ relative to this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_ROOT="$SCRIPT_DIR/../backups"
BACKUP_DIR="$BACKUP_ROOT/$SKILL_NAME"

mkdir -p "$BACKUP_DIR"

# If backup already exists, timestamp it
BACKUP_FILE="$BACKUP_DIR/SKILL.md"
if [ -f "$BACKUP_FILE" ]; then
    TIMESTAMP="$(date +%Y-%m-%dT%H%M%S)"
    BACKUP_FILE="$BACKUP_DIR/SKILL.md.$TIMESTAMP"
    echo "Existing backup found; archiving to $BACKUP_FILE"
fi

cp "$SKILL_FILE" "$BACKUP_FILE"

# Save original location for restore
echo "$SKILL_FILE" > "$BACKUP_DIR/.origin"

echo "Backed up: $SKILL_FILE → $BACKUP_FILE"
echo "Skill: $SKILL_NAME"
