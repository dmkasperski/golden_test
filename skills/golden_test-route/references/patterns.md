# golden_test-route — Reference

Full examples cited from `SKILL.md`. Read on demand.

All examples import `package:material_ui/material_ui.dart` (Flutter
`>=3.47`); on older Flutter with `golden_test` 1.x that's
`package:flutter/material.dart` instead.

## A full worked file

The shape to copy: one group, a shared happy-path `setUp`, fresh mocks per
test, and each `setup:` overriding only what differs. Uses Cubit/BLoC —
swap the injection for whichever recipe below matches the project.

```dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFeatureCubit extends Mock implements FeatureCubit {
  @override
  Stream<FeatureState> get stream => const Stream.empty();
  @override
  Future<void> close() => Future.value();
}

void main() {
  group('$FeatureScreen', () {
    late MockFeatureCubit cubit;

    setUp(() {
      // Fresh instance per test — a shared one leaks stubs between goldens.
      cubit = MockFeatureCubit();
      when(() => cubit.state).thenReturn(const FeatureInitial());
    });

    tearDown(() => reset(cubit));

    Widget build() => BlocProvider<FeatureCubit>.value(
      value: cubit,
      child: const FeatureScreen(),
    );

    goldenTest(
      name: 'FeatureScreen - Loading',
      tags: 'golden_test',
      setup: (_) async {
        when(() => cubit.state).thenReturn(const FeatureLoading());
      },
      // Only needed if the loading indicator animates forever.
      builder: (_) => TickerMode(enabled: false, child: build()),
    );

    goldenTest(
      name: 'FeatureScreen - Success',
      tags: 'golden_test',
      setup: (_) async {
        when(() => cubit.state).thenReturn(FeatureSuccess(items: _items()));
      },
      builder: (_) => build(),
    );

    goldenTest(
      name: 'FeatureScreen - Empty',
      tags: 'golden_test',
      setup: (_) async {
        when(() => cubit.state).thenReturn(const FeatureSuccess(items: []));
      },
      builder: (_) => build(),
    );

    goldenTest(
      name: 'FeatureScreen - Error',
      tags: 'golden_test',
      setup: (_) async {
        when(() => cubit.state).thenReturn(const FeatureError());
      },
      builder: (_) => build(),
    );

    // One stress variant on the richest state, not across all four.
    // This one only earns its place if the app ships an RTL locale.
    goldenTest(
      name: 'FeatureScreen - Success, RTL',
      tags: 'golden_test',
      setup: (_) async {
        when(() => cubit.state).thenReturn(FeatureSuccess(items: _items()));
      },
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: build(),
      ),
    );
  });
}

List<Item> _items() => [
  Item(id: '1', title: 'First item', updatedAt: DateTime(2024, 1, 1)),
  Item(id: '2', title: 'A much longer title that will wrap onto two lines'),
];
```

A constructor-injected variant is identical except `build()` becomes
`FeatureScreen(cubitForTesting: cubit)` — prefer that when the screen
exposes such a param, since it skips `BlocProvider` entirely.

---

## State-injection recipes

Substitute for `build()` above.

### Riverpod

```dart
Widget build(FeatureState state) => ProviderScope(
  overrides: [featureProvider.overrideWith((_) => state)],
  child: const FeatureScreen(),
);
```

### Provider

```dart
Widget build() => ChangeNotifierProvider<FeatureController>.value(
  value: mockController,
  child: const FeatureScreen(),
);
```

### Plain ChangeNotifier / ValueNotifier (no DI package)

For screens that own a notifier directly — construct it in the state you
want and hand it over:

```dart
Widget build(FeatureState state) => FeatureScreen(
  controller: FeatureController.forTesting(state: state),
);
```

If the screen doesn't expose a way to inject a pre-built controller, that's
usually worth adding — a small seam that makes every other recipe here
unnecessary.

### Service locator (GetIt or similar)

For screens that resolve a dependency from a locator during construction or
`initState`. **Scope registrations per test** — this is the leak the skill's
§6 warns about:

```dart
group('$FeatureScreen', () {
  late MockFeatureRepository repository;
  late MockSettingsRepository settings;

  setUp(() {
    getIt.pushNewScope();

    repository = MockFeatureRepository();
    getIt.registerLazySingleton<FeatureRepository>(() => repository);
    when(() => repository.dataStream).thenAnswer((_) => const Stream.empty());

    settings = MockSettingsRepository();
    getIt.registerLazySingleton<SettingsRepository>(() => settings);
    when(() => settings.theme).thenReturn(AppTheme.light);
  });

  tearDown(() async => getIt.popScope());

  // Keep each mock's construction, registration and stubbing together rather
  // than batching all the constructors, then all the registrations, then all
  // the `when`s. One block per dependency stays readable as they multiply,
  // and a mock that's missing a step is obvious.

  goldenTest(
    name: 'FeatureScreen - Success',
    // Only what differs — the baseline lives in setUp().
    setup: (_) async {
      when(() => repository.getStatus()).thenAnswer((_) async => Status.ready);
    },
    builder: (_) => const FeatureScreen(),
  );
});
```

---

## Simulating a pushed route (back button, `canPop`)

Some screens render chrome — an AppBar back arrow, a custom close
affordance — only when they're not the first route, i.e. when
`Navigator.canPop(context)` is true. `golden_test` ships a helper; don't
hand-roll a bootstrap widget:

```dart
goldenTest(
  name: 'FeatureScreen - as pushed route (shows back button)',
  builder: (_) => simulateRouteStack(const FeatureScreen()),
);
```

`simulateRouteStack` is exported from `package:golden_test/golden_test.dart`.
No extra `setup:`/`action:` wiring — `goldenTest` pumps and settles after
building, which flushes the scheduled push before the screenshot.

One constraint: the helper holds a **static** `GlobalKey`, so two
`simulateRouteStack` widgets cannot be alive at the same time. Fine for
tests that run one after another — but don't put two in a single golden's
tree.

---

## Data-shape states — worked examples

Three kinds, each shown as: the branch in the code, the fixtures that reach
it, the goldens that come out. Names describe the data condition, not the
widget.

### 1. Absent fields

```dart
// lib/feature/ui/widgets/item_row.dart
Row(
  children: [
    if (item.imageUrl != null) Thumbnail(url: item.imageUrl!),
    Text(item.title),
    if (item.subtitle != null) Text(item.subtitle!),
  ],
)
```

Two independent optional fields: four reachable shapes, and the layout
differs in each.

```dart
goldenTest(
  name: 'FeatureScreen - item without image',
  setup: (_) async => _stub(_items(imageUrl: null)),
  builder: (_) => build(),
);

goldenTest(
  name: 'FeatureScreen - item without subtitle',
  setup: (_) async => _stub(_items(subtitle: null)),
  builder: (_) => build(),
);

goldenTest(
  name: 'FeatureScreen - item with title only',
  setup: (_) async => _stub(_items(imageUrl: null, subtitle: null)),
  builder: (_) => build(),
);
```

**Check whether `null` and `''` take the same path.** The code above sends
an empty subtitle down the *rendering* branch — `Text('')` still occupies a
line box and can shift everything below it. If the guard were
`item.subtitle?.isNotEmpty ?? false`, they'd collapse to the same output. A
golden pins which of the two the code actually does:

```dart
goldenTest(
  name: 'FeatureScreen - item with empty subtitle',
  setup: (_) async => _stub(_items(subtitle: '')),
  builder: (_) => build(),
);
```

### 2. Sentinel values

```dart
// lib/feature/ui/format/price_label.dart
String priceLabel(int amountMinor) {
  if (amountMinor < 0) return 'Free';              // -1 = free
  if (amountMinor == 0) return 'Pay what you want'; // 0 is NOT the same
  return formatCurrency(amountMinor);
}
```

Nothing about the type `int` says `-1` and `0` are special, and a schema
won't either — only this function does. Each magic value is a golden, plus a
large value for layout:

```dart
for (final (name, amount) in const [
  ('free', -1),
  ('pay what you want', 0),
  ('priced', 2500),
  ('large amount', 9999999),
])
  goldenTest(
    name: 'FeatureScreen - $name',
    setup: (_) async => _stub(_items(amountMinor: amount)),
    builder: (_) => build(),
  );
```

Other shapes worth grepping for: a status string that means "unset", an
index of `-1`, a count of `0` meaning "unlimited" rather than "none", a
`DateTime` sentinel far in the past or future.

### 3. Relationships between fields

```dart
// lib/feature/ui/format/date_range.dart
String dateRange(DateTime start, DateTime? end) {
  if (end == null) return _dayAndTime(start);
  if (_sameDay(start, end)) {
    return '${_day(start)}, ${_time(start)}–${_time(end)}';
  }
  return '${_day(start)} – ${_day(end)}';
}
```

Three renderings, and no single field is interesting on its own — you only
reach them by varying `start` and `end` *together*:

```dart
goldenTest(
  name: 'FeatureScreen - no end date',
  setup: (_) async => _stub(_items(start: _t(10, 0), end: null)),
  builder: (_) => build(),
);

goldenTest(
  name: 'FeatureScreen - same-day range',
  setup: (_) async => _stub(_items(start: _t(10, 0), end: _t(18, 30))),
  builder: (_) => build(),
);

goldenTest(
  name: 'FeatureScreen - multi-day range',
  setup: (_) async =>
      _stub(_items(start: _t(10, 0), end: _t(10, 0).add(const Duration(days: 3)))),
  builder: (_) => build(),
);
```

Then the one nobody writes: the *invalid* relation the API can still return.

```dart
goldenTest(
  name: 'FeatureScreen - end before start',
  setup: (_) async =>
      _stub(_items(start: _t(18, 0), end: _t(10, 0))),
  builder: (_) => build(),
);
```

Other relations worth looking for: a discount equal to or above the full
price, a used count above its quota, a value crossing the threshold where
its unit changes (metres to kilometres), a range whose ends are equal.

### Bounding the set

The three kinds above are a way to *find* candidates, not a quota to fill.
Before writing each one, ask whether it produces an image you could tell
apart from the others. Two fixtures that render the same thing are one
golden; a branch that changes only a semantic label or an analytics event is
no golden at all.

For a screen, bundle independent shapes rather than pairing them:

```dart
// One fixture, three unrelated absent fields, one PNG to review.
goldenTest(
  name: 'FeatureScreen - sparse item',
  setup: (_) async => _stub(_items(
    imageUrl: null,
    subtitle: null,
    end: null,
  )),
  builder: (_) => build(),
);
```

That replaces three near-identical full-screen goldens. Split them back out
only when you need to isolate which field broke, or when two of them
interact — both collapsing and leaving the container empty, say.

## Scroll & interaction recipes

`action:` runs after the first settle, before the screenshot.

### Scroll to bottom

```dart
goldenTest(
  name: 'FeatureScreen - Scrolled',
  supportedDevices: [
    const Device(name: 'short', width: 390, height: 400, devicePixelRatio: 3),
  ],
  action: (WidgetTester tester) async {
    // `find.byType(Scrollable)` works whatever the screen actually uses —
    // ListView, CustomScrollView, or a project-specific wrapper around one.
    // Naming a concrete type fails with "Found 0 widgets" the moment the
    // screen doesn't use that exact class.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
  },
  builder: (_) => const FeatureScreen(),
);
```

### Tap to expand

```dart
action: (WidgetTester tester) async {
  await tester.tap(find.byType(ExpansionTile).first);
  await tester.pumpAndSettle();
},
```

### Scroll until a widget is visible (lazy lists)

```dart
action: (WidgetTester tester) async {
  await tester.scrollUntilVisible(find.byKey(const Key('footer')), 300);
  await tester.pump();
},
```

### Pull to refresh

```dart
action: (WidgetTester tester) async {
  final center = tester.getCenter(find.byType(MaterialApp));
  await tester.startGesture(center);
  await tester.dragFrom(center, const Offset(0, 75));
  await tester.pump();
},
```

## Tall device — the whole page in one golden

```dart
const _tall = Device(name: 'tall', width: 393, height: 4000,
    devicePixelRatio: 3, insets: EdgeInsets.zero);

goldenTest(
  name: 'FeatureScreen - loaded',
  supportedDevices: [_tall],
  builder: (_) => const FeatureScreen(),
);

// Large text needs even more room — the content roughly doubles.
goldenTest(
  name: 'FeatureScreen - loaded, large text',
  supportedDevices: [_tall.copyWith(name: 'tall-xl', height: 8000)],
  supportedTextScales: [AndroidFontScale.maximum.value],
  builder: (_) => const FeatureScreen(),
);
```

Size it to the content and check the PNG after the first generate. Too short
silently cuts the bottom — and still passes, every run. Too tall leaves a
void that makes the golden harder to review and the file bigger. Aim for the
content filling the frame with a visible margin below it.

`devicePixelRatio: 3` on a 4000pt canvas is a 12000px-tall image. Drop the
ratio to 1 for very tall pages unless you're specifically checking rendering
at density.

Insets are zeroed deliberately — a 4000pt canvas is not a phone, so the safe
area means nothing here. Check safe-area behaviour on a real device preset
instead.

### Framing a data-shape golden instead

The tall device is for the *composition* golden. A golden about one region
reads better framed on that region — same phone device, scrolled into view:

```dart
goldenTest(
  name: 'FeatureScreen - no end date',
  action: (tester) async {
    await tester.scrollUntilVisible(find.byKey(const Key('dateChip')), 300);
    await tester.pumpAndSettle();
  },
  setup: (_) async => _stub(_items(start: _t(10, 0), end: null)),
  builder: (_) => build(),
);
```

When the screen has nothing to scroll — content shorter than the viewport,
or no scrollable at all — raise the height and say why, so the next reader
doesn't undo it:

```dart
goldenTest(
  name: 'FeatureScreen - sparse item',
  // Taller than a phone: with most fields absent the page still doesn't
  // scroll, so there is nothing to scroll *to* — the whole state fits in
  // one frame and this is the smallest height that holds it.
  supportedDevices: [
    const Device.iphone15Pro().copyWith(name: 'tall', height: 1400),
  ],
  setup: (_) async => _stub(_items(imageUrl: null, subtitle: null, end: null)),
  builder: (_) => build(),
);
```

Pick the height from the content, not from a round number. If the bottom
third of the PNG is empty background, it was a guess — bring it down.

## Stress variants

Each of these is **one extra golden on the richest state**, not an axis
across every state — a layout bug visible in the success state is visible
in all of them.

### Safe-area stress

```dart
goldenTest(
  name: 'FeatureScreen - safe area variants',
  supportedDevices: const [
    Device(name: 'standard', width: 390, height: 844,
        insets: EdgeInsets.only(top: 44, bottom: 34), devicePixelRatio: 3),
    Device(name: 'no-insets', width: 390, height: 844,
        insets: EdgeInsets.zero, devicePixelRatio: 3),
    Device(name: 'large-insets', width: 390, height: 844,
        insets: EdgeInsets.only(top: 100, bottom: 100), devicePixelRatio: 3),
  ],
  supportMultipleDevices: true,
  builder: (_) => const FeatureScreen(),
);
```

`large-insets` is deliberately more extreme than any real device — the point
is to catch layout code that assumes a maximum inset, not to model a phone.

### Tight layout

Shrink a real preset rather than inventing an arbitrary tiny size; it stays
representative of an actual form factor while forcing overflow.

**Only the constrained dimension is the stress.** For a horizontal overflow
that's the width — shrinking the height too just crops the page, and you can
end up with a frame containing none of the text that was supposed to
overflow: a golden that passes forever and tests nothing. Squeeze the
dimension under test, size the other one to the content.

```dart
goldenTest(
  name: 'FeatureScreen - tight layout',
  supportedDevices: [
    Device.iphone15Pro().copyWith(
      name: 'tight',
      width: Device.iphone15Pro().width * 0.7,
      height: Device.iphone15Pro().height * 0.7,
    ),
  ],
  builder: (_) => const FeatureScreen(),
);
```

RTL belongs here **only if the app ships an RTL locale** — see SKILL.md §4.

### Large text

```dart
goldenTest(
  name: 'FeatureScreen - large text',
  // At 2.0 the content roughly doubles; a phone-height canvas would show a
  // heading and nothing else. Size to the scaled content, then trim.
  supportedDevices: [
    const Device.iphone15Pro().copyWith(name: 'tall-xl', height: 8000),
  ],
  supportedTextScales: [AndroidFontScale.maximum.value],
  builder: (_) => const FeatureScreen(),
);
```

A single value in `supportedTextScales` adds no scale segment to the golden
path; two or more do (`.../2x/...`).

---

## Fixture conventions

- Build fixtures with **dedicated helpers** at the bottom of the file:
  `_items()`, `_buildState()`. Never inline literals scattered through
  `setup:` blocks.
- Match the fixture to the conversion the code performs. For UI that calls
  `.toLocal()`, a local **`DateTime(2024, 1, 1)`** is stable and
  `DateTime.utc(...)` makes the golden depend on the runner's timezone. For
  code converting into a fixed zone (`TZDateTime`, a Warsaw/UTC helper) or
  reassembling an instant from UTC components, it's the other way round.
  Check, then leave a comment saying which and why.
- Exercise long strings, large numbers and overflow-prone content in the
  success fixture; it's free coverage on a golden you're taking anyway.
- Keep fixtures stable. A fixture derived from `DateTime.now()`, a random
  id, or a locale-dependent format makes the golden fail on a schedule.

---

## Anti-patterns

- Driving the real state object through business logic (`emit()`,
  `notifyListeners()` from a real reducer, an actual repository call)
  instead of stubbing the state.
- A mock instantiated once at file scope and reused — stubs leak into later
  goldens. Fresh instance in `setUp`.
- Service-locator registrations without `pushNewScope`/`popScope`.
- `Future.delayed` / `.timeout()` — non-deterministic.
- Instantiating the screen without mocking when `initState` triggers
  network calls.
- One golden trying to capture "everything" on a complex screen — split by
  state.
- RTL, tight-layout and large-text as axes across every state instead of one
  golden each on the richest state.
- Snapshotting a state the product cannot render — an RTL golden in an app
  with no RTL locale, a dark-mode golden for a screen that forces light.
  Permanent maintenance cost, zero coverage.
- Shrinking a fixture until an overflow stops failing. That converts a bug
  report into a golden asserting the bug is absent.

## Skipping a state the app cannot render

An overflow still produces a screen. Sometimes the state simply throws — a
null-check on data the screen doesn't guard, a crash from a dependency
boundary — and no golden is possible until the app is fixed.

Don't delete the test, and don't reshape the fixture until the crash goes
away (that quietly redefines the state as one that works). Keep it in the
file, skipped, with the bug and the un-skip condition named:

```dart
goldenTest(
  name: 'FeatureScreen - contact without a display name',
  // BLOCKED: detail_header.dart:29 force-unwraps `contact.name`, which the
  // summary row guards as nullable. Un-skip once that null is handled.
  skip: true,
  setup: (_) async { /* ... */ },
  builder: (_) => const FeatureScreen(),
);
```

The suite stays green, the gap is visible in the source rather than absent
from it, and whoever fixes the bug finds the test waiting. Say so in the PR
too — a skipped golden nobody mentions is a deleted golden with extra steps.
