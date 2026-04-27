#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ALLOWED_REPO="${ALLOWED_PR_REPO:-jajunk/azurelinux-protagonist}"

cd "${REPO_ROOT}"

chmod +x .githooks/pre-push
chmod +x .cursor/hooks/block-upstream-pr.sh
chmod +x scripts/gh-pr-safe

git config --local core.hooksPath .githooks

if command -v gh >/dev/null 2>&1; then
  gh repo set-default "${ALLOWED_REPO}" >/dev/null
fi

if git config --local --get-regexp '^branch\..*\.github-pr-base-branch$' >/dev/null 2>&1; then
  while IFS= read -r key; do
    git config --local --unset "${key}" || true
  done < <(git config --local --name-only --get-regexp '^branch\..*\.github-pr-base-branch$')
fi

echo "Repository guards installed."
echo "- core.hooksPath=.githooks"
echo "- gh default repo=${ALLOWED_REPO}"
echo "- executable guard scripts enabled"
