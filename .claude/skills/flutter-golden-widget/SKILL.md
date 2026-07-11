---
name: flutter-golden-widget
description: >-
  Write Flutter golden (screenshot) tests for widgets and design-system
  components in isolation using the golden_test package. Use when adding
  component goldens, DS showcases, bottom sheet content, or widget-level
  visual regression tests.
---

# Flutter Golden Tests — Widgets & Components

Pixel-perfect snapshots of **isolated widgets** using the `golden_test` package.

## 1. API shape

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';

void main() {
  goldenTest(
    name: 'ComponentName - variant description',
    builder: (_) => const MyWidget(),
  );
}
```

Full signature (all optional except `name` and `builder`):

```dart
goldenTest(
  name: 'string used verbatim as the filename',
  builder: (BuildContext context) => widget,
  supportedDevices: <Device>[...],      // overrides global
  supportMultipleDevices: false,         // uses goldenTestSupportedDevices
  supportedThemes: [Brightness.light],   // overrides global
  supportedLocales: [Locale('en')],      // overrides global
  supportedTextScales: [1.0, 1.5],       // a11y matrix
  localizationsDelegates: [...],
  setup: (WidgetTester tester) async { /* runs before pump */ },
  tearDown: (WidgetTester tester) async { /* runs after screenshot */ },
  action: (WidgetTester tester) async { /* runs after first settle, before screenshot */ },
  subdirectory: 'design_system',         // inserted after 'goldens/' in path
  tags: 'golden',
  skip: false,
);
```

## 2. Device selection

| Use case | Pattern |
|---|---|
| Isolated component (no chrome) | `supportedDevices: [const Device.noInsets()]` |
| Default phone (from global config) | omit `supportedDevices` |
| Multiple form factors | `supportMultipleDevices: true` or explicit list |
| Custom size for catalog/tall showcase | `Device(name: 'showcase', width: 600, height: 2000)` |

Built-in presets: `Device.noInsets()`, `Device.iphone15Pro()`, `Device.pixel9ProXL()`, `Device.ipadPro12()`, `Device.browser()`.

## 2a. Theme selection

By default tests run with whatever themes are in `goldenTestSupportedThemes` (global config). Override per-test when you want a different set:

```dart
// Force both themes regardless of global config
goldenTest(
  name: 'MyButton - all variants',
  supportedThemes: [Brightness.light, Brightness.dark],
  ...
);

// Light only — useful when the component has no meaningful dark variant
goldenTest(
  name: 'MyBadge - count',
  supportedThemes: [Brightness.light],
  ...
);
```

DS component goldens should almost always include **both light and dark** explicitly — don't rely on global config which may change.

## 2b. Subdirectory

Use `subdirectory` to group goldens by feature or design-system scope. The value is inserted after `goldens/` in the path:

```dart
goldenTest(
  name: 'MyButton - primary',
  subdirectory: 'design_system/buttons',
  ...
);
// → goldens/design_system/buttons/en/light/MyButton - primary.png
```

Useful when:
- A repo has multiple apps or packages sharing one golden folder
- You want to separate DS goldens from feature goldens
- You need to scope `--update-goldens` to a subset: `flutter test --update-goldens` only regenerates files whose paths match the test being run

## 3. When to write one

**Write**: DS components, reusable feature widgets, dialog/bottom-sheet content, responsive behavior across narrow widths.

**Skip**: pure logic (unit test), full screens with many state variants (use a route-level test), copy-only churn, mid-animation frames.

## 4. Patterns

### Variant column — all states in one golden

Stack all variants (enabled/disabled/long text/empty) in a `Column` under one `goldenTest` call.
Prefer `Device.noInsets()` so screenshots are tight.

```dart
goldenTest(
  name: 'MyChip - all variants',
  supportedDevices: [const Device.noInsets()],
  builder: (_) => Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MyChip(label: 'Enabled', onTap: () {}),
          const SizedBox(height: 12),
          MyChip(label: 'Very long label that might overflow', onTap: () {}),
          const SizedBox(height: 12),
          MyChip(label: 'Disabled', onTap: null),
        ],
      ),
    ),
  ),
);
```

### Per-state goldens — separate snapshot per interaction

Use when layout shifts significantly between states. Drive input via `action:`.

```dart
goldenTest(
  name: 'AmountInput - focused with value',
  action: (WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), '0.50');
    await tester.pump();
  },
  builder: (_) => const _AmountInputWrapper(),
);
```

### Stateful controller wrapper

`goldenTest` rebuilds the widget tree per device. Own `TextEditingController`, `FocusNode`, and `ScrollController` inside a `StatefulWidget` — shared instances blow up on multi-device runs.

```dart
class _InputWrapper extends StatefulWidget {
  const _InputWrapper();
  @override
  State<_InputWrapper> createState() => _InputWrapperState();
}

class _InputWrapperState extends State<_InputWrapper> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MyInput(controller: _controller);
}
```

### Catalog showcase (tall device, enum loop)

```dart
goldenTest(
  name: 'MyButton showcase',
  supportedDevices: [const Device(name: 'showcase', width: 400, height: 2000)],
  builder: (_) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final variant in MyButtonVariant.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MyButton(variant: variant, label: variant.name),
          ),
      ],
    ),
  ),
);
```

### Widget with cubit / state management

```dart
goldenTest(
  name: 'MyWidget - success state',
  setup: (_) async {
    when(() => mockCubit.state).thenReturn(MySuccess(data: mockData));
  },
  builder: (_) => BlocProvider<MyCubit>.value(
    value: mockCubit,
    child: const MyWidget(),
  ),
);
```

For other state libraries see `reference.md`.

## 5. Non-negotiables

- **`Device.noInsets()`** for isolated components — removes safe-area chrome.
- **Stateful wrapper** for any `TextEditingController` / `FocusNode` / `ScrollController`.
- **No `Future.delayed` / `.timeout()`** — use `action:` + `pump` / `pumpAndSettle`.
- **Realistic test data** — use factory helpers (`_mockItem()`, etc.) instead of inline literals.
- **`setup:`** for per-golden state stubs; `setUp()` for group-wide stable stubs.
- **Network images** are stubbed out of the box (red placeholder) — no widget changes needed.

## 6. Global config (in `flutter_test_config.dart`)

```dart
goldenTestThemeInTests = myAppLightTheme;
goldenTestDarkThemeInTests = myAppDarkTheme;
goldenTestSupportedThemes = [Brightness.light, Brightness.dark];
goldenTestSupportedLocales = [Locale('en'), Locale('de')];
goldenTestSupportedDevices = [Device.iphone15Pro(), Device.pixel9ProXL()];
goldenTestDefaultDevices = [Device.iphone15Pro()];
// Optional: replace the default red stub image
goldenTestNetworkImageStubPng = myGrayPlaceholderPngBytes;
```

## 7. Running tests

```bash
flutter test test/path/to/widget_test.dart --update-goldens  # generate
flutter test test/path/to/widget_test.dart                   # verify
```

Commit the PNG golden files alongside the test file.

## Reference

See [`reference.md`](reference.md) for full device lists, complete stateful wrapper code, BlocProvider / Riverpod / Provider snippets, and bottom-sheet patterns.
