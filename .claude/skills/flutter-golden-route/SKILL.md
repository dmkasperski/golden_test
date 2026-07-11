---
name: flutter-golden-route
description: >-
  Write Flutter golden tests for full screens and cubit/state-driven UI
  (loading, success, error, empty, scrolled). Use when adding screen-level
  goldens or visual regression for navigation destinations — not isolated
  DS components (use flutter-golden-widget for those).
---

# Flutter Golden Tests — Screens & State-Driven Routes

Full-screen snapshots covering **every state** a screen can render.
For isolated components use `flutter-golden-widget`.

## 1. API shape

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';

void main() {
  goldenTest(
    name: 'FeatureScreen - Loading',
    builder: (_) => const FeatureScreen(),
  );
}
```

## 1a. Theme selection

Override `supportedThemes` per-test when you need something other than the global config:

```dart
// Both themes — good default for screens that support dark mode
goldenTest(
  name: 'FeatureScreen - Success',
  supportedThemes: [Brightness.light, Brightness.dark],
  ...
);

// Light only — for screens where dark mode isn't implemented yet
goldenTest(
  name: 'OnboardingScreen - Step 1',
  supportedThemes: [Brightness.light],
  ...
);
```

## 1b. Subdirectory

Group goldens by feature to keep the `goldens/` folder navigable and to scope `--update-goldens` runs:

```dart
goldenTest(
  name: 'FeatureScreen - Loading',
  subdirectory: 'feature/cards',
  ...
);
// → goldens/feature/cards/en/light/FeatureScreen - Loading.png
```

## 2. Pick the injection pattern

Use the shallowest mock layer the screen allows.

| Pattern | When to use |
|---|---|
| **A. Constructor param** | Screen exposes a `cubitForTesting:` / `stateForTesting:` param |
| **B. `BlocProvider.value`** | No test hook, but the cubit can be provided via context |
| **C. `ProviderScope` overrides** | Riverpod — override the relevant provider |
| **D. `setUp` + service locator** | Cubit/screen resolves from GetIt/locator during build |
| **E. Static screen** | No state management at all |

Rule: stub **state first**. Only mock repositories or services when the screen still calls them during build / first frame.

## 3. Mock cubit setup (BLoC / Cubit)

```dart
class MockFeatureCubit extends Mock implements FeatureCubit {
  @override
  Stream<FeatureState> get stream => const Stream.empty();
  @override
  Future<void> close() => Future.value();
}

void main() {
  final cubit = MockFeatureCubit();

  setUp(() {
    when(() => cubit.state).thenReturn(const FeatureInitial());
  });

  goldenTest(
    name: 'FeatureScreen - Success',
    setup: (_) async {
      when(() => cubit.state).thenReturn(FeatureSuccess(items: _mockItems()));
    },
    builder: (_) => BlocProvider<FeatureCubit>.value(
      value: cubit,
      child: const FeatureScreen(),
    ),
  );
}
```

Reuse one cubit instance per file. Stub `state` per golden in `setup:`.

| Hook | Scope | Use for |
|---|---|---|
| `setUp()` | Group-wide | Fallback stubs, `registerFallbackValue`, stable stream stubs |
| `setup:` | Single golden | `when(() => cubit.state).thenReturn(...)` for that visual state |

## 4. Required states for every screen

- [ ] **Loading** (+ `disableAnimations: true` if shimmer / spinner present)
- [ ] **Success** with representative data (use factory helpers)
- [ ] **Error**
- [ ] **Empty** (success state with empty collection)
- [ ] **Domain variants** — tabs, filters, expanded sections, feature-flag branches
- [ ] **Scrolled to bottom** — `action: (t) async { await t.drag(...); await t.pumpAndSettle(); }` on a short device
- [ ] **Multi-device** — only when layout meaningfully changes per form factor

Don't add a golden per locale unless translated copy has overflow risk.

## 5. Scroll & interaction actions

### Scroll to bottom

```dart
goldenTest(
  name: 'FeatureScreen - Scrolled',
  supportedDevices: [
    const Device(name: 'short', width: 390, height: 400, devicePixelRatio: 3),
  ],
  action: (WidgetTester tester) async {
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
  },
  builder: (_) => BlocProvider<FeatureCubit>.value(
    value: cubit,
    child: const FeatureScreen(),
  ),
);
```

### Tap to expand

```dart
action: (WidgetTester tester) async {
  await tester.tap(find.byType(ExpansionTile).first);
  await tester.pumpAndSettle();
},
```

### Scroll until widget is visible (lazy lists)

```dart
action: (WidgetTester tester) async {
  await tester.scrollUntilVisible(find.byKey(const Key('footer')), 300);
  await tester.pump();
},
```

## 6. Non-negotiables

- **`disableAnimations: true`** for loading / shimmer / spinner states — `pumpAndSettle()` times out otherwise.
- **Stub `state` — never call `emit()`** in tests.
- **No `Future.delayed` / `.timeout()`** — use `action:` + `pump` / `pumpAndSettle`.
- **Service locator isolation** — `pushNewScope` / `popScope` per test when using GetIt.
- **Use `DateTime(2024, 1, 1)`** not `DateTime.utc(...)` when UI calls `.toLocal()` (timezone parity on CI).
- **Network images** are stubbed automatically (red placeholder) — no widget changes needed.

## 7. Minimal call shapes

```dart
// Loading state
goldenTest(
  name: 'FeatureScreen - Loading',
  disableAnimations: true,
  setup: (_) async {
    when(() => cubit.state).thenReturn(const FeatureLoading());
  },
  builder: (_) => BlocProvider<FeatureCubit>.value(
    value: cubit,
    child: const FeatureScreen(),
  ),
);

// Success state (default device from flutter_test_config.dart)
goldenTest(
  name: 'FeatureScreen - Success',
  setup: (_) async {
    when(() => cubit.state).thenReturn(FeatureSuccess(items: _mockItems()));
  },
  builder: (_) => BlocProvider<FeatureCubit>.value(
    value: cubit,
    child: const FeatureScreen(),
  ),
);
```

## 8. File placement & naming

- Mirror feature path: `lib/feature/ui/feature_screen.dart` → `test/feature/ui/feature_screen_test.dart`.
- Test name: `'ScreenName - State description'`.
- Goldens: `test/feature/ui/goldens/en/light/FeatureScreen - Loading.png`.

## 9. Running tests

```bash
flutter test test/path/to/feature_screen_test.dart --update-goldens
flutter test test/path/to/feature_screen_test.dart  # verify
```

Commit the PNG files alongside the test file.

## Reference

See [`reference.md`](reference.md) for: full file template, GetIt scope + repository stubbing block, Riverpod/Provider equivalents, scroll recipes, tall-device patterns, and state-data fixture conventions.
