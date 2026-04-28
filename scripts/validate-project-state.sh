#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

failures=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

pass() {
  echo "OK: $*"
}

expect_file() {
  local path="$1"
  if [[ -f "${path}" ]]; then
    pass "found ${path}"
  else
    fail "missing ${path}"
  fi
}

expect_executable() {
  local path="$1"
  if [[ -x "${path}" ]]; then
    pass "executable ${path}"
  else
    fail "not executable ${path}"
  fi
}

origin_url="$(git remote get-url origin 2>/dev/null || true)"
upstream_url="$(git remote get-url upstream 2>/dev/null || true)"

[[ "${origin_url}" == "https://github.com/jajunk/azurelinux-protagonist.git" ]] \
  && pass "origin points at jajunk/azurelinux-protagonist" \
  || fail "origin should point at jajunk/azurelinux-protagonist, found '${origin_url}'"

[[ "${upstream_url}" == "https://github.com/microsoft/azurelinux.git" ]] \
  && pass "upstream points at microsoft/azurelinux" \
  || fail "upstream should point at microsoft/azurelinux, found '${upstream_url}'"

expect_file "scripts/gh-pr-safe"
expect_file "scripts/install-repo-guards.sh"
expect_file "scripts/validate-repo-guards.sh"
expect_file "scripts/validate-project-state.sh"
expect_executable "scripts/gh-pr-safe"
expect_executable "scripts/install-repo-guards.sh"
expect_executable "scripts/validate-repo-guards.sh"
expect_executable "scripts/validate-project-state.sh"

if [[ "$(git config --local --get core.hooksPath || true)" == ".githooks" ]]; then
  pass "core.hooksPath is .githooks"
else
  fail "core.hooksPath is not set to .githooks; run ./scripts/install-repo-guards.sh"
fi

if command -v gh >/dev/null 2>&1; then
  default_repo="$(gh repo set-default --view 2>/dev/null || true)"
  [[ "${default_repo}" == "jajunk/azurelinux-protagonist" ]] \
    && pass "gh default repo is jajunk/azurelinux-protagonist" \
    || fail "gh default repo should be jajunk/azurelinux-protagonist, found '${default_repo}'"
else
  echo "WARN: gh not found; skipping GitHub CLI default repo check" >&2
fi

if rg -n 'active integration branch is `sandbox`|branch: sandbox|microsoft/azurelinux.*pr create' \
  README.md docs scripts .cursor .githooks \
  -g '!scripts/validate-project-state.sh' >/tmp/protagonistos-drift.$$ 2>/dev/null; then
  cat /tmp/protagonistos-drift.$$ >&2
  rm -f /tmp/protagonistos-drift.$$
  fail "found stale branch or unsafe PR-targeting language"
else
  rm -f /tmp/protagonistos-drift.$$
  pass "no obvious stale sandbox or unsafe PR-targeting references"
fi

if git config --local --get-regexp '^branch\..*\.github-pr-base-branch$' >/tmp/protagonistos-branch-config.$$ 2>/dev/null; then
  cat /tmp/protagonistos-branch-config.$$ >&2
  rm -f /tmp/protagonistos-branch-config.$$
  fail "found local branch github-pr-base-branch config; run ./scripts/install-repo-guards.sh"
else
  rm -f /tmp/protagonistos-branch-config.$$
  pass "no stale local github-pr-base-branch config"
fi

if rg -Fq '%global protagonist_desktop_gallium 1' SPECS/mesa/mesa.spec \
  && rg -Fq '%global protagonist_gallium_drivers swrast,virgl,iris,radeonsi' SPECS/mesa/mesa.spec \
  && rg -Fq -- '-Dgallium-drivers=%{protagonist_gallium_drivers}' SPECS/mesa/mesa.spec \
  && rg -Fq 'iris_dri.so' SPECS/mesa/mesa.spec \
  && rg -Fq 'radeonsi_dri.so' SPECS/mesa/mesa.spec; then
  pass "Mesa narrow desktop Gallium path is present"
else
  fail "Mesa narrow desktop Gallium path is incomplete"
fi

if git cat-file -e origin/main:.github/workflows/pages.yml 2>/dev/null; then
  pages_workflow="$(git show origin/main:.github/workflows/pages.yml)"
  if grep -q 'Deploy ProtagonistOS dashboard' <<<"${pages_workflow}" \
    && grep -q 'workflow_dispatch' <<<"${pages_workflow}" \
    && grep -q -- '- main' <<<"${pages_workflow}" \
    && grep -q 'path: site' <<<"${pages_workflow}"; then
    pass "dashboard workflow on origin/main targets main and site/"
  else
    fail "dashboard workflow on origin/main is missing expected main/site deployment assumptions"
  fi
else
  fail "origin/main:.github/workflows/pages.yml is missing; fetch origin/main or restore dashboard workflow"
fi

if (( failures > 0 )); then
  echo "Project state validation failed with ${failures} issue(s)." >&2
  exit 1
fi

echo "Project state validation passed."
