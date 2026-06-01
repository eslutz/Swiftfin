# visionOS Documentation

Design and process docs for the native **Swiftfin visionOS** client. Build/contributor
docs that apply to all platforms live one level up in [`Documentation/`](../).

- [**requirements.md**](requirements.md) — Requirements (R1–R12), non‑functional constraints,
  and testable acceptance criteria. Derived from analyzing PR
  [#1](https://github.com/eslutz/Swiftfin/pull/1) and re‑scoping to Swiftfin's shared‑first
  architecture, the visionOS HIG, and native visionOS APIs.
- [**cross-platform-validation.md**](cross-platform-validation.md) — Living register of every
  shared‑layer change, classified by blast radius, with the iOS/iPadOS + tvOS checks each
  requires. Keeps the existing apps from regressing (Requirement N1).
- [**xcode-target-setup.md**](xcode-target-setup.md) — Exact wiring to create the net‑new
  `Swiftfin visionOS` Xcode target (mirror the tvOS target), the SPM products to link, build
  settings, the `Shared/` incompatibility‑resolution strategy, and the binary assets to author.

## Architecture in one line

The visionOS target compiles `Shared/` + a dedicated `Swiftfin visionOS/` view layer (it does
**not** compile the iOS `Swiftfin/` tree). Shared view models/services/coordinators/player state
are reused as‑is; shared views gain `#if os(visionOS)` seams only where differences are minor;
screens that materially differ are forked into `Swiftfin visionOS/Views/`. No visionOS
conditionals are added to the iOS tree, so iOS/tvOS stay byte‑identical.
