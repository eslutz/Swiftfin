# Swiftfin visionOS — Requirements & Acceptance Criteria

> Status: living document. Derived by analyzing the prior visionOS proof‑of‑concept
> (PR [#1](https://github.com/eslutz/Swiftfin/pull/1) "Native Apple Vision Pro Support",
> branch `codex-visionos-support`) and re‑scoping it to Swiftfin's shared‑first
> architecture, the [visionOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/designing-for-visionos),
> and the [visionOS API set](https://developer.apple.com/documentation/visionos).
> PR #1 is treated as the **functional bar** and its tests as **behavioral acceptance coverage**;
> its implementation is reference material, not the architecture.

## Purpose

Add a first‑class, native **Apple Vision Pro** client to Swiftfin that reaches feature
parity with the iOS/iPadOS browsing and playback experience, feels native to visionOS,
and is built without destabilizing the existing iOS/iPadOS and tvOS apps.

## Scope

**In scope**
- A dedicated `Swiftfin visionOS` app target reusing the shared backend, view models,
  services, coordinators, and player state.
- Native visionOS presentation for the screens that materially differ from iPad.
- Native (AVPlayer/AVKit) playback, including visionOS system docking.
- A branded RealityKit **immersive "Jellyfin Cinema"** environment for playback
  (enhancement over PR #1), layered on top of the reliable windowed player.

**Out of scope (initial release)**
- Volumetric (3D) windows.
- Multi‑window / multi‑scene browsing.
- VLCKit (Swiftfin player) playback — not available on visionOS (see R6).

## Definitions

- **Shared‑first hybrid** — reuse `Shared/` view models/services/coordinators and
  platform‑neutral views; add `#if os(visionOS)` seams to shared views where small
  differences exist; fork only the screens that materially differ into
  `Swiftfin visionOS/Views/`. No visionOS conditionals are added to the iOS `Swiftfin/` tree.
- **Byte‑identical** — the compiled iOS and tvOS products are unchanged; their existing
  `#if` branches are never edited.

---

## Functional requirements

### R1 — App target & CI
A dedicated `Swiftfin visionOS` application target and shared scheme exist, build against
the **visionOS 2.0** SDK, and are added to the required CI build matrix alongside iOS and tvOS.

### R2 — App shell & lifecycle
A single‑window SwiftUI `App` entry presents the shared `RootView`. Scene‑phase
background/foreground handling honors `signOutOnBackground` / `backgroundSignOutInterval`.
A sensible `defaultSize` is provided for the main window.

### R3 — Onboarding & accounts
The shared server/auth/user flows work on visionOS: connect to server, edit server,
user sign‑in, Quick Connect, select/switch user, and sign‑out. Switching users does not crash.

### R4 — Navigation
The root uses an adaptive tab/sidebar (`TabView` with `.sidebarAdaptable`) exposing the
primary destinations (Home, Search, Library/Media, Settings). Per‑screen controls
(filters, options, search) use visionOS‑native chrome (toolbars/ornaments).

### R5 — Browsing
Home (e.g., continue‑watching, latest, genres), library paging grids, search, and item
detail are fully functional. Horizontal rails and grids use native scrolling, page
additional results correctly, and present poster/now‑playing art.

### R6 — Playback (native only)
Playback uses **Native (AVPlayer)** exclusively. The visionOS target does **not** link
VLCKit and does **not** compile VLC/VLCUI player surfaces (technical constraint: VLCKit
ships `MobileVLCKit`/`TVVLCKit` only — no visionOS binary). The player‑type selector and
VLC‑only settings are hidden on visionOS, with the effective player forced to native.

### R7 — Native visionOS affordances
The app favors platform APIs over custom code: native `searchable`, native `ColorPicker`
for the accent‑color setting, look‑to‑scroll, hover/focus highlighting on interactive
elements, and system glass surfaces.

### R8 — Resources
The target ships a layered (`solidimagestack`) app icon featuring the Jellyfin logo, an
Optic ID usage description (`NSFaceIDUsageDescription`), and visionOS device icons.

### R9 — Paging correctness (shared)
Library/search paging does not issue duplicate next‑page requests and does not get stuck
in a loading state. This fix lives in shared view models and therefore applies to all platforms.

### R10 — Test coverage
Unit tests cover, at minimum: platform helpers, the native‑player default on visionOS,
and paging request behavior (no duplicate page loads). New visionOS‑specific behaviors
(forced‑native selection, immersive open/dismiss + fallback) are covered.

### R11 — Documentation
`Documentation/contributing.md`, `players.md`, and `version.md` are updated to reflect
visionOS support (native‑only playback rationale, immersive cinema, CI inclusion, min OS).

### R12 — Branded immersive cinema (enhancement)
A custom RealityKit `ImmersiveSpace` presents a subtle, Jellyfin‑branded cinema/media‑room
for playback using native docking APIs. It is isolated entirely in visionOS‑only code and
never replaces the reliable windowed player — it is an opt‑in enhancement with a clean fallback.

---

## Non‑functional requirements

- **N1 Blast radius** — iOS and tvOS products remain byte‑identical. No `#if os(visionOS)`
  branches are added to the iOS `Swiftfin/` tree. Every shared‑layer change is justified and
  recorded in `cross-platform-validation.md`.
- **N2 House style** — follow the existing shared‑first pattern (shared views with platform
  seams; per‑platform folders for screens that fully differ). Use `// MARK:` organization.
- **N3 Quality gates** — SwiftFormat and SwiftLint pass; all three schemes build; new
  non‑experimental strings are localized.
- **N4 HIG & comfort** — respect visionOS comfort guidance (no forced rapid motion; user
  controls immersion; legible content at distance; ≥60pt targets with adequate spacing).
- **N5 Min OS** — visionOS 2.0. visionOS‑26‑only enhancements are gated behind `if #available`.

---

## Acceptance criteria

Each criterion is testable via build, unit test, or a visionOS Simulator pass.

**Build & integrity**
- AC‑1: `Swiftfin visionOS` scheme builds warning‑clean against visionOS 2.0.
- AC‑2: `Swiftfin` (iOS) and `Swiftfin tvOS` schemes build, and `git diff upstream/main -- Swiftfin/`
  shows no behavioral edits to iOS view files (only Shared/promotions/visionOS appear).
- AC‑3: No VLCKit symbols are linked into the visionOS product; `MediaPlayerProxy+VLC`
  and VLC/VLCUI controls are not members of the visionOS target.

**Functional (Simulator)**
- AC‑4: Launch presents `RootView`; sign‑in and Quick Connect succeed; switching users does not crash.
- AC‑5: All primary destinations are reachable via the adaptive tab/sidebar.
- AC‑6: Home, library grids, and search load, hover‑highlight interactive items, and page
  additional results without duplicate requests or stuck spinners.
- AC‑7: Item detail presents and can start playback.
- AC‑8: Playback opens in `AVPlayerViewController`; the player‑type selector and VLC‑only
  settings are absent; the accent color can be changed via the native `ColorPicker`.
- AC‑9: Backgrounding past the configured interval signs out when `signOutOnBackground` is enabled.

**Immersive cinema**
- AC‑10: From playback, the Jellyfin Cinema immersive space opens, docks the video, applies
  the Jellyfin palette, and dismisses cleanly returning to the window.
- AC‑11: If the immersive space cannot open, playback continues in the windowed docked player
  with no error surfaced to the user (graceful fallback).

**Quality**
- AC‑12: SwiftFormat (`--lint`) and SwiftLint report no violations.
- AC‑13: visionOS unit tests pass on the Simulator (≥ PR #1's coverage plus the new cases in R10).
- AC‑14: New user‑facing strings are present in `en` and flow through localization.

---

## Traceability to PR #1

| PR #1 capability | Requirement |
|---|---|
| visionOS target, scheme, resources, app entry | R1, R2, R8 |
| Reuse shared browsing/settings flows | R3, R5, N2 |
| visionOS nav / toolbar / `.sidebarAdaptable` tab/sidebar | R4 |
| Native AVKit player; hide VLC‑only settings | R6 |
| Native `searchable`, `ColorPicker`, look‑to‑scroll, glass, hover | R7 |
| Layered app icon, Optic ID, device icons | R8 |
| Shared paging de‑duplication fix | R9 |
| visionOS unit tests (platform helpers, player defaults, paging) | R10 |
| Docs updates | R11 |
| (New) immersive playback environment | R12 |
| Immersive/volumetric/multi‑window deferred | Scope → Out of scope (cinema now in via R12) |
