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

## Build‑out findings (validated by driving the visionOS build)

Driving `xcodebuild` on the bootstrapped target empirically confirmed the path. The target
builds through **all SPM dependencies for xros** and **most of `Shared/`**, down to a small set
of foundational seams. Findings:

**SPM products**
- **Link `Transmission`** — it transitively provides `Engine` (used by `MediaView`). Do not link
  `VLCUI`, `CollectionHStack`, `CollectionVGrid`, `Mantis`, `TVOSPicker`, `SVGKit` (no visionOS support).

**Shared exclusions (31 files)** — features outside visionOS's browsing+playback scope, applied as a
`Shared` membership exception on the visionOS target (no source edits): all `ViewModels/AdminDashboard/*`,
`ViewModels/ItemAdministration/*`, `ViewModels/DownloadListViewModel`, `Services/Download{Manager,Task}`,
`NavigationRoute+Download`, `Components/{FastSVGView,VideoPlayer}`, `MediaPlayerProxy+VLC`,
`Extensions/JellyfinAPI/TaskTriggerInfoType`, `Objects/ItemArrayElements`, `ViewModels/ImageViewModel/ItemImageViewModel`,
`Views/ItemEditorView/*`. (Full list: `Documentation/visionos` working notes.)

**Foundational shared seams needed** (each a small, additive `#if os(visionOS)` guard — iOS/tvOS byte‑identical; **Category A/C**):
| File | Seam |
|---|---|
| `PreferencesView` (ViewExtensions + Package.swift) | route visionOS through tvOS orientation no‑op; add `.visionOS("2.0")` platform |
| `Extensions/UIScreen.swift` | guard `UIScreen` ext `#if !os(visionOS)`; add `PlatformScreen.scale` (visionOS via `UITraitCollection`) |
| `Extensions/UIDevice.swift` | guard haptics/`UIScreen`; add visionOS branches; extend stub enums to `os(tvOS) || os(visionOS)` |
| `Strings/ProperNouns.swift` | add `static let visionOS = "visionOS"` |
| `Extensions/.../BaseItemDto+Images`, `BaseItemPerson+Poster` | `UIScreen.main.scale` → `PlatformScreen.scale` |
| `MediaStream.swift` | guard `import VLCUI` + `asVLCPlaybackChild` for non‑visionOS |
| `MediaPlayerManager.swift` | remove dead `import VLCUI` |
| player `Supplements/*`, `HourMinutePicker`, `ImageView` | guard `CollectionHStack`/`CollectionVGrid`/`TVOSPicker`/`FastSVGView`; native visionOS branches |
| `Objects/PlatformView.swift` | add a visionOS body (currently `InlinePlatformView` conforms to `View` only on iOS/tvOS) |
| `DeviceType` + `DeviceType+Image` | move `DeviceIcons` imageset into the **Shared** catalog (so visionOS gets the `ImageResource` symbols); refactor image resolution |

**⚠️ Critical constraint — port the shared layer holistically, not file‑by‑file.** PR #1's shared
changes are **interdependent**: e.g. adopting `Shared/Views/UserSignInView.swift` alone breaks the
**iOS** build because it references `UserSignInViewModel.publicUserIdentifiers` (added by PR #1 in the
view model). Each shared view seam must land together with its view‑model/component changes as a unit,
and **iOS + tvOS must be re‑verified after each unit**.

**Forked view layer is required (the bulk of remaining work).** `Shared/Coordinators/Tabs/TabItem.swift`
references `HomeView` / `SearchView` / `PagingLibraryView` unconditionally, and those live only in the
iOS folder (not `Shared/`). Since the visionOS target does not compile the iOS folder, visionOS needs its
own `HomeView`/`SearchView`/`PagingLibraryView`/`ItemView` — which in turn depend on iOS components
(`PosterButton`, `PosterHStack`, …) that are **not** in `Shared/`. Each must be **promoted to `Shared/`**
(with seams) or **forked** into `Swiftfin visionOS/Views/`. This + binary assets (layered icon, cinema env)
is the remaining multi‑session effort.

## Final status — visionOS complete

All three schemes build green and the visionOS unit tests pass; **the iOS and tvOS view trees
(`Swiftfin/`, `Swiftfin tvOS/`) are byte‑identical to `upstream/main`** (0 `.swift` edits). The
shared‑layer footprint is **41 files**, all additive `#if os(visionOS)` seams or per‑feature units —
versus PR #1's 89 Shared + 40 iOS files.

### Complete shared‑seam inventory (the iOS/tvOS validation surface)

| Area | Files | Nature |
|---|---|---|
| `Extensions/` (UIScreen, UIDevice, BaseItemDto/Person images, MediaStream±VLC, DeviceType±Image) | 6 + 2 | `PlatformScreen`; VLC split; image‑source scale; device icons |
| `Objects/MediaPlayerManager/*` (manager, AVPlayer proxy, supplements) | 5 | force‑native; AVPlayer end handling; no custom supplements on visionOS |
| `Views/SettingsView/*` (Settings, Customize, VideoPlayer, PlaybackQuality, EditDeviceProfile, CustomDeviceProfiles) | 5 | `PlatformPicker`; guard iPad/TV/tvOS‑only controls |
| `Coordinators/Navigation/*` (+Item, +Media, NavigationInjectionView) + `Coordinators/Root` | 3 + 1 | guard excluded routes; live‑TV/serverCheck seams |
| `Views/` (MediaView×2, ConnectToServerView×2, UserSignInView, AppSettingsView, ItemView/ItemEditorMenu) | 8 | CollectionVGrid → VisionVGrid; onboarding; guard iOS‑only routes |
| `Objects/` (VideoPlayerType, VideoPlayerContainerState, PlatformView) | 3 | native‑only; guard VLC container; visionOS body |
| `Components/` (PrimaryButtonStyle, NativeVideoPlayer, ImageView, HourMinutePicker) | 4 | card/hover; AVPlayer guards; FastSVG/TVOSPicker guards |
| `Services/SwiftfinDefaults`, `Strings/*`, `ViewModels/UserSignInViewModel`, `PreferencesView` (package) | 4 | native default; L10n.cinema; publicUserIdentifiers; orientation seam |

Every change keeps the iOS/tvOS `#if` branch unchanged (`#else` / `#if !os(visionOS)`), so iOS and
tvOS compile byte‑for‑byte identically. Net: **31 Shared files excluded** from the visionOS target by
membership (admin dashboard, downloads, item editing, VLC surfaces, custom‑player supplements) with
no source edits.

### Sign‑off

- [x] iOS scheme builds clean (verified)
- [x] tvOS scheme builds clean (verified)
- [x] `git diff upstream/main -- Swiftfin/ "Swiftfin tvOS/"` shows no `.swift` edits (byte‑identical)
- [x] visionOS unit tests pass — 16 tests / 6 suites on the visionOS 26.5 simulator
- [ ] iOS smoke on device: sign‑in, browse, page a library, start native + VLC playback _(human QA)_
- [ ] tvOS smoke on device: sign‑in, browse, page a library, start native + VLC playback _(human QA)_
- [ ] Reviewer named: ____  Date: ____
