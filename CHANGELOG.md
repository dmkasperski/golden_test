## 2.0.1

### Fixes
- **Goldens no longer fail when the widget under test builds its own app** — the screenshot was taken of `find.byType(MaterialApp)`, which matched both the harness's app and the one under test. The test failed with `matched too many widgets` and no golden was written, including under `--update-goldens`. Server-driven UI, storybook-style harnesses and nested navigators all hit this. The snapshot is now anchored to a private root widget, so it resolves to a single widget whatever the builder returns. Existing goldens are byte-identical and do not need regenerating.

## 2.0.0

### Breaking changes
- **Migrated to `material_ui`** — Flutter 3.47 decoupled Material (and Cupertino) from the core SDK into standalone `material_ui`/`cupertino_ui` packages on pub.dev, deprecating `package:flutter/material.dart`. `golden_test` now imports `package:material_ui/material_ui.dart` instead, and the minimum supported Flutter version is now `3.47.0` (Dart SDK `>=3.13.0`). Projects on older Flutter versions will need to stay on `golden_test` 1.x.
- **Framework localization delegates are now built in** — `GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations` and `GlobalCupertinoLocalizations` are appended automatically, so `goldenTestLocalizationsDelegates` only needs your own app's delegates. Remove the framework ones from your config; you no longer need to import them, or to depend on `flutter_localizations`/`cupertino_ui` just for tests. This also sidesteps the `ambiguous_import` that otherwise occurs because `flutter_localizations` still exports deprecated copies of the Material and Cupertino delegates that `material_ui`/`cupertino_ui` now own. Delegates you supply are resolved before the built-in ones, so overriding still works.
- **Network images are stubbed by default** — `goldenTestStubNetworkImages` defaults to `true`, so any `NetworkImage` now resolves to a placeholder instead of failing to load. Goldens that contain network images will change: they previously captured a blank or error state and now show the placeholder, so they need regenerating. If you already stub network images yourself, note that golden_test installs its stub *before* the test body: a `debugNetworkImageHttpClientProvider` or `HttpOverrides` set in `flutter_test_config.dart` is superseded — set `goldenTestStubNetworkImages = false` to keep your own. Stubs installed inside `globalSetup` or a test's `setup` still win, since those run after, and are unaffected.

### New features
- **AI agent skills** — the package now ships three [Agent Skills](https://dart.dev/ai/package-skills) under `skills/`, installable with `dart run skills@ get`: `golden_test-setup` (wiring `flutter_test_config.dart` to your app's themes, locales and fonts), `golden_test-widget` (component goldens) and `golden_test-route` (screen goldens). They cover which test axes are worth their cost, deriving edge cases from branches in your own formatting code, and reading a failing golden — see [README § AI Agent Skills](README.md#ai-agent-skills).
- **Built-in network image stub** — golden tests no longer time out or produce flaky output when the widget tree loads images from the network. Any `NetworkImage` is resolved from a placeholder out of the box, no setup required, wherever it appears — `Image.network`, `FadeInImage`, a `DecorationImage` in a `BoxDecoration`, or a custom widget. Other `dart:io` HTTP traffic is left alone, so a repository call fired from the widget tree still behaves as it did. Opt out with `goldenTestStubNetworkImages = false`, or replace the placeholder via `goldenTestNetworkImageStubPng`.
- **Image loader hook** — `goldenTestImageLoaderSetups` lets any package register a per-test image-loading stub, for loaders that don't go through `NetworkImage`. It's a list, so several packages can register without clobbering one another. `CachedNetworkImage` is supported this way by the companion [`golden_test_cached_network_image`](https://pub.dev/packages/golden_test_cached_network_image) package, which keeps `cached_network_image` and `flutter_cache_manager` out of the dependency graph of projects that don't use them — see [README § CachedNetworkImage support](README.md#cachednetworkimage-support).

### Fixes
- **`Device.copyWith` no longer drops `name`** — omitting `name` reset it to `null`, which made the golden path fall back to `default` and caused distinct devices in one `supportedDevices` list to share a single golden file.

## 1.1.1

### Fixes
- **Bundled Roboto font** — The package now ships its own Roboto font, so the device frame's status bar time renders correctly in any consuming project regardless of whether it bundles Roboto itself.

## 1.1.0

### Fixes
- **Async hooks now awaited** — `globalSetup`, `setup`, and `tearDown` callbacks are now properly awaited inside `goldenTest`, preventing race conditions with font loading, `Intl.defaultLocale`, and mock wiring.

### Improvements
- **Typed `tags` parameter** — `goldenTest`'s `tags` parameter is now `Object?` (matching Flutter's own `testWidgets` signature) instead of `dynamic`, with dartdoc clarifying the accepted shapes (`String`, `Tag`, `Iterable`).

### New features
- **Text-scale matrix** — `supportedTextScales` and `goldenTestSupportedTextScales` add text scale as a test axis. Optional [AndroidFontScale] / [IosDynamicTypeScale] enums and accessibility preset lists are available.

## 1.0.1

- Fixed README images not rendering on pub.dev by using absolute URLs.

## 1.0.0

First stable release under [semantic versioning](https://semver.org/); the public API is now versioned with breaking changes reserved for major bumps.

### Breaking changes
- **Golden frame** — Redesigned the status bar and bottom bar UI rendered around the widget under test. All existing golden screenshots will need to be regenerated (`flutter test --update-goldens`).

### Improvements
- **Example app** — Expanded and clearer examples demonstrating real usage patterns.
- **Documentation** — Reworked and expanded docs so setup and options are easier to follow.

## 0.1.7
1. Added `tags` parameter to properly proxy it to `testWidgets`

## 0.1.6
1. **New Feature**: Added `subdirectory` parameter to `goldenTest` for organizing golden files into custom subdirectories
   - Allows per-test configuration of golden file organization
   - Useful for managing multiple apps with different design tokens
   - Supports nested subdirectories (e.g., `'design_system/v2'`)
   - Path structure: `goldens/[subdirectory]/locale/theme/[device]/name.png`

## 0.1.5
1. Refactor device configuration system to support three distinct configuration levels:
   - **New**: Added `goldenTestDefaultDevices` for setting global default device(s)
   - **Improved**: `goldenTestSupportedDevices` now exclusively for multi-device testing
   - **Changed**: `supportedDevices` parameter is now nullable, enabling proper configuration hierarchy
   - **Enhanced**: Device selection logic now follows clear priority: per-test override > multi-device mode > global default
   - **Fixed**: Golden file paths now intelligently include device names only when testing multiple devices 
   
    This change makes device configuration more intuitive and eliminates the need to pass `supportMultipleDevices: true` just to use a globally-defined single device.
2. Improved formatting
3. Updated dependencies
4. Updated example project
5. Updated documentation
6. Drop deprecated .withOpacity

## 0.1.4
Fix directory for generating failure screenshots.

## 0.1.3
Add option to precache assets.

## 0.1.2
Add option to set difference tolerance at which tests are considered failing.

## 0.1.1
Add read.me to example project.

## 0.1.0

Initial release of goldenTest method which helps writing Golden Tests very easily by pumping Flutter Widgets.

Features:
1. `goldenTest` - utility method for generating screenshots
2. Supporting multiple locales.
3. Supporting multiple localizations.
4. Supporting light and dark mode.
