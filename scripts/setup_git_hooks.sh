#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

chmod +x "$ROOT_DIR/.githooks/pre-commit"
chmod +x "$ROOT_DIR/scripts/pre_commit_checks.sh"

git -C "$ROOT_DIR" config core.hooksPath .githooks

echo "Git hooks are enabled from .githooks/"
echo "Pre-commit will now run scripts/pre_commit_checks.sh"
