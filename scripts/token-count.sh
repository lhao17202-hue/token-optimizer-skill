#!/usr/bin/env bash
# token-count.sh — Estimate token count of a file
#
# Usage: bash token-count.sh <file>
#
# Uses tiktoken (cl100k_base) if Python+tiktoken is available,
# otherwise falls back to estimation:
#   English: tokens ≈ words × 1.33  (i.e. words / 0.75)
#   Chinese: tokens ≈ chars × 0.67  (i.e. chars / 1.5)
#   Mixed:   tokens ≈ (words_ascii / 0.75) + (chars_cjk / 1.5)

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: token-count.sh <file>"
    exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo "Error: file not found: $FILE"
    exit 1
fi

# Try tiktoken first
if python3 -c "import tiktoken" 2>/dev/null; then
    TOKENS=$(python3 -c "
import tiktoken, sys
enc = tiktoken.get_encoding('cl100k_base')
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    text = f.read()
print(len(enc.encode(text)))
" "$FILE")
    echo "$TOKENS"
    exit 0
fi

# Fallback: estimate using wc + simple heuristics
# Count total words (handles English well)
TOTAL_WORDS=$(wc -w < "$FILE" 2>/dev/null || echo 0)
# Count total characters
TOTAL_CHARS=$(wc -m < "$FILE" 2>/dev/null || echo 0)

# Try to count CJK characters specifically
if command -v python3 >/dev/null 2>&1; then
    CJK_COUNT=$(python3 -c "
import sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    text = f.read()
# CJK Unified Ideographs: U+4E00–U+9FFF
# CJK Symbols/Punctuation: U+3000–U+303F
# CJK Compatibility Ideographs: U+F900–U+FAFF
# Hiragana + Katakana: U+3040–U+30FF
# Fullwidth forms: U+FF00–U+FFEF
cjk = sum(1 for c in text if (
    '一' <= c <= '鿿' or
    '　' <= c <= '〿' or
    '豈' <= c <= '﫿' or
    '぀' <= c <= 'ヿ' or
    '＀' <= c <= '￯'
))
print(cjk)
" "$FILE" 2>/dev/null || echo 0)
else
    CJK_COUNT=0
fi

# Estimation: ~0.75 tokens per English word, ~1.5 chars per token for CJK
# For mixed content, estimate based on word count + CJK adjustment
NON_CJK_WORDS=$((TOTAL_WORDS > 0 ? TOTAL_WORDS : TOTAL_CHARS / 5))
ESTIMATED=$(awk -v w="$NON_CJK_WORDS" -v c="$CJK_COUNT" 'BEGIN { printf "%.0f", (w / 0.75) + (c / 1.5) }')
echo "$ESTIMATED (estimated — install 'tiktoken' for exact count)"
