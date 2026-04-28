---
title: GitHub Branch and Dashboard Publication State
status: active
source_of_truth: github
branch: dev
last_reviewed: 2026-04-28
drive_copy: none
source_inputs:
  - GitHub Issue #13
  - docs/decisions/ADR-0002-branching-upstream-sync-and-access-policy.md
  - GitHub repository settings queried with gh on 2026-04-28
  - GitHub Actions run 25005573050
---

# GitHub Branch and Dashboard Publication State

## Verification Summary

Live GitHub state mostly matches the documented branch and dashboard model.

Verified on 2026-04-28 against `jajunk/azurelinux-protagonist`:

- GitHub default branch: `main`
- Protected downstream branches: `main`, `dev`, `3.0`
- Legacy/task branches deleted during follow-up: `sandbox`, `codex/project-dashboard`
- GitHub Pages URL: <https://jajunk.github.io/azurelinux-protagonist/>
- GitHub Pages build type: workflow
- Current successful dashboard deployment: GitHub Actions run `25005573050`, from `main`, created 2026-04-27 15:57:49 UTC
- Published Pages content: HTTP 200, `Last-Modified: Mon, 27 Apr 2026 15:58:03 GMT`

## Branch Roles

| Branch | Live state | Documented role | Verification result |
|---|---:|---|---|
| `main` | Exists, protected, default branch | Stable ProtagonistOS state | Matches |
| `dev` | Exists, protected | Active ProtagonistOS integration branch | Matches |
| `3.0` | Exists, protected | Pristine Azure Linux 3.0 mirror | Matches |
| `sandbox` | Deleted from `origin` on 2026-04-28 | Legacy only; no new work | Cleaned up |
| `codex/project-dashboard` | Deleted from `origin` on 2026-04-28 | Historical dashboard task branch | Cleaned up |

After follow-up cleanup, live GitHub branch listing contains only `main`, `dev`, and `3.0`.

## Branch Protection Snapshot

`main`, `dev`, and `3.0` all have branch protection enabled with:

- administrator enforcement enabled
- force pushes disabled
- branch deletion disabled
- pull request review rule present, with zero required approving reviews

No required status checks are currently configured on those protected branches. This is acceptable only as an early-project state; ADR-0002 says status checks should become required once the checks are stable enough to be meaningful.

## Dashboard Publication Path

The dashboard workflow is `Deploy ProtagonistOS dashboard` at `.github/workflows/pages.yml` on `main`.

Current workflow triggers:

- `push` to `main`, limited to `site/**` and `.github/workflows/pages.yml`
- `workflow_dispatch`

Current workflow actions:

- `actions/checkout@v6`
- `actions/configure-pages@v6`
- `actions/upload-pages-artifact@v5`
- `actions/deploy-pages@v5`

The latest successful deployment checked out `origin/main` at commit `c13037e948fc2314be4e663bb911d19e0ac4419e`, uploaded the `site/` artifact, and reported Pages deployment success for <https://jajunk.github.io/azurelinux-protagonist/>.

## Mismatches and Warnings

### Pages Source Metadata Still Mentions `3.0`

The Pages API reports:

```json
{
  "build_type": "workflow",
  "source": {
    "branch": "3.0",
    "path": "/"
  }
}
```

Because `build_type` is `workflow` and the latest successful Pages deployment came from `main`, the dashboard is publishing through GitHub Actions. The lingering `source.branch: 3.0` value appears to be stale legacy Pages source metadata, but it should be checked in the repository Settings UI.

Operator remediation:

- Open GitHub repository settings.
- Go to Pages.
- Confirm "Build and deployment" is set to GitHub Actions.
- If the UI still shows a branch source, clear or re-save it so it no longer points at `3.0`.
- Re-run `gh api repos/jajunk/azurelinux-protagonist/pages` and confirm the workflow setting remains active.

### `actions/deploy-pages@v5` Emits a Node Warning

The latest dashboard deployment log contains this warning during the `actions/deploy-pages@v5` step:

```text
[DEP0040] DeprecationWarning: The `punycode` module is deprecated.
```

The workflow already sets `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true`, and `actions/deploy-pages@v5.0.0` is the latest published `actions/deploy-pages` release as of 2026-04-28. The remaining warning appears to be inside the Pages action or one of its transitive dependencies.

Exact remediation:

- Keep `actions/deploy-pages` on the newest major release.
- Recheck the latest `actions/deploy-pages` release before the next dashboard workflow change.
- When a newer release is available, update `.github/workflows/pages.yml`, run the dashboard deploy workflow, and confirm the warning is gone from the `Deploy to GitHub Pages` step.

## Operator Notes

- `sandbox` and `codex/project-dashboard` were deleted from `origin` on 2026-04-28 after operator confirmation.
- Add required status checks to `main`, `dev`, and `3.0` after the project decides which workflows are stable branch gates.
- If dashboard deployments should require manual approval later, protect the `github-pages` environment.
