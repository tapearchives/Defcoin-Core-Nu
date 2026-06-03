#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v pre-commit >/dev/null 2>&1; then
  if command -v pipx >/dev/null 2>&1; then
    pipx install pre-commit
  elif command -v brew >/dev/null 2>&1; then
    brew install pre-commit
  else
    python3 -m venv .venv-pre-commit
    .venv-pre-commit/bin/python -m pip install --upgrade pip pre-commit
    export PATH="$repo_root/.venv-pre-commit/bin:$PATH"
  fi
fi

pre-commit install

echo "Running the initial Ruff/pre-commit baseline across tracked files..."
pre-commit run --all-files
