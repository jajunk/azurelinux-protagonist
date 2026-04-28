---
title: KDE Package Gap Matrix
status: active
source_of_truth: github
branch: dev
last_reviewed: 2026-04-28
drive_copy: none
source_inputs:
  - GitHub Issue #3
  - docs/decisions/ADR-0003-desktop-environment.md
  - docs/investigations/azure-linux-desktop-gaps.md
  - local SPECS and SPECS-EXTENDED inventory
---

# KDE Package Gap Matrix

## Purpose

This investigation records the first KDE-first package inventory for ProtagonistOS.

It is a planning matrix, not a complete Plasma packaging import plan. The goal is to identify the immediate package gaps between Azure Linux 3.0 and a minimal KDE/Plasma desktop bring-up.

## Scope

The first KDE milestone is a minimal Wayland-capable Plasma session path, not a fully polished desktop distribution.

In scope:

- Mesa hardware enablement
- Wayland, input, display, session, and portal prerequisites
- Qt/KDE Frameworks substrate
- Plasma session core
- display manager path
- enough shell and application surface to validate a login session

Out of scope for the first matrix:

- full KDE Gear application suite
- visual branding and artwork
- installer UX polish
- third-party application catalog
- complete SELinux policy implementation

## Inventory Method

On 2026-04-27, local package availability was checked by searching `SPECS/` and `SPECS-EXTENDED/` for exact or obvious package directories.

Status meanings:

| Status | Meaning |
|---|---|
| present | A local spec exists and is plausibly usable as part of the KDE path |
| present in extended | A local spec exists under `SPECS-EXTENDED/`; promotion or repo-policy work may be needed |
| needs rebuild | A local spec exists, but its current build options are insufficient |
| missing | No matching local spec was found |
| unclear | More dependency inspection is needed before classifying |

## Matrix

| Package or component | Purpose | Required for first KDE bring-up? | Azure Linux location | Status | Notes |
|---|---|---:|---|---|---|
| `mesa` | OpenGL/EGL/Gallium graphics stack | Yes | `SPECS/mesa` | needs rebuild | Present, but Gallium hardware path currently builds only `swrast,virgl`; enable `iris,radeonsi` first |
| `libdrm` | DRM userspace library | Yes | `SPECS/libdrm` | present | Required by Mesa and compositors |
| `vulkan-loader` | Vulkan loader | No for first GL smoke test, useful later | `SPECS/vulkan-loader` | present | Vulkan hardware drivers appear separately enabled in Mesa |
| `vulkan-headers` | Vulkan build headers | No runtime | `SPECS/vulkan-headers` | present | Build substrate |
| `wayland` | Wayland protocol/runtime libraries | Yes | `SPECS/wayland` | present | Version observed: 1.22.0 |
| `wayland-protocols` | Protocol definitions | Yes | `SPECS/wayland-protocols` | present | Build dependency for compositor/shell work |
| `xorg-x11-server-Xwayland` | Xwayland compatibility | Strongly recommended | `SPECS/xorg-x11-server-Xwayland` | present | Version observed: 24.1.6 |
| `libinput` | Input device stack | Yes | `SPECS/libinput` | present | Core compositor dependency |
| `systemd-logind` | Session and seat management path | Yes | `SPECS/systemd` | present | May be enough for first bring-up if `libseat` is deferred |
| `dbus` | Desktop service bus | Yes | `SPECS/dbus` | present | Required broadly by KDE and portals |
| `polkit` | Authorization framework | Yes | `SPECS/polkit` | present | Required by settings and system actions |
| `polkit-qt-1` | Qt bindings for polkit | Likely | `SPECS/polkit-qt-1` | present | Useful KDE integration component |
| `accountsservice` | User account metadata | Likely | `SPECS-EXTENDED/accountsservice` | present in extended | Version observed: 23.13.9 |
| `upower` | Power device state | Likely | `SPECS-EXTENDED/upower` | present in extended | Version observed: 0.99.11 |
| `bluez` | Bluetooth daemon/libraries | No for first login, yes for desktop | `SPECS/bluez` | present | UI integration packages still missing |
| `ModemManager` | WWAN modem support | No for first login | `SPECS/ModemManager` | present | KDE bindings are missing |
| `wpa_supplicant` | Wi-Fi supplicant | Hardware-dependent | `SPECS/wpa_supplicant` | present | Network UI path still unresolved |
| `iwd` | Alternative Wi-Fi daemon | Hardware-dependent | `SPECS-EXTENDED/iwd` | present in extended | Needs policy decision if preferred |
| `pipewire` | Modern audio/video graph | Strongly recommended | `SPECS-EXTENDED/pipewire` | present in extended | Version macro-based; session manager still missing |
| `wireplumber` | PipeWire session manager | Strongly recommended | none found | missing | Needed for a modern desktop audio baseline |
| `pulseaudio` | Legacy audio server | No if PipeWire path chosen | `SPECS-EXTENDED/pulseaudio` | present in extended | Fallback only, not preferred desktop direction |
| `libseat` | Seat/session abstraction | Strongly recommended | none found | missing | May be deferred if KDE/KWin path can rely on logind initially |
| `seatd` | Seat daemon backend for libseat | Optional if logind-only | none found | missing | Required only if choosing seatd path |
| `libdisplay-info` | Display EDID/DisplayID parser | Likely | none found | missing | Common modern compositor dependency |
| `xdg-desktop-portal` | Base desktop portal service | Yes for real desktop | none found | missing | Required for sandbox/app integration and many desktop flows |
| `xdg-desktop-portal-kde` | KDE portal backend | Yes for KDE desktop | none found | missing | Must follow base portal package |
| `qtbase` | Qt 6 base libraries | Yes | `SPECS/qtbase` | present | Version observed: 6.6.3 |
| `qtdeclarative` | QML/Qt Quick | Yes | `SPECS/qtdeclarative` | present | Needed by modern KDE UI |
| `qtsvg` | SVG support | Likely | `SPECS/qtsvg` | present | Common KDE dependency |
| `qttools` | Qt tools | Build-time | `SPECS/qttools` | present | Build substrate |
| `qt-rpm-macros` | Qt RPM helper macros | Build-time | `SPECS/qt-rpm-macros` | present | Packaging substrate |
| `qtwayland` | Qt Wayland client/compositor support | Yes | none found | missing | Critical for a Wayland-first KDE session |
| `qt6-qtconnectivity` | Qt connectivity module | No for first login | `SPECS-EXTENDED/qt6-qtconnectivity` | present in extended | Later feature dependency |
| `qt6-qtsensors` | Qt sensors module | No for first login | `SPECS-EXTENDED/qt6-qtsensors` | present in extended | Later/mobile-adjacent dependency |
| `qt6-qtserialport` | Qt serial module | No for first login | `SPECS-EXTENDED/qt6-qtserialport` | present in extended | Later app dependency |
| `kf` | KDE Frameworks aggregate/source package | Yes as substrate | `SPECS/kf` | present | Version observed: 5.249.0 |
| `kf-kconfig` | KDE configuration framework | Yes | `SPECS/kf-kconfig` | present | Version observed: 5.249.0 |
| `kf-kcoreaddons` | KDE core helpers | Yes | `SPECS/kf-kcoreaddons` | present | Framework subset exists |
| `kf-ki18n` | KDE internationalization | Yes | `SPECS/kf-ki18n` | present | Framework subset exists |
| `kf-kwidgetsaddons` | KDE widgets helpers | Likely | `SPECS/kf-kwidgetsaddons` | present | Framework subset exists |
| `kde-filesystem` | KDE filesystem ownership | Yes | `SPECS-EXTENDED/kde-filesystem` | present in extended | May need promotion if building core KDE packages in `SPECS/` |
| `kde-settings` | Fedora-derived KDE defaults | Maybe | `SPECS/kde-settings` | present | Version observed: 39.1; usefulness for ProtagonistOS needs review |
| `kio` / `kf-kio` | KDE I/O framework | Yes for real desktop | none found | missing | Blocks many KDE apps |
| `solid` / `kf-solid` | Hardware abstraction | Likely | none found | missing | Needed by Plasma and device integration |
| `kglobalaccel` | Global shortcuts | Likely | none found | missing | Desktop shell dependency |
| `kidletime` | Idle detection | Likely | none found | missing | Power/session behavior |
| `kwindowsystem` | Window-system integration | Likely | none found | missing | KWin/Plasma dependency |
| `kdbusaddons`, `kservice`, `kconfigwidgets` | Common KDE frameworks | Likely | none found | missing | Representative framework gaps, not exhaustive |
| `kwayland` | KDE Wayland integration | Yes | none found | missing | Core KDE Wayland substrate |
| `plasma-wayland-protocols` | Plasma-specific Wayland protocols | Yes | none found | missing | Needed before Plasma/KWin packaging |
| `layer-shell-qt` | Layer shell Qt integration | Yes | none found | missing | Common Plasma shell dependency |
| `kdecoration` | Window decoration framework | Yes for KWin | none found | missing | KWin dependency |
| `kwin` | KDE compositor/window manager | Yes | none found | missing | Core session blocker |
| `plasma-workspace` | Plasma shell/session workspace | Yes | none found | missing | Core session blocker |
| `plasma-desktop` | Desktop shell integration | Yes for full desktop | none found | missing | First full desktop tranche |
| `sddm` | Display manager | Strongly recommended | none found | missing | Could temporarily use direct session launch during bring-up |
| `breeze` | Default KDE theme/assets | Strongly recommended | none found | missing | Needed for a normal Plasma experience |
| `qqc2-desktop-style` | Qt Quick Controls desktop style | Strongly recommended | none found | missing | Needed for KDE QML UI polish and consistency |
| `kscreen` | Display configuration | Strongly recommended | none found | missing | Hardware-display validation tool |
| `powerdevil` | Power management daemon | Strongly recommended | none found | missing | Laptop usability dependency |
| `kscreenlocker` | Screen locking | Later security baseline | none found | missing | Needed before daily-driver use |
| `dolphin` | File manager | Later shell app | none found | missing | Not required for first compositor proof |
| `konsole` | Terminal | Useful early app | none found | missing | A terminal is useful for first graphical smoke tests |
| `systemsettings` | KDE settings app | Later shell app | none found | missing | Needed for real desktop usability |
| `plasma-nm` | NetworkManager UI | Later desktop integration | none found | missing | NetworkManager itself was not found in this inventory |
| `plasma-pa` | Audio UI | Later desktop integration | none found | missing | Depends on chosen audio stack |
| `bluedevil` | Bluetooth UI | Later desktop integration | none found | missing | BlueZ substrate exists |

## First Package Tranches

### Tranche 0: Graphics Gate

Required before KDE packaging work is meaningful:

- rebuild `mesa` with `iris` and `radeonsi`
- verify `mesa-dri-drivers` owns the expected DRI files
- validate renderer on Intel and AMD hardware

### Tranche 1: First Packaging Tranche

The first packaging tranche is intentionally limited to non-Plasma desktop prerequisites that unblock later KWin and Plasma work without pulling the full shell into scope.

Build/import order:

| Order | Package | Work type | Why now |
|---:|---|---|---|
| 1 | `qtwayland` | new add or import | Critical Qt 6 Wayland client/compositor support for KDE session work |
| 2 | `libdisplay-info` | new add or import | Modern display metadata dependency expected by compositor/display stack components |
| 3 | `xdg-desktop-portal` | new add or import | Base portal service required before KDE portal backend and real desktop integration |
| 4 | `wireplumber` | new add or import | PipeWire session manager for the modern desktop audio/video baseline |
| 5 | `kde-filesystem` | promotion decision from `SPECS-EXTENDED/` | Filesystem ownership substrate for KDE packages if core KDE specs land in `SPECS/` |
| 6 | `libseat` | conditional new add | Keep deferred unless KWin bring-up or source dependencies prove `systemd-logind` alone is insufficient |

Dependency assumptions:

- `qtwayland` should be attempted first because Azure Linux already carries Qt 6 base components.
- `xdg-desktop-portal-kde` is deferred until the base portal package and more KDE Frameworks are present.
- `wireplumber` should consume the existing `pipewire` package from `SPECS-EXTENDED/` or force an explicit promotion decision if image composition requires it.
- `libseat` and `seatd` are not first-day blockers if the first compositor/session tests can rely on `systemd-logind`.

Deferred from Tranche 1:

- Plasma/KWin packages: `kwin`, `plasma-workspace`, `plasma-desktop`, `sddm`
- KDE portal backend: `xdg-desktop-portal-kde`
- KDE usability layer: `breeze`, `qqc2-desktop-style`, `kscreen`, `powerdevil`, `konsole`, `dolphin`, `systemsettings`
- Full KDE Frameworks expansion beyond packages proven by actual KWin and Plasma Workspace build requirements

### Tranche 2: KDE Framework Expansion

Package the missing framework set required by KWin and Plasma Workspace. The known early set includes:

- `kio`
- `solid`
- `kglobalaccel`
- `kidletime`
- `kwindowsystem`
- `kdbusaddons`
- `kservice`
- `kconfigwidgets`

This list must be generated from actual KWin/Plasma spec dependencies before implementation.

### Tranche 3: Plasma Session Core

Package:

- `plasma-wayland-protocols`
- `kwayland`
- `layer-shell-qt`
- `kdecoration`
- `kwin`
- `plasma-workspace`
- `sddm` or a temporary direct-session launch path

### Tranche 4: Usable Desktop Baseline

Package:

- `plasma-desktop`
- `breeze`
- `qqc2-desktop-style`
- `kscreen`
- `powerdevil`
- `konsole`
- `dolphin`
- `systemsettings`
- portal backend: `xdg-desktop-portal-kde`

## Key Findings

1. Azure Linux already has useful Qt and partial KDE Frameworks substrate.
2. Azure Linux does not currently have the Plasma/KWin/session packages needed to boot a KDE desktop.
3. Several non-KDE desktop prerequisites are also missing, especially portals, `libdisplay-info`, `libseat`, `qtwayland`, and `wireplumber`.
4. `SPECS-EXTENDED/` contains some useful desktop-adjacent packages, but the project needs a policy for what gets promoted to `SPECS/` for the first ProtagonistOS image.
5. Mesa remains the first gate because a successful KDE package import would still be unusable as a bare-metal desktop without hardware rendering.

## Next Work

Open follow-up issues for:

- `qtwayland` package import
- `libdisplay-info` package import
- `xdg-desktop-portal` base package import
- `wireplumber` package import
- KDE Framework dependency expansion from actual KWin/Plasma sources
- first Plasma session package tranche
