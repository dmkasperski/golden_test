---
name: flutter-golden-setup
description: >-
  Set up the golden_test package in a Flutter project for the first time —
  add the dependency, create test/flutter_test_config.dart wired to the
  project's own theme/locale/font/CachedNetworkImage conventions. Use once,
  before writing any goldens. For writing the actual tests afterward, use
  flutter-golden-widget (components) or flutter-golden-route (screens).
---

# Golden Test — Package Setup

One-time setup of the `golden_test` package in a Flutter repo. Run this
**before** `flutter-golden-widget` / `flutter-golden-route` — those assume
`flutter_test_config.dart` already exists and is configured.

## 1. Add the dependency

```bash
dart pub add golden_test --dev
```

## 2. Survey the project before writing config

`flutter_test_config.dart` should mirror the app's *real* conventions, not
generic defaults. Before writing it, check the target repo for:

| Check | Command / look for | Wires into |
|---|---|---|
| Custom fonts | `pubspec.yaml` → `flutter: fonts:` section, or `assets/fonts/` | Font loading block |
| Localization codegen (`flutter gen-l10n`) | `l10n.yaml`, `lib/l10n/`, an `AppLocalizations` class | `goldenTestSupportedLocales`, `goldenTestLocalizationsDelegates` |
| `intl` package used directly (not codegen) | `intl` in `pubspec.yaml` dependencies, `Intl.message(...)` calls | `globalSetup` (see §5) |
| App theme | `ThemeData` construction in `lib/` (often `app_theme.dart`, `theme.dart`, or in the `MaterialApp` widget itself) | `goldenTestThemeInTests` / `goldenTestDarkThemeInTests` |
| `cached_network_image` | `cached_network_image` in `pubspec.yaml` dependencies | CachedNetworkImage opt-in (see §6) — **skip this import entirely if absent**, it will fail to compile |

Don't guess these — grep the actual repo. A wrong locale/theme/font setup produces goldens that don't match the real app.

## 3. Create `test/flutter_test_config.dart`

This exact filename, directly under `test/`, is auto-discovered by
`flutter test` — no wiring needed beyond creating it.

Minimal template — start here, then layer in §4–§6 based on what §2 found:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  return testMain();
}
```

## 4. Wire project conventions

Add whichever of these apply, inside `testExecutable` before `return testMain();`:

```dart
// Fonts — repeat per font family found in pubspec.yaml's `flutter: fonts:`
await (FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf')))
    .load();

// Devices — pick real target form factors, not every preset
goldenTestSupportedDevices = [Device.iphone15Pro(), Device.ipadPro12()];
goldenTestDefaultDevices = [Device.iphone15Pro()]; // used when a test doesn't opt into multi-device

// Locales — from the app's own generated AppLocalizations, not a hardcoded list
goldenTestSupportedLocales = AppLocalizations.supportedLocales;
goldenTestLocalizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

// Theme — reuse the app's real ThemeData, don't hand-roll a copy
goldenTestThemeInTests = AppTheme.light;
goldenTestDarkThemeInTests = AppTheme.dark;
```

`rootBundle` is from `package:flutter/services.dart`; `Device` and the
`goldenTest*` globals are from `package:golden_test/golden_test.dart`
(already imported).

## 5. `intl` package (only if §2 found direct `intl` usage, not codegen)

`intl` hardcodes `Intl.systemLocale` to `en_US`; without this, translated
strings won't render correctly per-locale in tests:

```dart
import 'package:intl/intl.dart';

globalSetup = (locale) async => Intl.defaultLocale = locale.languageCode;
```

## 6. CachedNetworkImage support (only if §2 found `cached_network_image` in the project)

**Skip this section entirely if the project doesn't use `CachedNetworkImage`** — importing it without the underlying dependency present fails to compile.

`CachedNetworkImage` doesn't go through `dart:io`'s `HttpClient` like
`Image.network` does — it fetches through `flutter_cache_manager`, which
needs SQLite and `path_provider`, neither of which work inside Flutter's
fake-async test zone. `golden_test` ships a ready-made fix for this as a
separate opt-in entry point (not part of the main `golden_test.dart`
import), so it adds no dependency to projects that don't use it:

```dart
import 'package:golden_test/cached_network_image.dart';
```

And inside `testExecutable`, before `return testMain();`:

```dart
setupGoldenTestCachedNetworkImage();
```

That's the entire setup — every `CachedNetworkImage` in goldens now
resolves to the same stub placeholder, no per-widget changes needed.

## 7. Full example (all sections combined)

```dart
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/cached_network_image.dart'; // omit if project has no CachedNetworkImage
import 'package:golden_test/golden_test.dart';
import 'package:myapp/l10n/app_localizations.dart';
import 'package:myapp/theme/app_theme.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  await (FontLoader('Roboto')
        ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf')))
      .load();

  goldenTestSupportedDevices = [Device.iphone15Pro(), Device.ipadPro12()];
  goldenTestSupportedLocales = AppLocalizations.supportedLocales;
  goldenTestLocalizationsDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  goldenTestThemeInTests = AppTheme.light;
  goldenTestDarkThemeInTests = AppTheme.dark;

  setupGoldenTestCachedNetworkImage(); // omit if project has no CachedNetworkImage

  return testMain();
}
```

## 8. Verify the setup

Write one throwaway golden test to confirm the config loads without error,
generate it, then delete it:

```dart
// test/golden_setup_smoke_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';

void main() {
  goldenTest(
    name: 'setup smoke test',
    builder: (_) => const Scaffold(body: Center(child: Text('ok'))),
  );
}
```

```bash
flutter test test/golden_setup_smoke_test.dart --update-goldens
```

If it passes and produces a PNG under `test/goldens/`, delete the smoke
test and its golden — setup is complete.

## 9. Non-negotiables

- `flutter_test_config.dart` must be named exactly that and live directly under `test/` (or under a nested `test/<dir>/` to scope config to that subtree).
- Never hardcode locale/theme/font values that don't match the real app — pull from the app's own `AppLocalizations`/`ThemeData`/font assets (§2).
- Don't add the CachedNetworkImage import unless the project actually depends on `cached_network_image` — it won't compile otherwise.
- After setup, hand off to `flutter-golden-widget` (components) or `flutter-golden-route` (screens) to write actual tests.
