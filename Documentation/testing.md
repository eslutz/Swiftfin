# Testing

## visionOS Unit Tests

Swiftfin includes unit tests for platform-specific behavior added by the visionOS target. These tests are intentionally narrow: they cover small pieces of shared logic that can regress as platform conditionals, defaults, and paging behavior evolve.

The visionOS unit tests verify that:

- visionOS reports the expected platform and device helpers;
- visionOS exposes only the native video player;
- the visionOS video player default is native;
- shared paging logic avoids duplicate next-page requests and clears stale loading state on refresh.

These tests do not cover UI flows, simulator launch behavior, real Jellyfin networking, CoreStore integration, or playback rendering. Those areas need deterministic harnesses before they can produce reliable automated coverage.

Run all visionOS tests from the repository root:

```bash
xcodebuild test \
  -project Swiftfin.xcodeproj \
  -scheme "Swiftfin visionOS" \
  -destination 'platform=visionOS Simulator,name=Apple Vision Pro'
```

If the local visionOS simulator name differs, or multiple simulators have the same name, discover available destinations first:

```bash
xcodebuild -showdestinations \
  -project Swiftfin.xcodeproj \
  -scheme "Swiftfin visionOS"
```

When multiple destinations match, use the discovered simulator `id` instead of the name:

```bash
xcodebuild test \
  -project Swiftfin.xcodeproj \
  -scheme "Swiftfin visionOS" \
  -destination 'platform=visionOS Simulator,id=<device-id>'
```

If command-line testing stops on package macro validation for existing dependencies, rerun the same command with `-skipMacroValidation`.

The same tests can also be run from Xcode by selecting the `Swiftfin visionOS` scheme and a visionOS simulator, then using Product > Test.
