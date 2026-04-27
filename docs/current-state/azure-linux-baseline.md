---
title: Azure Linux Baseline
status: active
source_of_truth: github
branch: dev
last_reviewed: 2026-04-27
drive_copy: none
source_inputs:
  - AGENTS.md
---

# Azure Linux Baseline

## Purpose

This document captures the current technical baseline for using Azure Linux 3.0 as the foundation for ProtagonistOS.

It is derived from the repository project guidelines in `AGENTS.md` and should be treated as the concise current-state reference for the base system.

## Current Verdict

Azure Linux 3.0 is a plausible but difficult base for ProtagonistOS.

Its strengths are RPM packaging, a disciplined build pipeline, reproducible source/signature handling, and a hardened enterprise-style baseline.

Its weakness is that it is server/cloud-first. A desktop distribution must add or rebuild a substantial graphical stack before it can be treated as a credible workstation base.

## Repository Role

This repository is a downstream fork of `microsoft/azurelinux`, branch `3.0`.

The fork is not a passive mirror. It is intended to diverge deliberately to support a custom desktop distribution.

## Target Architecture

The intended build-up path is:

```text
Azure Linux 3.0
  -> Mesa rebuild with Intel iris and AMD radeonsi Gallium drivers
  -> Desktop prerequisites
  -> KDE session core components
  -> KDE shell and applications
  -> ProtagonistOS branding, defaults, and developer-focused system policy
```

## Current Development Phase

The project is in planning / pre-build phase as of April 2026.

No desktop package layer is considered complete yet.

The current engineering priority is not branding, installer polish, or default applications. The first priority is making the graphical stack technically viable.

## Key Baseline Facts

### Build system

Azure Linux uses a three-stage build process:

1. Toolchain bootstrap or download
2. Package build from RPM specs into SRPM/RPM artifacts
3. Image assembly through declarative image configuration

The build tooling is Go-based and orchestrated through `make`.

A Linux build host is required. macOS is not a supported build host for validation.

### Package structure

The important repository areas are:

- `SPECS/` for primary RPM specs
- `SPECS-EXTENDED/` for extended package specs
- `SPECS-SIGNED/` for signed boot/kernel/EFI wrappers
- `toolkit/` for the build system
- `toolkit/imageconfigs/` for image composition definitions
- `toolkit/docs/` for build-system documentation

### Desktop enablement path

The first desktop-enablement sequence is:

1. Rebuild Mesa with required hardware drivers.
2. Add missing desktop prerequisites.
3. Add KDE session baseline packages.
4. Add KDE login/session integration packages.
5. Add KDE shell and application packages.
6. Only then work on final image composition and polish.

## First Engineering Dependency: Mesa

Mesa must be rebuilt for hardware desktop support.

The current inspection result is documented in [Mesa hardware driver plan](mesa-hardware-driver-plan.md). The active Azure Linux Mesa Gallium path is currently `swrast,virgl` because `SPECS/mesa/mesa.spec` sets `with_hardware` to `0`.

The immediate requirement is to update the Mesa spec so the build includes the Gallium drivers required for realistic workstation graphics support.

Minimum required targets:

- `iris` for modern Intel integrated graphics
- `radeonsi` for AMD graphics

Without this, the desktop stack risks falling back to software rendering or incomplete virtualized rendering paths, which is not acceptable for ProtagonistOS.

## Constraints

### Do not casually modify upstream build tooling

The toolkit Go source should be treated as upstream-maintained infrastructure. Changes to the toolkit should be avoided unless there is a specific, measured reason.

### Preserve upstream package library assumptions

The Azure Linux package library should be treated as the base inventory. Desktop work should primarily add or extend packages, not randomly replace upstream structure.

### Validate on Linux

All serious build validation must happen on a Linux host.

A Mac or VM can be useful for reading, editing, or early inspection, but it is not the proving ground for the distribution.

## Practical Consequences for ProtagonistOS

- The project should remain build-system-first until the ISO path is understood.
- Desktop package work should begin with Mesa, not KDE shell packages.
- Hardware acceleration is a credibility gate.
- The fork must maintain a clear distinction between upstream Azure Linux and downstream ProtagonistOS changes.
- Documentation must record where the fork intentionally diverges.

## Open Questions

- Which Linux host should run the first Mesa package build and image build?
- Which physical machines should make up the first Intel and AMD validation targets?
- Which exact KWin and Plasma Workspace dependency versions should define the first KDE import tranche?

Resolved planning questions:

- The first Mesa spec change should enable a narrow ProtagonistOS Gallium set: `swrast,virgl,iris,radeonsi`.
- The first KDE gap matrix is recorded in [KDE package gap matrix](../investigations/kde-package-gap-matrix.md).
- The first image target is `toolkit/imageconfigs/core-efi.json`, documented in [Installer and ISO path](installer-and-iso-path.md).

## Current Recommendation

Treat Azure Linux as an engineering research base until the package and image pipeline can produce a bootable image that consumes the first rebuilt desktop package.

Do not assume that the distribution vision is validated just because the repository builds. For ProtagonistOS, the first meaningful proof is a `core-efi` image from this fork, followed by a Mesa-consuming image that reaches hardware rendering on target-class Intel and AMD systems. A graphical ISO comes after that.
