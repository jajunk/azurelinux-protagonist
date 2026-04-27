#!/usr/bin/env bash
set -euo pipefail

ALLOWED_REPO="${ALLOWED_PR_REPO:-jajunk/azurelinux-protagonist}"
OVERRIDE="${ALLOW_UPSTREAM_PR:-0}"

payload="$(cat)"
command="$(
  printf "%s" "${payload}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("command",""))'
)"

deny() {
  local reason="$1"
  printf '{"permission":"deny","user_message":"%s","agent_message":"%s"}\n' "${reason}" "${reason}"
  exit 0
}

allow() {
  printf '{"permission":"allow"}\n'
  exit 0
}

if [[ "${command}" != *"gh pr create"* ]]; then
  allow
fi

if [[ "${OVERRIDE}" == "1" ]]; then
  allow
fi

if [[ "${command}" == *"--repo microsoft/azurelinux"* || "${command}" == *"-R microsoft/azurelinux"* ]]; then
  deny "Blocked: upstream PR creation is disabled by default in this repository."
fi

if [[ "${command}" == *"--repo "* || "${command}" == *" -R "* ]]; then
  if [[ "${command}" != *"--repo ${ALLOWED_REPO}"* && "${command}" != *"-R ${ALLOWED_REPO}"* ]]; then
    deny "Blocked: gh pr create must target ${ALLOWED_REPO}."
  fi
else
  deny "Blocked: gh pr create requires --repo ${ALLOWED_REPO}. Use scripts/gh-pr-safe."
fi

allow
