#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMP_TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_TEST_DIR"' EXIT
xcrun swift-format lint --strict "$ROOT"/App/*.swift
xcrun swiftc "$ROOT/App/ChatModels.swift" "$ROOT/App/ChatPrompt.swift" "$ROOT/Tests/PromptTests.swift" -o "$TEMP_TEST_DIR/prompt-tests"
"$TEMP_TEST_DIR/prompt-tests"
python3 "$ROOT/Tests/check-project.py"
