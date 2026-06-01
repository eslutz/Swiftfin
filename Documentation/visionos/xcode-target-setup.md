# visionOS — Xcode Target & Asset Setup

> The `Swiftfin visionOS` target is net‑new (it does not exist on `upstream/main`). This guide
> captures the exact wiring so the target can be created reliably in Xcode (the project uses
> Xcode 16+ **file‑system synchronized groups**, so most source membership is automatic by folder).
> The **tvOS target is the structural template** — visionOS mirrors it, swapping the platform.

## 1. Create the app target

**Automated path (validated):** run the bootstrap script — it creates the target by mirroring
the tvOS target with the correct synchronized groups (Shared + `Swiftfin visionOS`, **not** the
iOS folder), build settings, and SPM products:

```bash
gem install xcodeproj          # once
ruby Documentation/visionos/bootstrap-target.rb Swiftfin.xcodeproj
```

It rewrites `project.pbxproj` in xcodeproj's formatting; let Xcode re-normalize on next save if
desired. Then add a shared scheme (§7) and proceed to §4. The manual equivalent follows.

**Manual path** — in Xcode: **File ▸ New ▸ Target… ▸ visionOS ▸ App**.
- Product Name: `Swiftfin visionOS`  →  folder `Swiftfin visionOS/`
- Interface: SwiftUI, Language: Swift, no tests from the wizard (add the test target separately).
- Minimum Deployments: **visionOS 2.0** (matches `Documentation/version.md`).

Then align it to the house layout (compare against the `Swiftfin tvOS` target):

- **`fileSystemSynchronizedGroups`** = `Shared`, `Swiftfin visionOS`, `Translations`, `XcodeConfig`.
  **Do not** add the iOS `Swiftfin` group (this is the key divergence from PR #1, which compiled
  the iOS view tree into visionOS and caused the broad blast radius).
- Add a synchronized‑group **membership exception** so `Swiftfin visionOS/Resources/Info.plist`
  is treated as the target's Info.plist (mirror the tvOS `Resources/Info.plist` exception).
- Reproduce the tvOS build phases in order: `Alphabetize Strings`, `Run Swiftgen.swift`,
  `Run SwiftFormat`, `Run SwiftLint`, then `Sources`, `Frameworks`, `Resources`.

## 2. Build settings

- `SDKROOT = xros`, `SUPPORTED_PLATFORMS = "xros xrsimulator"`, `XROS_DEPLOYMENT_TARGET = 2.0`.
- `TARGETED_DEVICE_FAMILY = 7` (Vision).
- `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon-primary-primary` (layered stack, see §5).
- Signing via the gitignored `XcodeConfig/DevelopmentTeam.xcconfig` (per `contributing.md`) —
  **never** commit a `DEVELOPMENT_TEAM`. `PRODUCT_BUNDLE_IDENTIFIER` from the shared xcconfig.
- `INFOPLIST_FILE = "Swiftfin visionOS/Resources/Info.plist"`.

## 3. Swift Package product dependencies

Add the same SPM **products** the iOS target links **except all VLC/UIKit‑only ones**. VLCKit is
unavailable on visionOS (`Cartfile` ships `MobileVLCKit`/`TVVLCKit` only). Link:

`CoreStore, Defaults, Algorithms, Nuke, NukeUI, BlurHashKit, Factory, Files, Pulse,
PulseLogHandler, PulseUI, OrderedCollections, PreferencesView, SwiftUIIntrospect, Engine,
KeychainSwift, IdentifiedCollections, StatefulMacros, JellyfinAPI`

**Do not** link: `VLCUI`, `CollectionHStack`, `CollectionVGrid`, `Mantis`, `TVOSPicker`,
`LNPopupUI`/`LNPopupController` (UIKit/platform‑specific; visionOS uses native `ScrollView`+`Lazy*`
via `VisionHorizontalScroll`/`VisionVGrid`).

## 4. Resolve `Shared/` visionOS‑incompatibility (the real work)

Synchronized groups compile **all** of `Shared/`, so every Shared file must compile on visionOS
or be excepted from the visionOS target. The incompatible set is small (9 files import the
excluded packages). For each, choose the lowest‑blast‑radius option, and record it in
`cross-platform-validation.md`:

1. **VLC‑only** (`MediaPlayerProxy+VLC.swift`, `MediaStream.swift` VLCUI usage) → exclude from the
   visionOS target via a `Shared` membership exception (no source edit).
2. **Shared core needed on visionOS but importing VLC symbols** (`MediaPlayerManager.swift`,
   player `Supplements/*`) → guard the VLC imports/usage (`#if canImport(VLCUI)` / `#if !os(visionOS)`).
3. **Shared views using `CollectionHStack`/`CollectionVGrid`** needed on visionOS
   (`MediaView.swift`, `UserSignInView.swift`, …) → **fork** into `Swiftfin visionOS/Views/` (preferred)
   or add a `#if os(visionOS)` branch using `VisionVGrid`/`VisionHorizontalScroll`.

Iterate: build the visionOS scheme, fix the next incompatibility, repeat. Each shared edit is its
own commit.

## 5. Binary assets to author (cannot be generated headlessly)

- **Layered app icon** — `Swiftfin visionOS/Resources/Assets.xcassets/AppIcon-primary-primary.solidimagestack`
  with `Front`/`Middle`/`Back` `.solidimagestacklayer`s, each a `Content.imageset` PNG, built from the
  Jellyfin "stylized fin" mark. Brand: gradient `#AA5CC3`→`#00A4DC` (Swiftfin's `Color.jellyfinPurple`
  is `#AC5CC3`). Source art: `Resources/AppIcons/*/AppIcon-*-jellyfin.svg`.
- **visionOS device icons** for `DeviceType+Image` (Apple Vision Pro glyph).
- **Jellyfin Cinema environment** — a Reality Composer Pro package (`.usda`/`.rkassets`) under
  `Swiftfin visionOS/` defining the branded media‑room with a `DockingRegion` and Virtual Environment
  Probe (see §6).

## 6. Immersive "Jellyfin Cinema" (R12)

- Add an `ImmersiveSpace(id:)` scene in `SwiftfinApp.swift`; open it from the player; render video
  via the system `AVPlayerViewController` (already docks on visionOS) and, when using a custom
  environment, a RealityKit `DockingRegion` (pattern: Apple's *Destination Video* sample, visionOS 2.0+).
- Brand language: dark media‑room `#000B25`→`#101010`, dim ambient light, faint purple→blue fin motif.
  `.immersionStyle` defaults to `.mixed`/progressive with dimming; user controls immersion.
- **Fallback:** if `openImmersiveSpace` returns an error, stay in the windowed docked player —
  never surface an error. Gate visionOS‑26‑only enhancements behind `if #available`.

## 7. Scheme & CI

- Create a **shared** scheme `Swiftfin visionOS` (mirror the tvOS scheme) under
  `Swiftfin.xcodeproj/xcshareddata/xcschemes/`.
- Add the visionOS build to `.github/workflows/ci.yml` alongside iOS and tvOS (per `contributing.md`:
  iOS, tvOS, **and** visionOS builds must pass).

## 8. Verify

`xcodebuild build -scheme "Swiftfin visionOS" -destination 'platform=visionOS Simulator,id=<sim>'
-derivedDataPath /tmp/swiftfin_dd CODE_SIGNING_ALLOWED=NO`, then run the `Swiftfin visionOS` tests and
the manual Simulator pass in `requirements.md`. Confirm iOS + tvOS remain green (see
`cross-platform-validation.md`).
