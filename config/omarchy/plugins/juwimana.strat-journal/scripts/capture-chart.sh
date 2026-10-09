#!/usr/bin/env bash
# Captures active screen or window using grim and saves with timestamp
set -e

DIR="${HOME}/.local/state/omarchy/strat-journal/screenshots"
mkdir -p "${DIR}"

FILENAME="trade_$(date +%Y%m%d_%H%M%S).png"
TARGET_PATH="${DIR}/${FILENAME}"

# Capture active screen with grim
if command -v grim >/dev/null 2>&1; then
    grim "${TARGET_PATH}"
else
    # Fallback mock/dummy if grim not active
    echo "Screenshot tool not available" >&2
    exit 1
fi

echo "${TARGET_PATH}"
