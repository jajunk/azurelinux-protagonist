---
title: Installer and ISO Path
status: active
source_of_truth: github
branch: dev
last_reviewed: 2026-04-27
drive_copy: none
source_inputs:
  - GitHub Issue #5
  - toolkit/imageconfigs/core-efi.json
  - toolkit/imageconfigs/minimal-os.json
  - toolkit/imageconfigs/full.json
  - toolkit/docs/building/building.md
  - toolkit/docs/how_it_works/4_image_generation.md
---

# Installer and ISO Path

## Purpose

This document defines the first meaningful ProtagonistOS build artifact and the path from package proof to image proof to installable ISO.

## Decision

The first ProtagonistOS artifact should be an EFI VHDX image based on `toolkit/imageconfigs/core-efi.json`, not a graphical ISO.

The first artifact is intentionally conservative:

- It proves the Azure Linux image pipeline from this fork.
- It gives a bootable target for consuming rebuilt RPMs.
- It avoids pretending the KDE desktop layer exists before Mesa and package prerequisites are ready.
- It is easier to debug than a full installer ISO.

## Why Not Start With A Graphical ISO

A graphical ISO is premature because:

- Mesa hardware Gallium drivers are not enabled yet.
- KDE Plasma/KWin/session packages are missing.
- desktop portals and other prerequisites are missing.
- no canonical Linux build host has completed a clean image build for this fork.
- installer polish would distract from the graphics and package gates.

The ISO path remains important, but it should follow package and image proof.

## Existing Image Configs

| Config | Output intent | Use for first ProtagonistOS proof? | Notes |
|---|---|---:|---|
| `toolkit/imageconfigs/core-efi.json` | EFI bootable VHDX named `core` | Yes | Best first target: bootable, practical, includes cloud-init and VM-oriented package lists |
| `toolkit/imageconfigs/minimal-os.json` | very small EFI VHDX | No | Too stripped down for first practical debugging; useful later for minimal-base experiments |
| `toolkit/imageconfigs/full.json` | multi-config full/core image input and ISO source | Later | Better suited once package and image path are understood |
| future `toolkit/imageconfigs/protagonistos-kde-minimal.json` | ProtagonistOS graphical image | Later | Create after Mesa and the first KDE prerequisite tranche exists |

## Build Stages

### Stage 0: Package Proof

Goal:

Build the first divergent package without composing a full desktop image.

First package target:

```text
mesa
```

Command from repository root:

```bash
sudo make build-packages \
  CONFIG_FILE=toolkit/imageconfigs/core-efi.json \
  PACKAGE_BUILD_LIST=mesa \
  REBUILD_TOOLS=y
```

Acceptance criteria:

- The package build completes on Linux.
- `mesa-dri-drivers` contains `iris_dri.so` and `radeonsi_dri.so` after the future Mesa patch.
- Build logs are saved with the branch or issue notes.

### Stage 1: First Bootable Image

Goal:

Build an unbranded EFI image from the existing Azure Linux config to prove the compose path.

Command from repository root:

```bash
sudo make image \
  CONFIG_FILE=toolkit/imageconfigs/core-efi.json \
  REBUILD_TOOLS=y
```

Expected output family:

```text
out/images/core-efi/
```

Acceptance criteria:

- Image build completes on a Linux host.
- The resulting VHDX boots in a supported VM path.
- A user can be provisioned through the documented cloud-init/meta-user-data path.
- The system reaches a login-capable text environment.
- Kernel, package, and image versions are recorded.

### Stage 2: First ProtagonistOS Package-Consuming Image

Goal:

Consume the rebuilt Mesa RPM in a bootable image.

This can still use `core-efi.json` initially. Do not create a new image config until the package overlay behavior is understood.

Acceptance criteria:

- The image installs or includes the rebuilt Mesa package.
- `rpm -q mesa mesa-dri-drivers` reports the expected rebuilt version/release.
- `rpm -ql mesa-dri-drivers` includes the expected DRI artifacts.
- The image boots in a VM after the Mesa change.

### Stage 3: Minimal Graphical Bring-Up Image

Goal:

Create the first ProtagonistOS-specific image config only after the following are true:

- Mesa hardware driver package build succeeds.
- The KDE package gap matrix has a first package tranche.
- desktop prerequisite package imports are underway.
- the project knows which session launch path is being tested.

Likely future config:

```text
toolkit/imageconfigs/protagonistos-kde-minimal.json
```

Likely future package list:

```text
toolkit/imageconfigs/packagelists/protagonistos-kde-minimal-packages.json
```

Initial graphical acceptance criteria:

- Image boots on EFI.
- Hardware Mesa DRI artifacts are present.
- A minimal Wayland/KDE session path can be launched or a known placeholder compositor can validate the graphics path.
- Renderer output confirms hardware acceleration on at least one Intel target and one AMD target before public desktop claims.

### Stage 4: Installable ISO

Goal:

Build an installable ISO only after the image config is stable enough to install.

Toolkit reference command shape:

```bash
sudo make iso \
  CONFIG_FILE=toolkit/imageconfigs/full.json \
  REBUILD_TOOLS=y
```

The actual ProtagonistOS ISO command should use the future ProtagonistOS image config once it exists.

ISO acceptance criteria:

- ISO build completes on the canonical Linux build host.
- ISO boots in a VM.
- Installer path installs the intended image.
- Installed system boots without the ISO attached.
- Logs and build artifacts are archived.

## First Build Host Requirements

The first Linux host is not defined by this document, but the image path assumes:

- Linux host, not macOS.
- enough disk for Azure Linux toolchain, package, and image outputs.
- `sudo` access for image build steps that require loop devices, chroot, or filesystem operations.
- stable network access for any package/toolchain downloads not already cached.
- recorded host distro, kernel, CPU, memory, disk, filesystem, and available free space.

## Current First Artifact

The first artifact to build is:

```text
toolkit/imageconfigs/core-efi.json
```

The first success condition is:

```text
An Azure Linux EFI VHDX image from this fork boots and can be logged into.
```

The first ProtagonistOS-specific success condition is:

```text
That same image path consumes a rebuilt Mesa package with Intel iris and AMD radeonsi DRI artifacts present.
```

Only after those are true should the project spend time on a ProtagonistOS graphical ISO.
