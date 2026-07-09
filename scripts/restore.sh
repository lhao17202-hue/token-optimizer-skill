#!/usr/bin/env bash
# restore.sh — Restore original SKILL.md from token-optimizer backup
#
# Usage: bash restore.sh <skill-name> [target-skill-path]
#
# If target is omitted, restores to the original location inferred from
# a .origin file saved alongside the backup.

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: restore.sh <skill-name> [target-skill-path]"
    echo "  skill-name:       name of the skill to restore (matches backups/<skill-name>/)"
    echo "  target-skill-path: optional path to write SKILL.md to"
    echo ""
    echo "Available backups:"
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    BACKUP_ROOT="$SCRIPT_DIR/../backups"
    if [ -d "$BACKUP_ROOT" ]; then
        ls -1 "$BACKUP_ROOT" 2>/dev/null || echo "  (none)"
    fi
    exit 1
fi

SKILL_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_ROOT="$SCRIPT_DIR/../backups"
BACKUP_DIR="$BACKUP_ROOT/$SKILL_NAME"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: no backup found for skill '$SKILL_NAME'"
    echo "Available: $(ls -1 "$BACKUP_ROOT" 2>/dev/null || echo "(none)")"
    exit 1
fi

# Find the main backup file (SKILL.md, not timestamped copies)
BACKUP_FILE="$BACKUP_DIR/SKILL.md"
if [ ! -f "$BACKUP_FILE" ]; then
    # Try the most recent timestamped backup
    BACKUP_FILE=$(ls -1t "$BACKUP_DIR"/SKILL.md.* 2>/dev/null | head -1 || true)
    if [ -z "$BACKUP_FILE" ]; then
        echo "Error: no SKILL.md backup found in $BACKUP_DIR"
        ls -la "$BACKUP_DIR"
        exit 1
    fi
    echo "Using timestamped backup: $BACKUP_FILE"
fi

# Determine target
if [ $# -ge 2 ]; then
    TARGET_DIR="$2"
    # If target is a directory, write SKILL.md inside it
    if [ -d "$TARGET_DIR" ]; then
        TARGET="$TARGET_DIR/SKILL.md"
    else
        TARGET="$TARGET_DIR"
    fi
else
    # Try .origin file
    ORIGIN_FILE="$BACKUP_DIR/.origin"
    if [ -f "$ORIGIN_FILE" ]; then
        TARGET="$(cat "$ORIGIN_FILE")"
        echo "Restoring to original location: $TARGET"
    else
        echo "No target specified and no .origin file found."
        echo "Backup is at: $BACKUP_FILE"
        echo "Run: bash restore.sh $SKILL_NAME <path-to-skill-directory>"
        exit 1
    fi
fi

# Confirm before overwriting
if [ -f "$TARGET" ]; then
    echo "Warning: $TARGET already exists and will be overwritten."
    echo "Proceed? (y/N)"
    read -r CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        echo "Cancelled."
        exit 0
    fi
fi

mkdir -p "$(dirname "$TARGET")"
cp "$BACKUP_FILE" "$TARGET"
echo "Restored: $BACKUP_FILE → $TARGET"
