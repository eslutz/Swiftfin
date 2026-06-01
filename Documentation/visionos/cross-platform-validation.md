# visionOS — Cross‑Platform Validation Register

> Purpose: enumerate every change made **outside** the visionOS‑only target while building
> the visionOS client, classified by blast radius, with the exact iOS/iPadOS + tvOS checks
> each requires. This is the document referenced by Requirement **N1** and is the contract
> that keeps the iOS and tvOS apps from regressing.
>
> Status: **living** — append a row when a shared‑layer change lands; check it off after the
> iOS + tvOS validation passes. Per the commit strategy, every shared change is its own commit
> so each row maps 1:1 to a commit hash.

## How to read this

- **A — Shared logic / behavior**: changes to shared view models, services, or player state
  that *run* on iOS/tvOS. Highest risk → require functional smoke tests on both.
- **B — Promotions (iOS→Shared)**: an iOS file moved into `Shared/`. iOS now compiles it from
  a new location → confirm identical behavior; tvOS unaffected unless newly included.
- **C — Shared‑view seams (`#if os(visionOS)` added)**: a new visionOS branch added beside
  existing `#if os(iOS)`/`#if os(tvOS)` branches in a `Shared/Views/*` file. iOS/tvOS branches
  are byte‑identical → low risk, but enumerated for auditability.
- **D — Project / target membership / resources**: `project.pbxproj` target & scheme additions,
  visionOS target membership exclusions, and shared asset‑catalog additions. Verify iOS/tvOS
  still build, sign, and show no asset regressions.

## Validation commands (run for every Category A/B/D change)

```bash
DD=/tmp/swiftfin_dd
xcodebuild build -project Swiftfin.xcodeproj -scheme "Swiftfin"      -destination 'generic/platform=iOS Simulator'   -derivedDataPath "$DD" CODE_SIGNING_ALLOWED=NO
xcodebuild build -project Swiftfin.xcodeproj -scheme "Swiftfin tvOS" -destination 'generic/platform=tvOS Simulator'  -derivedDataPath "$DD" CODE_SIGNING_ALLOWED=NO
# Byte-identical guard for iOS view tree (should print nothing):
git diff --stat upstream/main -- Swiftfin/
```

---

## Anticipated shared‑layer changes (planned inventory)

These are the shared touchpoints the visionOS architecture is expected to require. Quantified
from the codebase: only **9 Shared files** import visionOS‑incompatible packages
(`CollectionHStack`, `CollectionVGrid`, `VLCUI`, `Mantis`), versus PR #1's 89‑file churn.

| # | Change | Category | Files (representative) | iOS/tvOS validation | Status |
|---|--------|----------|------------------------|---------------------|--------|
| 1 | Exclude VLC‑only player surfaces from the visionOS target (membership exception — **no source edit**) | D | `Shared/Objects/MediaPlayerManager/MediaPlayerProxy/MediaPlayerProxy+VLC.swift`, `Shared/Extensions/JellyfinAPI/MediaStream.swift` | iOS/tvOS still compile these (unchanged); confirm playback unaffected | ☐ |
| 2 | Guard the shared player core where it imports VLC‑only symbols, so it compiles on visionOS without VLCKit | A | `Shared/Objects/MediaPlayerManager/MediaPlayerManager.swift`, `…/Supplements/*` | iOS/tvOS playback start/stop, chapters, queue still work | ☐ |
| 3 | Force `VideoPlayerType.native` on visionOS + hide player‑picker / VLC‑only rows via `#if os(visionOS)` seams | A/C | `Shared/Objects/VideoPlayerType/*`, `Shared/Views/SettingsView/{VideoPlayerSettingsView,PlaybackQualitySettingsView}.swift` | iOS/tvOS settings show the player picker & VLC rows unchanged | ☐ |
| 4 | Shared paging de‑duplication fix (no duplicate next‑page; no stuck loading) — **R9** | A | shared paging/library view models (e.g. `PagingLibraryViewModel`) | iOS + tvOS library/search paging loads correctly, no double‑fetch | ☐ |
| 5 | Shared views that use `CollectionHStack`/`CollectionVGrid` and are needed on visionOS — **fork** into the visionOS view layer rather than editing the shared file (preferred), or add a `#if os(visionOS)` seam if the difference is minor | C | `Shared/Views/MediaView/MediaView.swift`, `Shared/Views/UserSignInView.swift` | iOS/tvOS branches untouched → smoke MediaView & sign‑in on both | ☐ |
| 6 | visionOS device icons for the active‑device UI | D | `Shared/Extensions/JellyfinAPI/DeviceType+Image.swift`, `Shared/Resources/Assets.xcassets/*` | iOS/tvOS device icons unchanged; no asset‑catalog regressions | ☐ |
| 7 | Add `Swiftfin visionOS` target + shared scheme; visionOS membership for `Shared`, `Translations`, `XcodeConfig` | D | `Swiftfin.xcodeproj/project.pbxproj`, `…/xcshareddata/xcschemes/Swiftfin visionOS.xcscheme` | iOS + tvOS schemes still build & sign; no scheme drift | ☐ |
| 8 | Any view **promoted** from `Swiftfin/` (iOS) into `Shared/` because visionOS needs it and it is platform‑neutral | B | _record each move here_ | iOS compiles from new path, behavior identical | ☐ |

> Note on look‑to‑scroll: implemented as a **visionOS‑only** file in the visionOS target
> (`scrollInputBehavior(.enabled, for: .look)`, gated `if #available(visionOS 26.0, *)`), so it
> is **not** a shared change (unlike PR #1, which placed it in `Shared/`).

## Sign‑off

- [ ] iOS scheme builds clean
- [ ] tvOS scheme builds clean
- [ ] `git diff --stat upstream/main -- Swiftfin/` shows no behavioral iOS view edits
- [ ] iOS smoke: sign‑in, browse, page a library, start native + VLC playback
- [ ] tvOS smoke: sign‑in, browse, page a library, start native + VLC playback
- [ ] Reviewer named: ____  Date: ____
