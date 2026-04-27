#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

required_files=(
  "scripts/gh-pr-safe"
  "scripts/install-repo-guards.sh"
  ".githooks/pre-push"
  ".cursor/hooks.json"
  ".cursor/hooks/block-upstream-pr.sh"
  ".cursor/rules/pr-target-guardrails.mdc"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "${file}" ]]; then
    echo "Missing required file: ${file}" >&2
    exit 1
  fi
done

for executable in scripts/gh-pr-safe scripts/install-repo-guards.sh .githooks/pre-push .cursor/hooks/block-upstream-pr.sh; do
  if [[ ! -x "${executable}" ]]; then
    echo "Expected executable permission on: ${executable}" >&2
    exit 1
  fi
done

if [[ "$(git config --local --get core.hooksPath || true)" != ".githooks" ]]; then
  echo "core.hooksPath is not set to .githooks" >&2
  exit 1
fi

if command -v gh >/dev/null 2>&1; then
  default_repo="$(gh repo set-default --view 2>/dev/null || true)"
  if [[ "${default_repo}" != "jajunk/azurelinux-protagonist" ]]; then
    echo "gh default repo is not jajunk/azurelinux-protagonist" >&2
    exit 1
  fi
fi

echo "Repository guardrails validated."
