---
title: "Dashboard Baseline: Planning and Pre-build"
date: "2026-04-24"
summary: "The first public dashboard snapshot records ProtagonistOS as a documentation-led Azure Linux desktop effort with Mesa, build host, package matrix, and image path work ahead."
---

## Current phase

ProtagonistOS is in **Planning / Pre-build**. The repository is currently a downstream Azure Linux 3.0 fork with project documentation, feasibility analysis, and the first sprint issues layered on top.

There is no downloadable ProtagonistOS desktop image yet. That is intentional: the project is still proving the base graphics, build, and image paths before treating the desktop vision as validated.

## What is known

- Azure Linux 3.0 is a plausible but difficult base for a custom desktop distribution.
- The target direction is now KDE-first, formalized by ADR-0003 after the original dashboard baseline was drafted.
- The repository is the source of truth for current technical state.
- GitHub Issues are the active workflow surface for blockers and near-term tasks.

## First engineering blocker

Mesa hardware acceleration is the first hard gate. The Mesa spec needs to be inspected and validated so the project can confirm the correct path for Intel `iris` and AMD `radeonsi` Gallium drivers.

Until hardware rendering is proven, desktop performance claims would be premature.

## Near-term work

- Inspect the Mesa spec and document the active hardware-driver build path.
- Define the Mesa enablement plan.
- Create the desktop package gap matrix.
- Keep active planning aligned with the KDE desktop decision.
- Define the minimal ISO or image build path.

This dashboard will track those workstreams publicly as the project moves from planning into build validation.
