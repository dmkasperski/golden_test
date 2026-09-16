# golden_test-widget — Reference

Full examples cited from `SKILL.md`. Read on demand.

All examples import `package:material_ui/material_ui.dart` (Flutter
`>=3.47`); on older Flutter with `golden_test` 1.x that's
`package:flutter/material.dart` instead.

## Device sets

### Default — isolated component

```dart
supportedDevices: [const Device.noInsets()],
```

`Device.noInsets()` is `393x852` logical at `devicePixelRatio: 3` — a
1179x2556 PNG. Override individual fields with `.copyWith(...)` when the
component needs more room, or drop the ratio for a showcase golden that
would otherwise be enormous:

```dart
supportedDevices: [const Device.noInsets().copyWith(devicePixelRatio: 1)],
```

The bare `Device()` constructor defaults to `420x800` at ratio 1, which is
often a better base for a tall catalog image than shrinking `noInsets()`.

### Showcase device (all variants in one image)

Size it to the content — anything below the fold is silently lost: the run
stays green and the PNG looks complete. Open the image after the first
generate and confirm both that the last row is fully visible and that a
strip of background follows it. That strip is the proof nothing was cut; a
void half the image tall means the height was a guess.

```dart
supportedDevices: [const Device(name: 'showcase', width: 420, height: 1400)],
```

### Reflow breakpoints

Only for components that change layout with available width — still no
insets, since width is what's under test.

```dart
const List<Device> _widths = [
  Device(name: 'narrow', width: 320, height: 900),
  Device(name: 'regular', width: 420, height: 900),
  Device(name: 'wide', width: 900, height: 900),
];

goldenTest(
  name: 'MyCard - reflow',
  supportedDevices: _widths,
  supportMultipleDevices: true,
  builder: (_) => const MyCard(),
);
```

### Screen-shaped widgets

Bottom sheets, dialogs, snackbars, anything that reasons about safe areas
or the bottom inset — use a real preset, because the chrome is the point.

```dart
supportedDevices: [const Device.iphone15Pro()],
```

---

## Pattern: labeled showcase

The default shape for a component golden — every combination in one
reviewable image, each row captioned.

```dart
goldenTest(
  name: 'MyChip - variants',
  supportedDevices: [const Device(name: 'showcase', width: 420, height: 1600)],
  supportedThemes: [Brightness.light, Brightness.dark],
  builder: (_) => Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final variant in MyChipVariant.values)
            for (final enabled in const [true, false])
              for (final withIcon in const [true, false]) ...[
                _Label('${variant.name} / '
                    '${enabled ? 'enabled' : 'disabled'} / '
                    '${withIcon ? 'icon' : 'no icon'}'),
                MyChip(
                  variant: variant,
                  label: 'Label',
                  icon: withIcon ? Icons.star : null,
                  onTap: enabled ? () {} : null,
                ),
                const SizedBox(height: 16),
              ],
        ],
      ),
    ),
  ),
);

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, color: Colors.grey),
    ),
  );
}
```

### Data-shape section

The showcase enumerates what the *constructor* takes. This one enumerates
what the widget's own code branches on — the cases a props table doesn't
show. One labelled golden, same as above.

```dart
goldenTest(
  name: 'MyChip - data shapes',
  supportedDevices: [const Device(name: 'showcase', width: 420, height: 1200)],
  supportedThemes: [Brightness.light, Brightness.dark],
  builder: (_) => Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Absent fields — null vs empty may take different paths.
          _Label('subtitle: null'),
          MyChip(label: 'Label', subtitle: null),
          _Label("subtitle: '' (renders an empty line box if unguarded)"),
          MyChip(label: 'Label', subtitle: ''),

          // 2. Sentinel values — magic numbers the type doesn't advertise.
          _Label('amountMinor: -1 → "Free"'),
          MyChip(label: 'Label', amountMinor: -1),
          _Label('amountMinor: 0 → "Pay what you want"'),
          MyChip(label: 'Label', amountMinor: 0),
          _Label('amountMinor: 2500 → formatted'),
          MyChip(label: 'Label', amountMinor: 2500),

          // 3. Relationships — only reachable by varying two fields together.
          _Label('start/end same day → "12 Mar, 10:00–18:30"'),
          MyChip(label: 'Label', start: _t(10, 0), end: _t(18, 30)),
          _Label('start/end different days → "12 Mar – 15 Mar"'),
          MyChip(label: 'Label', start: _t(10, 0), end: _t(10, 0).add(const Duration(days: 3))),
          _Label('end before start (API can still return it)'),
          MyChip(label: 'Label', start: _t(18, 0), end: _t(10, 0)),
        ],
      ),
    ),
  ),
);
```

How to find them: open the widget and look for `if`, `??`, a ternary in a
`children:` list, `switch`, `.isEmpty`, a null check, or a comparison
between two fields. Each branch that changes pixels is a row here.

Captions stay in English even when the app and its fixtures are in another
language — they label the *case* for a reviewer, and the widget beneath them
already shows the localised content. Keep them ASCII unless the bundled font
covers what you type.

---

### Content-shape section

Text-length coverage belongs in the same file, as deliberate content
variants rather than a locale sweep:

```dart
goldenTest(
  name: 'MyChip - content shapes',
  supportedDevices: [const Device(name: 'showcase', width: 420, height: 1000)],
  supportedThemes: [Brightness.light, Brightness.dark],
  supportedTextScales: [1.0, AndroidFontScale.maximum.value],
  builder: (_) => Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final label in const [
            'A',
            'Short',
            'A label long enough to wrap onto a second line in this width',
            'Supercalifragilisticexpialidocious',
            '1 234 567 890',
            '',
          ]) ...[
            _Label('"${label.isEmpty ? '(empty)' : label}"'),
            MyChip(label: label, onTap: () {}),
            const SizedBox(height: 16),
          ],
        ],
      ),
    ),
  ),
);
```

---

## Pattern: per-state goldens

For states that can't be reached by construction — focus, entered text,
expansion. One `action:` drives one tree, so each gets its own golden.

```dart
goldenTest(
  name: 'AmountInput - focused with value',
  supportedDevices: [const Device.noInsets()],
  action: (WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), '0.50');
    await tester.pump();
  },
  builder: (_) => const _AmountInputWrapper(),
);
```

---

## Pattern: stateful controller wrapper

```dart
class _InputWrapper extends StatefulWidget {
  const _InputWrapper({this.initialValue});
  final String? initialValue;

  @override
  State<_InputWrapper> createState() => _InputWrapperState();
}

class _InputWrapperState extends State<_InputWrapper> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: MyInput(
        controller: _controller,
        focusNode: _focusNode,
      ),
    ),
  );
}

// Drive text input in action:
goldenTest(
  name: 'MyInput - with value',
  supportedDevices: [const Device.noInsets()],
  action: (tester) async {
    final state = tester.state<EditableTextState>(
      find.byType(EditableText).first,
    );
    state.widget.controller.text = '42.00';
    await tester.pump();
  },
  builder: (_) => const _InputWrapper(),
);
```

---

## Pattern: widget with state management

Pick whichever of these matches your project — they're equally valid,
interchangeable ways to get a mocked/overridden state into the widget
under test.

### BLoC / Cubit

```dart
class MockMyCubit extends Mock implements MyCubit {
  @override
  Stream<MyState> get stream => const Stream.empty();

  @override
  Future<void> close() => Future.value();
}

void main() {
  late MockMyCubit cubit;

  group('MyWidget', () {
    setUpAll(() {
      registerFallbackValue(const MyInitial());
    });

    setUp(() {
      cubit = MockMyCubit();
      when(() => cubit.state).thenReturn(const MyInitial());
    });

    tearDown(() {
      reset(cubit);
    });

    goldenTest(
      name: 'MyWidget - success',
      supportedDevices: [const Device.noInsets()],
      // setup: only overrides what's different for this golden — the
      // happy-path baseline already lives in setUp() above.
      setup: (_) async {
        when(() => cubit.state).thenReturn(MySuccess(data: _mockData()));
      },
      builder: (_) => BlocProvider<MyCubit>.value(
        value: cubit,
        child: const MyWidget(),
      ),
    );
  });
}
```

### Riverpod

```dart
builder: (_) => ProviderScope(
  overrides: [myProvider.overrideWith((_) => mockNotifier)],
  child: const MyWidget(),
),
```

### Provider / ChangeNotifier (via a DI package)

```dart
builder: (_) => ChangeNotifierProvider<MyController>.value(
  value: mockController,
  child: const MyWidget(),
),
```

### Plain ChangeNotifier / ValueNotifier (no DI package)

For widgets that just take a controller directly as a constructor
parameter, with no provider/locator involved:

```dart
builder: (_) => MyWidget(
  controller: MyController.forTesting(state: MySuccess(data: _mockData())),
),
```

---

## Pattern: RTL variant

One golden, not a locale sweep.

```dart
goldenTest(
  name: 'MyListTile - RTL',
  supportedDevices: [const Device.noInsets()],
  builder: (_) => const Directionality(
    textDirection: TextDirection.rtl,
    child: MyListTile(
      leading: Icon(Icons.star),
      title: Text('Label'),
      trailing: Icon(Icons.chevron_right),
    ),
  ),
);
```

**Only if the app ships an RTL locale** (`ar`, `he`, `fa`, `ur` …). In an
app that doesn't, this golden can never catch a real regression and still
breaks on every layout change.

Given that, worth adding for any component whose layout depends on
direction — icon position relative to text, row order, asymmetric
padding/margins, `chevron_right` vs. `chevron_left` style affordances.
Skip it even then for components that are symmetric or icon-only.

---

## Pattern: reusable test harness

When most of a design system's component tests need the same ambient
setup, factor it into one small helper instead of repeating it per file:

```dart
Widget wrapForGolden(
  Widget child, {
  TextDirection textDirection = TextDirection.ltr,
  bool center = true,
}) => Directionality(
  textDirection: textDirection,
  child: Material(
    child: center ? Center(child: child) : child,
  ),
);

// usage
goldenTest(
  name: 'MyChip - RTL',
  supportedDevices: [const Device.noInsets()],
  builder: (_) => wrapForGolden(
    const MyChip(label: 'Label'),
    textDirection: TextDirection.rtl,
  ),
);
```

Keep the harness thin — a wrapper that starts accumulating real app logic
(routing, network, persisted state) is a sign the component needs its own
testing seam rather than a bigger shared harness.

---

## Pattern: bottom-sheet content

Test the content widget directly — never call `showModalBottomSheet` in
goldens. This is a screen-shaped widget, so use a real device: the bottom
inset is part of what you're checking.

```dart
goldenTest(
  name: 'MySheet - default',
  supportedDevices: [const Device.iphone15Pro()],
  supportedThemes: [Brightness.light, Brightness.dark],
  builder: (_) => Scaffold(
    body: Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: MySheetContent(onConfirm: () {}),
      ),
    ),
  ),
);
```

---

## Pattern: components that load images

No mocking needed — `golden_test` resolves every `NetworkImage` to a
checkerboard placeholder by default, so a URL-taking component renders deterministically:

```dart
goldenTest(
  name: 'UserAvatar - variants',
  supportedDevices: [const Device.noInsets()],
  builder: (_) => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      UserAvatar(imageUrl: 'https://example.com/a.png', size: 32),
      SizedBox(width: 12),
      UserAvatar(imageUrl: 'https://example.com/b.png', size: 48),
      SizedBox(width: 12),
      UserAvatar(imageUrl: null, initials: 'DK', size: 48),
    ],
  ),
);
```

The placeholder is a fixed image, so this covers size, fit, clipping and
border radius — not the real asset's content. For a component whose look
depends on the image itself, use a local asset fixture; for its loading
and error states, inject a custom `ImageProvider`, since the stub always
succeeds immediately.

---

## Minimal file template

```dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';

void main() {
  group('MyComponent', () {
    goldenTest(
      name: 'MyComponent - variants',
      supportedDevices: [
        const Device(name: 'showcase', width: 420, height: 1200),
      ],
      supportedThemes: [Brightness.light, Brightness.dark],
      tags: 'golden_test',
      builder: (_) => Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final variant in MyVariant.values)
                for (final enabled in const [true, false]) ...[
                  Text(
                    '${variant.name} / ${enabled ? 'enabled' : 'disabled'}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  MyComponent(variant: variant, onTap: enabled ? () {} : null),
                  const SizedBox(height: 16),
                ],
            ],
          ),
        ),
      ),
    );
  });
}
```

---

## Golden output path structure

`goldens/{subdirectory?}/{locale}/{brightness}/{deviceName?}/{textScale?}/{name}.png`

The device segment appears only when the test runs on more than one
device; the text-scale segment only when `supportedTextScales` has more
than one value.

Examples:
- `goldens/en/light/MyComponent - variants.png` (single device, single scale)
- `goldens/en/dark/narrow/MyCard - reflow.png` (multi-device)
- `goldens/en/light/2x/MyChip - content shapes.png` (text-scale matrix; trailing zeros are trimmed, so `1.0`→`1x`, `1.30`→`1.3x`)
- `goldens/design_system/en/light/MyButton - variants.png` (subdirectory)

Mirror `lib/` structure under `test/`.
