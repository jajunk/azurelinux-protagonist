---
title: Mesa Hardware Driver Plan
status: active
source_of_truth: github
branch: dev
last_reviewed: 2026-04-28
drive_copy: none
source_inputs:
  - GitHub Issue #1
  - GitHub Issue #2
  - SPECS/mesa/mesa.spec
  - docs/current-state/azure-linux-baseline.md
  - docs/current-state/desktop-performance-reality.md
---

# Mesa Hardware Driver Plan

## Purpose

This document closes the Mesa inspection and planning questions for the first ProtagonistOS desktop engineering gate.

It records what Azure Linux currently builds from `SPECS/mesa/mesa.spec`, why that is insufficient for a bare-metal KDE desktop, and the first patch strategy for enabling Intel `iris` and AMD `radeonsi`.

## Current Mesa Spec Facts

The current spec is:

| Field | Value |
|---|---|
| Spec path | `SPECS/mesa/mesa.spec` |
| Package | `mesa` |
| Version | `24.0.1` |
| Release | `6%{?dist}` |
| Build system | Meson through `%meson` |
| Platforms | `-Dplatforms=x11,wayland` |
| DRI3 | `-Ddri3=enabled` |
| OSMesa | `-Dosmesa=true` |
| LLVM | `-Dllvm=enabled`, `-Dshared-llvm=enabled` |
| LTO | disabled through `%define _lto_cflags %{nil}` |

The controlling Gallium macro is set near the top of the spec:

```spec
%ifnarch s390x
%global with_hardware 0
%global with_vulkan_hw 1
%global with_vdpau 0
%global with_va 0
```

That means the active Gallium Meson path is the non-hardware branch:

```spec
%if 0%{?with_hardware}
  -Dgallium-drivers=swrast,virgl,nouveau...
%else
  -Dgallium-drivers=swrast,virgl \
%endif
```

The currently enabled Gallium drivers are therefore:

| Driver | Purpose | Desktop relevance |
|---|---|---|
| `swrast` | CPU software rendering | Useful fallback, not acceptable as the primary desktop renderer |
| `virgl` | Virtual GPU rendering | Useful for VM paths, not sufficient for bare-metal workstation graphics |

The spec already declares latent hardware-driver macros:

| Macro | Current value where applicable | Effective today? |
|---|---:|---|
| `with_iris` | `1` on x86/x86_64 | No, because `with_hardware` is `0` |
| `with_crocus` | `1` on x86/x86_64 | No, because `with_hardware` is `0` |
| `with_i915` | `1` on x86/x86_64 | No, because `with_hardware` is `0` |
| `with_radeonsi` | `1` on non-s390x | No, because `with_hardware` is `0` |
| `with_r600` | `1` on non-s390x for non-RHEL builds | No, because `with_hardware` is `0` |
| `with_vmware` | `1` on non-s390x | No, because `with_hardware` is `0` |

The file list mirrors that gating. `mesa-dri-drivers` always owns the software and virtio paths:

```spec
%{_libdir}/dri/kms_swrast_dri.so
%{_libdir}/dri/swrast_dri.so
%{_libdir}/dri/virtio_gpu_dri.so
```

The hardware DRI artifacts are already listed, but only inside `%if 0%{?with_hardware}`:

```spec
%{_libdir}/dri/radeonsi_dri.so
%{_libdir}/dri/crocus_dri.so
%{_libdir}/dri/i915_dri.so
%{_libdir}/dri/iris_dri.so
```

## Important Nuance: Vulkan Is Separate

The spec sets `with_vulkan_hw` to `1` on non-s390x architectures and builds Vulkan drivers through:

```spec
-Dvulkan-drivers=%{?vulkan_drivers}
```

On x86_64, the macro expansion includes software Vulkan plus AMD and Intel Vulkan ICDs. That does not solve the desktop OpenGL/Gallium path. A KDE Plasma Wayland session still needs the DRI/Gallium driver side to avoid falling back to software rendering in common GL/EGL paths.

## Desktop-Relevant Missing Output

The first ProtagonistOS desktop Mesa build must produce at minimum:

| Artifact | Expected package | Why |
|---|---|---|
| `%{_libdir}/dri/iris_dri.so` | `mesa-dri-drivers` | Modern Intel integrated graphics |
| `%{_libdir}/dri/radeonsi_dri.so` | `mesa-dri-drivers` | AMD RadeonSI OpenGL/Gallium graphics |
| existing `swrast` and `virgl` artifacts | `mesa-dri-drivers` | Fallback and VM support retained |

Do not remove `swrast` or `virgl`. They remain useful for rescue, CI, VM, and headless validation paths.

## Implemented Patch Strategy

The smallest safe downstream patch is not to enable every latent hardware driver blindly. Flipping `with_hardware` from `0` to `1` would pull in a much broader set of Gallium drivers on x86_64, including drivers that are not part of the first ProtagonistOS hardware target.

As of 2026-04-28, `SPECS/mesa/mesa.spec` has a ProtagonistOS-specific narrow hardware path:

1. A downstream macro enables the first desktop target:

   ```spec
   %global protagonist_desktop_gallium 1
   ```

2. The Meson Gallium driver selection prefers that narrow path before the broad `with_hardware` branch:

   ```spec
   %if 0%{?protagonist_desktop_gallium}
     -Dgallium-drivers=%{protagonist_gallium_drivers} \
   %elif 0%{?with_hardware}
     -Dgallium-drivers=swrast,virgl,nouveau...
   %else
     -Dgallium-drivers=swrast,virgl \
   %endif
   ```

3. Matching file ownership for the new DRI artifacts exists without requiring the full `with_hardware` branch:

   ```spec
   %if 0%{?protagonist_desktop_gallium}
   %ifarch %{ix86} x86_64
   %{_libdir}/dri/iris_dri.so
   %endif
   %ifnarch s390x
   %{_libdir}/dri/radeonsi_dri.so
   %endif
   %endif
   ```

4. VAAPI and VDPAU remain disabled for the first patch unless a test build proves those outputs are required by the initial KDE session bring-up.

5. Older Intel (`crocus`, `i915`) and older AMD (`r600`) remain out of the first acceptance gate unless the first hardware validation matrix explicitly includes those GPU generations.

This keeps the first Mesa divergence easy to review: one existing spec, a narrow driver list, and two expected new DRI artifacts.

On x86 and x86_64, `%{protagonist_gallium_drivers}` expands to `swrast,virgl,iris,radeonsi`. On non-s390x non-x86 architectures, it omits `iris` and expands to `swrast,virgl,radeonsi`.

## Build Impact

Expected impact:

- `mesa` rebuild required.
- `mesa-dri-drivers` content changes.
- LLVM-backed Gallium build paths become relevant for the new drivers.
- Image composition does not change until the rebuilt RPMs are consumed by a test image.

Expected package ownership checks after a successful build:

```bash
rpm -ql mesa-dri-drivers | rg 'iris_dri|radeonsi_dri|swrast_dri|virtio_gpu_dri'
```

Expected files:

```text
/usr/lib64/dri/iris_dri.so
/usr/lib64/dri/radeonsi_dri.so
/usr/lib64/dri/kms_swrast_dri.so
/usr/lib64/dri/swrast_dri.so
/usr/lib64/dri/virtio_gpu_dri.so
```

Use the architecture-appropriate library directory if not building x86_64.

## Build Command

The first implementation branch should validate the package build on Linux before attempting a full image:

```bash
sudo make build-packages \
  CONFIG_FILE=toolkit/imageconfigs/core-efi.json \
  PACKAGE_BUILD_LIST=mesa \
  REBUILD_TOOLS=y
```

Then consume the rebuilt RPM in the first image path:

```bash
sudo make image \
  CONFIG_FILE=toolkit/imageconfigs/core-efi.json \
  REBUILD_TOOLS=y
```

If the build is run from inside `toolkit/`, use `./imageconfigs/core-efi.json` as the config path.

## Hardware Validation

Minimum validation commands on installed or booted test systems:

```bash
glxinfo -B
eglinfo -B
ls /usr/lib64/dri/iris_dri.so /usr/lib64/dri/radeonsi_dri.so
```

Expected result:

- Intel target reports an Intel hardware renderer, not `llvmpipe`, `softpipe`, or `swrast`.
- AMD target reports an AMD/Radeon hardware renderer, not `llvmpipe`, `softpipe`, or `swrast`.
- A simple Wayland compositor or KDE session smoke test can start without forcing software rendering.

## Risks

| Risk | Severity | Mitigation |
|---|---:|---|
| Mesa build exposes missing dependencies | High | Keep first driver set narrow; build Mesa alone before image work |
| File list misses new DRI artifacts | Medium | Add explicit `%files dri-drivers` entries for `iris` and `radeonsi` |
| Hardware drivers build but do not load | High | Validate on real Intel and AMD systems, not only VM paths |
| Vulkan looks healthy while OpenGL/EGL still falls back | Medium | Always validate `glxinfo -B` or equivalent GL/EGL renderer output |
| Full `with_hardware=1` enables too much at once | Medium | Use a ProtagonistOS-specific narrow macro for the first patch |

## Decision

The first implementation branch modifies only `SPECS/mesa/mesa.spec` for Mesa itself and enables the narrow x86/x86_64 Gallium set:

```text
swrast,virgl,iris,radeonsi
```

The next required action is a Linux-host package build of `mesa`, followed by inspection of `mesa-dri-drivers` ownership for `iris_dri.so` and `radeonsi_dri.so`.

That patch is the first real desktop-enablement code change for ProtagonistOS.
