# golden_test-setup — Reference

Optional, advanced setup patterns. Most projects won't need any of
these on day one — reach for one only when the situation it describes
actually comes up.

## Global mocks for cross-cutting services

Most screens touch a handful of ambient services that have nothing to do
with what's being visually tested — analytics, feature flags, crash
reporting. Register safe no-op mocks for these **once**, globally, in
`testExecutable`, instead of re-stubbing them in every test file:

```dart
void _mockCrossCuttingServices() {
  final analytics = MockAnalyticsService();
  when(() => analytics.logEvent(any())).thenAnswer((_) async {});
  getIt.registerSingleton<AnalyticsService>(analytics);

  final featureFlags = MockFeatureFlagsService();
  when(() => featureFlags.isEnabled(any())).thenReturn(false);
  getIt.registerSingleton<FeatureFlagsService>(featureFlags);
}
```

If a design-system component itself reads something out of DI during
build (an app-config object, a theme-mode service), mock that here too —
that's a signal it's a genuine cross-cutting dependency, not a
per-screen concern.

## Multiple brands or flavors

If the app ships more than one visual brand/flavor from one codebase
(white-label, or a shared component library skinned per client), a
single `goldenTestThemeInTests` global isn't enough — you want every
component tested under each brand it ships in. Rather than duplicating
every test file per brand, write a thin project-level wrapper around
`goldenTest` that loops internally:

```dart
import 'package:meta/meta.dart';

@isTest
void myAppGoldenTest({
  required String name,
  required Widget child,
  bool generateForBrandA = true,
  bool generateForBrandB = false,
  List<Device>? supportedDevices,
  // ...forward the rest of goldenTest's parameters
}) {
  final brands = [
    if (generateForBrandA) Brand.a,
    if (generateForBrandB) Brand.b,
  ];

  for (final brand in brands) {
    goldenTest(
      name: brands.length > 1 ? '$name (${brand.name})' : name,
      builder: (_) => AppTheme(brand: brand, child: child),
      supportedDevices: supportedDevices,
      subdirectory: brand.name, // keeps each brand's goldens separate
    );
  }
}
```

Test authors call `myAppGoldenTest(...)` instead of `goldenTest(...)`
and get the right brand coverage by default, without having to think
about it per test. The `@isTest` annotation (from `package:meta`) is
what `goldenTest` itself carries — add it to your own wrapper too, so
IDEs and `flutter test` tooling recognize each call as its own test
case (run/debug gutter icons, correct test counts) instead of treating
it as a plain helper function.

## Icon fonts that aren't in your own asset bundle

If icons render as empty boxes or fallback glyphs in goldens:

- **Material Icons**: not loaded automatically in tests. Load it from
  the Flutter SDK's own cache directory using the `FLUTTER_ROOT`
  environment variable, rather than bundling a copy yourself:
  `$FLUTTER_ROOT/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf`.
- **A third-party icon-font package** (an icon set distributed as a
  pub.dev package) that isn't declared under your own `pubspec.yaml`'s
  `flutter: fonts:`: resolve its installed location via
  `.dart_tool/package_config.json` (so you load the exact version your
  project actually resolved) and load the font file directly from
  there with `FontLoader('packages/<package_name>/<FontFamily>')`.

Both are a few lines of one-time setup code; wrap them in a try/catch
that fails open, so a missing font degrades to a fallback glyph in CI
rather than breaking every golden test in the suite.

## Sharing config across multiple packages (monorepo)

If several packages/apps in a monorepo each need their own
`flutter_test_config.dart`, factor the common wiring (font loading,
cross-cutting mocks, locale/localization-delegate setup) into one
internal helper function that every package's config calls with just
its own specifics:

```dart
// in a shared internal package
Future<void> configureGoldenTests({required MyThemeType themeType, Map<String, List<String>> fonts = const {}}) async {
  // shared device/locale/localization-delegate/theme wiring here
}

// in each package's test/flutter_test_config.dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await configureGoldenTests(themeType: MyThemeType.defaultTheme, fonts: _fonts);
  return testMain();
}
```

This avoids each package's config drifting from the others as the
project grows.

## An app-wide "running in tests" flag

Some non-determinism is awkward to fix through DI/mocking alone — a real
map or ads SDK that doesn't work under `flutter test`, a debounce timer,
a shimmer animation, "now". A small ambient flag, registered once and
checked at those specific call sites, is often simpler than stubbing
each one individually:

```dart
class TestEnvironment {
  bool isRunningInTests = Platform.environment.containsKey('FLUTTER_TEST');
}
```

`FLUTTER_TEST` is set automatically by the Flutter test runner, so this
needs no wiring in `flutter_test_config.dart` beyond registering it in
your DI container. Production code then checks it directly at the few
places that need to behave differently under test:

```dart
DateTime now() =>
    sl<TestEnvironment>().isRunningInTests ? _frozenTestTime : DateTime.now();

// skip a real third-party SDK call and render a placeholder instead
if (!sl<TestEnvironment>().isRunningInTests) { ... }

// no debounce delay under test
Duration(milliseconds: sl<TestEnvironment>().isRunningInTests ? 0 : 500)
```

This is an alternative to per-test stubbing, not a replacement for it —
reach for it only for the handful of things that are genuinely awkward
to fake through a mocked dependency (a real time source, a debounce
timer, a third-party SDK your app doesn't control).

## Sizing a difference tolerance

Only reach for this after pinning the environment (SKILL.md §10) and still
seeing identical-looking diffs recur across machines. Tolerance exists for
**one** problem: the same UI rasterising differently on different hardware —
anti-aliased edges, shadows, rounding inside illustrations and gradients,
identical geometry with pixels a value or two apart.

1. **Confirm it's noise.** Open `failures/<name>_isolatedDiff.png`.
   Scattered single-channel speckle along edges, at identical image
   dimensions, is drift. Readable shapes, a solid region, a size change or a
   shifted element is a real change — however small the percentage.
2. **Measure.** Collect the reported percentages over several runs on the
   machines that disagree. The failure message gives both figures:
   `Pixel test failed, 0.11%, 3362px diff detected.`
3. **Set the smallest value that covers them**, in
   `flutter_test_config.dart`:

   ```dart
   goldenTestDifferenceTolerance(0.05); // percent
   ```

Then treat it as a floor, not a licence. It suppresses *failures*, not
changes:

- **If the UI changed, regenerate** even though the suite is green.
  Otherwise small real diffs accumulate under the threshold until the
  committed goldens no longer show what the app renders.
- **The budget is finite.** Real drift silently absorbed eats the headroom
  meant for cross-machine noise, so genuine platform diffs start failing.

A tolerance that keeps needing to grow is evidence the environment isn't
pinned, not evidence the number was too small.
