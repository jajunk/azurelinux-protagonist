---
title: ProtagonistOS Technical Status
status: active
source_of_truth: github
branch: dev
last_reviewed: 2026-04-28
drive_copy: none
source_inputs:
  - AGENTS.md
  - README.md
  - docs/current-state/azure-linux-baseline.md
  - docs/current-state/desktop-performance-reality.md
  - docs/current-state/github-branch-dashboard-state.md
  - docs/current-state/installer-and-iso-path.md
  - docs/current-state/mesa-hardware-driver-plan.md
  - docs/investigations/azure-linux-desktop-gaps.md
  - docs/investigations/kde-package-gap-matrix.md
  - docs/current-state/environment-setup.md
  - docs/decisions/ADR-0001-project-workflow-source-of-truth.md
  - docs/decisions/ADR-0002-branching-upstream-sync-and-access-policy.md
  - docs/decisions/ADR-0003-desktop-environment.md
---

# ProtagonistOS Technical Status

## Current Phase

Planning / pre-build.

No ProtagonistOS desktop package layer is complete yet. The repository is currently a downstream Azure Linux 3.0 fork with project documentation and feasibility analysis layered on top.

## Source of Truth

The Git repository is authoritative.

Google Drive is archive/reference. GitHub Issues should become the active task board. Google Calendar should become the time-planning surface.

The active ProtagonistOS integration branch is `dev`. Stable project state lives on `main`, which is also the live GitHub default branch. The `3.0` branch is reserved as a pristine Azure Linux upstream mirror. The previous `sandbox` branch is legacy and should not receive new project work.

The dashboard publishes through the GitHub Pages workflow on `main`. The latest verification is captured in `docs/current-state/github-branch-dashboard-state.md`.

## Current Technical Direction

The documented target remains:

```text
Azure Linux 3.0
  -> Mesa rebuild with Intel iris and AMD radeonsi
  -> desktop prerequisites
  -> KDE session core
  -> KDE shell and applications
  -> ProtagonistOS branding and defaults
```

## Highest-Priority Engineering Gate

Mesa hardware acceleration is the first hard blocker.

Current inspection result:

- `SPECS/mesa/mesa.spec` sets `with_hardware` to `0`.
- The upstream-default Gallium driver list is `swrast,virgl`.
- The local ProtagonistOS patch adds a narrow downstream x86/x86_64 Gallium path: `swrast,virgl,iris,radeonsi`.
- `iris` and `radeonsi` are now selected without enabling the broader latent `with_hardware` path.

Required first work:

- rebuild Mesa on a Linux host
- confirm expected DRI artifacts are present
- validate hardware rendering on Intel and AMD systems

Until this is done, desktop performance conclusions are not meaningful.

## Current Constraints

- macOS is useful for editing and coordination, but not Azure Linux build validation
- serious package and image builds require a Linux host
- physical hardware validation is required for a credible desktop distro
- upstream Azure Linux toolkit Go source should not be modified casually
- desktop packages should be additions or measured rebuilds, not random replacement of upstream package structure

## Known Documentation State

Active current-state docs:

- `docs/current-state/azure-linux-baseline.md`
- `docs/current-state/desktop-performance-reality.md`
- `docs/current-state/environment-setup.md`
- `docs/current-state/github-branch-dashboard-state.md`
- `docs/current-state/installer-and-iso-path.md`
- `docs/current-state/mesa-hardware-driver-plan.md`

Active investigation docs:

- `docs/investigations/azure-linux-desktop-gaps.md`
- `docs/investigations/kde-package-gap-matrix.md`
- `docs/investigations/personal-ai-workflow-surface.md`

Active workflow decision:

- `docs/decisions/ADR-0001-project-workflow-source-of-truth.md`
- `docs/decisions/ADR-0002-branching-upstream-sync-and-access-policy.md`
- `docs/decisions/ADR-0003-desktop-environment.md`

Legacy detailed reports still present:

- `CUSTOM_DISTRO_FEASIBILITY_REPORT.md`
- `RETROSPECTIVE.md`
- `docs/desktop-performance-reality.md`
- `docs/desktop-security-posture.md`
- `docs/package-management.md`

## Immediate Next Engineering Issues

The initial documentation sprint has enough information to close the first planning issues for Mesa inspection, Mesa patch strategy, KDE package gap inventory, desktop decision, and first image target.

Next implementation issues should be:

1. Build the patched Mesa package on Linux and inspect `mesa-dri-drivers`.
2. Attempt the first `core-efi.json` image build on Linux hardware.
3. Define the first Linux build host as the canonical build environment.
4. Import or package `qtwayland`.
5. Import or package `libdisplay-info`.
6. Import or package `xdg-desktop-portal`.
7. Import or package `wireplumber`.
8. Expand the KDE Frameworks dependency list from actual KWin and Plasma Workspace build requirements.
9. Define the first hardware validation matrix.

## Open Decisions

- first official Linux build host
- first hardware validation targets
- exact first KDE package tranche from KWin/Plasma source dependency inspection
- SELinux enforcement strategy for early graphical builds
