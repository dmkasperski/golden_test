---
name: golden_test-setup
description: >-
  Set up the golden_test package in a Flutter project for the first time —
  add the dependency, create test/flutter_test_config.dart wired to the
  project's own theme/locale/font conventions. Use once,
  before writing any goldens. For writing the actual tests afterward, use
  golden_test-widget (components) or golden_test-route (screens).
---

# Golden Test — Package Setup

One-time setup of `golden_test` in a Flutter repo. Run **before**
`golden_test-widget` / `golden_test-route` — those assume
`flutter_test_config.dart` exists and is configured.

## 1. Add the dependency

```bash
dart pub add golden_test --dev
```

Use whatever SDK wrapper the project pins with — `fvm dart pub add …` if
there's an `.fvmrc`, `melos`/`mise`/`asdf` equivalents otherwise. A bare
`dart`/`flutter` on a pinned project resolves against the wrong SDK.

`golden_test` 2.x needs Flutter `>=3.47.0` — 3.47 moved Material and
Cupertino out of the SDK into standalone `material_ui` / `cupertino_ui`
packages and the package migrated with it. On older Flutter, pin
`golden_test` 1.x or upgrade first; don't discover the mismatch
mid-`pub get`.

**Check which major version actually resolved** before following anything
below — `pubspec.lock`, not the constraint. The two behave differently in
ways these skills depend on:

| | 1.x | 2.x |
|---|---|---|
| Material import | `package:flutter/material.dart` | `package:material_ui/material_ui.dart` |
| Framework localization delegates | list them yourself (§4) | appended automatically |
| Network image stubbing | none — stub it yourself | built in (§6) |
| `Device.copyWith` without `name` | drops the name | keeps it |

If `golden_test` is already in `pubspec.yaml`, skip `pub add` and work from
the version that's there.

**2.x requires the app itself to be on `material_ui` — you cannot mix.**
`material_ui`'s `ThemeData` is a different class from
`package:flutter/material.dart`'s, so `goldenTestThemeInTests = appTheme`
simply won't compile while `lib/` still imports `flutter/material`, on any
Flutter version. Check before you start:

```bash
grep -rl 'package:flutter/material.dart' lib | wc -l
```

If that's non-zero, the project has a decision to make, and it isn't yours
to make silently:

- **Migrate** — the app's own files are a mechanical one-line-per-file import
  swap (`package:flutter/material.dart` → `package:material_ui/material_ui.dart`),
  and compile errors surface where the theme crosses the boundary:
  `MaterialApp(theme:)`, `Theme(data:)`.

  **Compiling is not the same as working.** Any dependency still on the SDK's
  Material stays on the *other* library, and every point where the two meet is
  a silent cross-library boundary at runtime: a `material_ui` button inside a
  `wolt_modal_sheet` fails `debugCheckHasMaterial` ("No Material widget
  found"), and localizations lookups miss (§4). These are app-wide defects,
  not test problems — a golden is just where you notice them first. Audit the
  dependencies that wrap your widgets in their own Material before calling a
  migration done.
- **Stay on 1.x** — correct if the app isn't ready to migrate. Then follow
  the 1.x column above and ignore §6.

Say which one you're doing and why; don't start rewriting `lib/` imports as
a side effect of setting up tests.

## 2. Survey the project first

`flutter_test_config.dart` must mirror the app's *real* conventions. Grep for
these — don't guess; a wrong locale/theme/font setup produces goldens that
don't match the app:

| Check | Look for | Wires into |
|---|---|---|
| Custom fonts | `pubspec.yaml` → `flutter: fonts:`, or `assets/fonts/` | Font loading block |
| Localization codegen | `l10n.yaml`, `lib/l10n/`, an `AppLocalizations` class | `goldenTestSupportedLocales`, `goldenTestLocalizationsDelegates` |
| `intl` used directly | `intl` in dependencies, `Intl.message(...)` calls | `globalSetup` (§5) |
| App theme | `ThemeData` construction in `lib/` — often `app_theme.dart`, `theme.dart`, or inline in `MaterialApp` | `goldenTestThemeInTests` / `goldenTestDarkThemeInTests` |
| Image loading packages | `cached_network_image` or similar | `goldenTestImageLoaderSetups` (§6) |
| Timezone database | `timezone` in dependencies, `getLocation(...)`/`tz.` calls | `initializeTimeZones()` (§5) |
| Non-English date formatting | `DateFormat` used with a non-`en` locale | `initializeDateFormatting` (§5) |
| An RTL locale | `ar`, `he`, `fa`, `ur` … in the supported locales | whether RTL goldens are worth writing at all |
| Icon fonts | `Icon(...)` / `Icons.` anywhere in `lib/` | Icon font loading (§4) |
| **Existing test hooks** | `FLUTTER_TEST` in `lib/`, a `TestsManager`-style flag, fake ad/map/image widgets | what your goldens will actually show — see below |

Every row resolves from what you find — wire it in without asking. The one
exception is **which theme is the default** when the survey turns up several
(white-label, multi-tenant, seasonal palettes) with no obviously-primary
one. That's a product call, not a discoverable fact: say what you found
("this app has 3 themes: A, B, C") and ask once, rather than turning the
whole survey interactive. If there's no answer or setup must run unattended,
pick the one that looks primary (first-listed, most complete asset coverage)
and say so plainly instead of blocking.

**If the app ships an RTL locale, set it up as a locale worth testing.**
Goldens are unusually good value here: RTL bugs are common — a hardcoded
`EdgeInsets.only(left:)`, a `Row` that reads backwards, a chevron pointing
the wrong way, text that stays left-aligned — and they are close to
invisible to a team that doesn't read the language, so they ship. A
screenshot shows them instantly. Wire the RTL locale into
`goldenTestSupportedLocales` (or leave it out globally and have tests opt in
per golden, which is usually cheaper), and tell whoever writes the tests
that RTL variants are expected rather than optional. If the app ships no RTL
locale, skip it entirely — the widget and route skills both say not to
snapshot a state the product cannot render.

**Test hooks the app already has decide what a golden shows.** A codebase
that swaps a real map, ad or network image for a placeholder under
`FLUTTER_TEST` will render that placeholder in every golden — which is what
makes the suite deterministic, and also means the golden is not a picture of
the app. Find these before writing tests, register whatever flag they read
(§4), and note where a placeholder's size differs from the real widget's, or
you'll "verify" a layout the user never sees.

Don't generate goldens for every brand by default — that multiplies the
golden count fast and most won't get looked at. `references/advanced-setup.md`'s multi-brand
wrapper opts specific ones in.

## 3. Create `test/flutter_test_config.dart`

This exact filename directly under `test/` is auto-discovered by
`flutter test` — no wiring beyond creating it.

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';
import 'package:material_ui/material_ui.dart'; // 1.x: package:flutter/material.dart

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  return testMain();
}
```

The Material import is not optional decoration: `Locale` and `Brightness`
come from there, and `golden_test`'s own exports do not re-export them.
Without it the config fails to compile on the first `goldenTestSupportedLocales`
line.

A config in a nested `test/<dir>/` applies to that subtree — useful for
giving a design-system folder a narrower locale list than the app. It
**replaces** the root config rather than layering on it, so extract shared
wiring into a helper both call (`references/advanced-setup.md` has the pattern).

## 4. Wire project conventions

Inside `testExecutable`, before `return testMain();`:

```dart
// Fonts — repeat per family in pubspec.yaml's `flutter: fonts:`
await (FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf')))
    .load();

// Material icons — NOT loaded in tests. Without this every Icon renders as
// a blank box. Load from the SDK cache rather than bundling a copy, and
// fail open so a missing cache degrades to a fallback glyph instead of
// breaking the suite. reference.md covers third-party icon packages.
final flutterRoot = Platform.environment['FLUTTER_ROOT'];
final iconFont = flutterRoot == null
    ? null
    : File('$flutterRoot/bin/cache/artifacts/material_fonts/'
        'MaterialIcons-Regular.otf');
if (iconFont != null && iconFont.existsSync()) {
  try {
    await (FontLoader('MaterialIcons')..addFont(
          iconFont.readAsBytes().then((b) => ByteData.view(b.buffer)),
        ))
        .load();
  } catch (_) {}
}

// Devices — real target form factors, not every preset.
// Precedence, highest first: a test's own `supportedDevices` >
// `supportMultipleDevices: true` (uses goldenTestSupportedDevices) >
// goldenTestDefaultDevices. A test that passes nothing gets
// goldenTestDefaultDevices only — it does NOT fan out over the supported
// list. The device name appears in the golden path only when more than one
// device is active for that test.
goldenTestSupportedDevices = [Device.iphone15Pro(), Device.ipadPro12()];
goldenTestDefaultDevices = [Device.iphone15Pro()];

// Locales — ONE primary locale, not every supported one. Each extra locale
// multiplies every golden in the repo; a test opts into another itself.
// Pick the product's real primary — l10n.yaml's template-arb-file is the
// strongest hint. The golden path segment is locale.languageCode, so the
// default [Locale('en','US')] silently writes to goldens/en/.
goldenTestSupportedLocales = const [Locale('en')];

// Delegates — YOUR app's only (see below)
goldenTestLocalizationsDelegates = [AppLocalizations.delegate];

// Theme — reuse the app's real ThemeData, don't hand-roll a copy
goldenTestThemeInTests = AppTheme.light;
goldenTestDarkThemeInTests = AppTheme.dark;
goldenTestSupportedThemes = [Brightness.light, Brightness.dark];

// Text scale — leave at the default [1.0] and opt in per test.
// Setting a matrix here multiplies every golden in the repo.
goldenTestSupportedTextScales = const [1.0];
```

**Framework delegates — read this before trusting the one-liner above.**
Flutter 3.47 ships **two** Material libraries, and each has its own
`MaterialLocalizations` and its own `GlobalMaterialLocalizations`: one in
`material_ui`, one in `flutter_localizations` (for the SDK's
`package:flutter/material.dart`). `golden_test` appends only `material_ui`'s.

- **Pure `material_ui` app** — the line above is right; `AppLocalizations.delegate`
  alone is enough.
- **Mixed app** — if *any* dependency still imports `package:flutter/material.dart`
  (`wolt_modal_sheet`, `skeletonizer`, and plenty of others do), its widgets
  need the SDK-side delegate too, and you get a runtime
  `No MaterialLocalizations found` the moment one mounts. Supply both: the
  simplest route is your generated `AppLocalizations.localizationsDelegates`,
  which already carries `flutter_localizations`' globals.

Note that `grep -rl 'package:flutter/material.dart' lib` (§1) answers a
*different* question: it tells you whether your own code migrated, not
whether a dependency is still on SDK Material. An app can be 100% pure in
`lib/` and still be mixed through its packages — and generated
`AppLocalizations` is often SDK-Material itself.

**When in doubt, supply both delegate sets.** It costs nothing and is the
only way to be sure: a duplicate delegate is harmless, a missing one is a
runtime crash in whatever screen you didn't test.

On 1.x none of this appending happens at all: list the delegates yourself.

On 2.x, in a pure `material_ui` app,
`GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations` and
`GlobalCupertinoLocalizations` are added for you — listing them is
unnecessary, and importing `flutter_localizations` to get them causes an
`ambiguous_import` against `material_ui` / `cupertino_ui`. Delegates you
supply resolve first, so overriding still works.

Load every weight the app actually uses, not just the one the `pubspec`
happens to declare. A single-weight family makes the engine synthesize
bold, and any glyph outside that file (an unusual separator or symbol, a
non-Latin script) renders as tofu — in every golden, permanently, until someone
notices.

**When a glyph the app uses isn't in any bundled font**, a real device
silently falls back to a system font and the golden cannot, so the two
disagree forever. Three ways out, in order of preference:

1. **Bundle a font that covers it.** Add the fallback to `pubspec.yaml` and
   load it here. Deterministic, works on CI, closest to what users see.
2. **Change the app** to a character the bundled font has — often the right
   call anyway, since that glyph was already at the mercy of whatever
   fallback each platform happens to provide.
3. **Accept the tofu and write it down**, in the test config next to the
   font loading. This is the normal outcome when you're adding tests to a
   repo where `pubspec.yaml` and `lib/` are someone else's call, not a rare
   last resort — say which glyph, which widgets use it, and which of the two
   fixes above would resolve it, so the note is actionable rather than an
   apology. Re-check it whenever a font is added.

What you must *not* do is load a font from the host machine (a macOS or
Linux system path) to make it look right locally: that breaks §10, and the
goldens then fail on every machine without it.

Text scales accept raw doubles or the packaged `AndroidFontScale` /
`IosDynamicTypeScale` presets (`AndroidFontScale.maximum.value`). Prefer the
presets — they name the real OS setting.

`rootBundle` comes from `package:flutter/services.dart`; `Device`, the
`goldenTest*` globals and the scale enums from
`package:golden_test/golden_test.dart`.

## 5. `intl` (only if §2 found direct usage, not codegen)

`intl` hardcodes `Intl.systemLocale` to `en_US`; without this, translated
strings won't render per-locale:

```dart
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

globalSetup = (locale) async {
  Intl.defaultLocale = locale.languageCode;
  // Required for DateFormat in any non-`en` locale — setting
  // Intl.defaultLocale alone is not enough and throws at format time.
  await initializeDateFormatting(locale.languageCode);
};
```

`globalSetup` takes the `Locale` being rendered and runs **once per golden**,
inside the test — not once per suite. Keep it cheap and idempotent; it is not
the place for one-time wiring, which belongs directly in `testExecutable`.

If the app uses the `timezone` package (a `getLocation('<Region/City>')`
anywhere, usually behind a date helper), initialize the database once in
`testExecutable` — it throws until you do, from deep inside a widget build:

```dart
import 'package:timezone/data/latest.dart' as tz;

tz.initializeTimeZones();
```

## 6. Network images — usually nothing to do

**2.x only.** On 1.x none of the globals in this section exist and nothing
is stubbed: a `NetworkImage` in the widget tree hangs on a request the test
runner never answers. There, install your own
`debugNetworkImageHttpClientProvider` or `HttpOverrides` in `testExecutable`,
or keep image URLs out of goldens. Check `pubspec.lock` (§1) before
following the rest of this section.

`goldenTestStubNetworkImages` defaults to `true`, so anything painting
through a `NetworkImage` — `Image.network`, `FadeInImage`, a
`DecorationImage` — resolves to a checkerboard placeholder instead of
hanging on a request the runner never answers. Other `dart:io` traffic is
untouched.

Two cases need action:

**The project already stubs network images.** golden_test installs its stub
*before* the test body, so a `debugNetworkImageHttpClientProvider` or
`HttpOverrides` set in `flutter_test_config.dart` is superseded. Either
delete the project's own, or keep it and set
`goldenTestStubNetworkImages = false`. (Stubs installed inside `globalSetup`
or a test's `setup:` run later and still win.)

**An image package with its own loader**, which never touches
`NetworkImage`. Register through `goldenTestImageLoaderSetups`. For
`cached_network_image` that's one line:

```dart
import 'package:golden_test_cached_network_image/golden_test_cached_network_image.dart';

setupGoldenTestCachedNetworkImage();
```

For anything else, add a callback. It runs once per test, so construct fresh
instances inside it — that keeps cache state from leaking between tests:

```dart
goldenTestImageLoaderSetups.add(() {
  SomePackage.imageLoader = MyInMemoryLoader();
});
```

Change the placeholder by assigning PNG bytes to
`goldenTestNetworkImageStubPng`.

## 7. Full example

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:myapp/l10n/app_localizations.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  await _loadFonts();
  tz.initializeTimeZones();

  goldenTestSupportedDevices = [Device.iphone15Pro(), Device.ipadPro12()];
  goldenTestSupportedLocales = const [Locale('en')];
  goldenTestLocalizationsDelegates = [AppLocalizations.delegate];
  goldenTestThemeInTests = AppTheme.light;
  goldenTestDarkThemeInTests = AppTheme.dark;

  globalSetup = (locale) async {
    Intl.defaultLocale = locale.languageCode;
    await initializeDateFormatting(locale.languageCode);
  };

  return testMain();
}

Future<void> _loadFonts() async {
  await (FontLoader('Roboto')
        ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf')))
      .load();

  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final icons = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!icons.existsSync()) return;
  try {
    await (FontLoader('MaterialIcons')
          ..addFont(icons.readAsBytes().then((b) => ByteData.view(b.buffer))))
        .load();
  } catch (_) {}
}
```

Note what's absent: no framework delegates, no network-image mocking, no
difference tolerance.

## 8. Verify

```dart
// test/golden_setup_smoke_test.dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';

void main() {
  goldenTest(
    name: 'setup smoke test',
    // Non-ASCII on purpose: 'ok' renders identically in your font and in the
    // fallback, so it cannot tell you whether FontLoader worked. Use
    // characters the app actually uses — accents, a non-Latin script, the
    // separator glyphs in your UI.
    builder: (_) => const Scaffold(
      body: Center(child: Text('ok — zażółć gęślą jaźń 日本語')),
    ),
  );
}
```

```bash
flutter test test/golden_setup_smoke_test.dart --update-goldens
```

A PNG under `test/goldens/` means setup works — open it and check the text
rendered as glyphs rather than boxes. Run it once more *without*
`--update-goldens` to confirm it verifies as well as generates, then delete
the smoke test and its golden.

## 9. Leave the difference tolerance unset

Comparison is pixel-exact by default. **Don't call
`goldenTestDifferenceTolerance` during setup** — a threshold nobody measured
silently absorbs real changes from day one.

It exists for one problem a fresh project doesn't have yet: the same UI
rasterising differently on different machines. Fix that with §10 first. If
identical-looking diffs still recur across machines afterward,
`references/advanced-setup.md` has the measure-first procedure for sizing one.

## 10. Reproducibility

Generate goldens in the environment they'll be verified in: same OS, same
Flutter version, same bundled fonts. The most common source of "unexplained"
golden failures isn't a UI change — it's goldens generated on a
contributor's machine and verified on a different CI runner. Generate and
update from CI (or a container mirroring it) where possible.

## 11. Non-negotiables

- `flutter_test_config.dart`, named exactly that, directly under `test/` (or a nested `test/<dir>/` to scope a subtree — it replaces rather than extends).
- Never hardcode locale/theme/font values that don't match the real app (§2).
- `goldenTestLocalizationsDelegates` takes the app's own delegates only **in a pure `material_ui` app**. In a mixed app (any dependency still on `package:flutter/material.dart`) you must also supply `flutter_localizations`' globals, usually via `AppLocalizations.localizationsDelegates` — see §4.
- Leave the tolerance unset (§9); pin the environment (§10) instead.
- Add `failures/` to `.gitignore` — golden failure artifacts are build output.
- Tag golden tests (`tags: 'golden_test'`) so CI can split them: `--exclude-tags=golden_test` for a fast run, `--tags=golden_test` for the visual suite. **Declare the tag** in `dart_test.yaml` at the package root, or every run prints `Warning: A tag was used that wasn't specified in dart_test.yaml`:

  ```yaml
  # dart_test.yaml
  tags:
    golden_test:
  ```

  There is no `goldenTestDefaultTags` global — the tag goes on every
  `goldenTest` call. If that repetition bothers you, a thin project-level
  wrapper around `goldenTest` (`references/advanced-setup.md`) is the place to default it.
- Hand off to `golden_test-widget` (components) or `golden_test-route` (screens).

## Reference

[`references/advanced-setup.md`](references/advanced-setup.md) — global mocks for cross-cutting services, the
multi-brand wrapper, icon-font loading (Material Icons, third-party icon
packages), sharing config across a monorepo, an app-wide "running in tests"
flag, and the tolerance-sizing procedure. Optional; most projects need none
of it on day one.

The package's `README.md` has further worked examples — a default locale
other than `en_US`, and `google_fonts`.
