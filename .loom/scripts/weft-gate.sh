#!/usr/bin/env bash
# weft-gate.sh — STUB.
#
# Runs at weft's gate/close moment (loom.toml [weft] hook). Echoes only, so the next
# plugin version can verify the hook actually fires before any real behavior exists.
# Real behavior TBD — e.g. repo-specific pre-merge checks beyond loom's built-in
# lint + clean-tree gate. Fails loud if it ever grows teeth.
set -euo pipefail

echo "weft-gate: hook fired (stub — no checks yet). args: $*"
