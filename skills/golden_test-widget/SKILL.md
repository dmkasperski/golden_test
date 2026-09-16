---
name: golden_test-widget
description: >-
  Write Flutter golden (screenshot) tests for widgets and design-system
  components in isolation using the golden_test package. Use when adding
  component goldens, DS showcases, bottom sheet content, or widget-level
  visual regression tests.
---

# Flutter Golden Tests — Widgets & Components

Snapshots of **isolated widgets**. A widget golden treats the component as
a black box: give it every input it can receive, screenshot what it draws.
No device chrome, no navigation, no locale sweep. For full screens use
`golden_test-route`.

Assumes `flutter_test_config.dart` exists — if not, run `golden_test-setup`
first.

## 1. API shape

```dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';

void main() {
  goldenTest(
    name: 'MyChip - variants',
    supportedDevices: [const Device.noInsets()],
    builder: (_) => const MyChip(label: 'Label'),
  );
}
```

Full signature — `name` and `builder` required, everything else optional:

```dart
goldenTest(
  name: 'string used verbatim as the filename',
  builder: (BuildContext context) => widget,
  supportedDevices: <Device>[...],      // overrides global
  supportMultipleDevices: false,         // true → goldenTestSupportedDevices
  supportedThemes: [Brightness.light],   // overrides global
  supportedLocales: [Locale('en')],      // overrides global
  supportedTextScales: [1.0, 1.5],       // overrides global
  localizationsDelegates: [...],
  setup: (WidgetTester tester) async {},     // before build
  action: (WidgetTester tester) async {},    // after first settle, before shot
  tearDown: (WidgetTester tester) async {},  // after shot
  subdirectory: 'design_system',         // inserted after 'goldens/'
  tags: 'golden_test',
  skip: false,
);
```

No `disableAnimations` parameter exists — see §10 for infinite animations.

## 2. When to write one

**Write**: DS components, reusable feature widgets, dialog/bottom-sheet
content, anything with a visual variant matrix, responsive behaviour.

**Skip**: pure logic (unit test), full screens with many state variants
(`golden_test-route`), copy-only churn, mid-animation frames.

## 3. Device: `noInsets` by default

**Every widget golden runs on `Device.noInsets()`.** A component doesn't
know it's on a phone — status bars, notches and home indicators aren't part
of what it renders, so including them means the golden fails when the
*frame* changes rather than when the component does.

```dart
supportedDevices: [const Device.noInsets()],
```

Two exceptions, and only these two:

**Screen-shaped widgets** — bottom sheets, modals, dialogs, snackbars, a
`Scaffold` with an app bar. Anything whose own job involves safe areas or
the bottom inset. Use a real preset; the chrome is the point.

**Widgets that reflow** with available width or height — a responsive card,
a grid that changes column count. Test at several sizes, **still without
insets**, since width is what's under test:

```dart
supportedDevices: const [
  Device(name: 'narrow', width: 320, height: 900),
  Device(name: 'wide', width: 900, height: 900),
],
supportMultipleDevices: true,
```

Presets: `Device.noInsets()`, `.iphone15Pro()`, `.pixel9ProXL()`,
`.ipadPro12()`, `.browser()`. `Device(name:, width:, height:,
devicePixelRatio:, insets:)` and `.copyWith(...)` cover the rest.

`noInsets()` is 393x852 at ratio 3 — a 1179x2556 PNG. That cost drives §4.

## 4. Axes multiply files; combinations fit in one file

The distinction that governs everything below:

- **Axes** (locales × themes × devices × text scales) multiply the number
  of PNGs. Four axes at two values each is 16 files for one component.
- **Combinations** (variants, flags, optional props, content shapes) can
  live side by side *inside a single* golden.

So: be frugal with axes, exhaustive with combinations. Adding a prop
combination to an existing showcase costs a few hundred pixels; adding an
axis costs another full set of megapixel images and another set of diffs to
review.

| Axis | Default for a widget | Turn it on when |
|---|---|---|
| **Devices** | one, `noInsets` | the widget reflows (§3) — still `noInsets` |
| **Locales** | one | the widget is genuinely locale-specific. Text length is *not* — cover that as content variants (§5), where each case is deliberate rather than dependent on a translator's phrasing |
| **Themes** | both | always, unless the component provably has no dark variant |
| **Text scales** | one | the widget holds text |

**RTL — only if the app ships an RTL locale.** Check the supported locales
for `ar`, `he`, `fa`, `ur` or similar first. If the app ships only
left-to-right languages, no user will ever see the component mirrored, and
an RTL golden is a file that can never catch a real regression while still
failing every time the layout changes. This is the general rule for every
variant below: *don't snapshot a state the product cannot render.*

When the app does ship RTL, it's cheaper as a variant than an axis: one
`Directionality`-wrapped golden, for components whose layout is directional
(icon placement, row order, asymmetric padding). Skip it even then for
symmetric or icon-only components.

Text scale is the axis most worth paying for — it's where overflow shows
up, and a component is the cheapest place to catch it:

```dart
supportedTextScales: [1.0, AndroidFontScale.maximum.value],
```

`AndroidFontScale` / `IosDynamicTypeScale` ship with the package; prefer
their `.value` over bare doubles so the golden names the real OS setting.

**Scoping the locale axis without per-call boilerplate:** a
`flutter_test_config.dart` inside `test/design_system/` applies to that
subtree, so the narrow locale list can be set once there instead of on
every call. It **replaces** the root config rather than layering on it, so
extract the shared wiring (fonts, theme, delegates) into a helper both
configs call.

## 5. Cover every combination

A component's inputs are a finite, enumerable list — unlike a screen, whose
state space is unbounded and where you pick representative slices. Enumerate
them:

- **Enum-driven looks** (variant, size, status) — every value.
- **Optional props** (leading icon, trailing action, badge) — every
  present/absent combination, not one representative each. A trailing action
  that breaks only when there's *also* a leading icon is exactly the
  regression these tests exist to catch.
- **Boolean flags** (disabled, selected, loading) — every combination with
  the above, including the ones that look redundant.
- **Content shapes** — short, long-enough-to-wrap, multiline, single
  character, empty, large number, unbreakable word. This replaces a locale
  sweep (§4).
- **Every branch in the component's own formatting code.** The constructor is
  only half the enumeration; the other half is inside the widget:

  ```dart
  if (subtitle != null) Text(subtitle!),        // ← two cases
  Text(count == 0 ? 'None yet' : '$count'),     // ← two cases
  if (end != null && _sameDay(start, end)) ...  // ← a relation
  ```

  Three kinds, in increasing order of how often they're missed: **absent
  fields** (null or empty — and check whether the code treats those two the
  same); **sentinel values**, a magic value the type doesn't advertise, like
  `-1` meaning free or `0` meaning unlimited, findable only by reading the
  code; and **relationships between fields** — a start and end on the same
  day, a discount equal to the full price, a value past the threshold where
  its unit changes. The last are highest value, because no single field
  looks interesting on its own.

  **Bound it.** One row per distinct *rendering*, not per input value — if
  `null`, `-1` and `0` all render an em dash, that's one row, not three.
  Skip branches that don't change pixels. Don't pair independent shapes
  against each other; a missing subtitle and a free price don't interact.
  Rows in a showcase are cheap, so enumerate more freely here than a screen
  would. The check is the first rule applied honestly: **would these two
  rows render the same?** If yes, one row — and say so in the label
  (`'-1' renders as null does`) so the next reader doesn't re-add it. If no,
  keep both, however similar they look; two rows differing by one character
  is exactly what a branch looks like.

  Name these after the data condition — `free of charge`, `subtitle missing`
  — not after the widget. `references/patterns.md` works each kind through in full.

If the cross-product is genuinely unmanageable, that's a finding about the
component, not licence to thin the coverage: a widget with that many
independent visual inputs is usually two widgets.

### Put them in one labeled golden

Default to **one image holding every combination, each row labeled**:

```dart
for (final variant in MyButtonVariant.values)
  for (final enabled in const [true, false]) ...[
    Text('${variant.name} / ${enabled ? 'enabled' : 'disabled'}',
        style: const TextStyle(fontSize: 11, color: Colors.grey)),
    MyButton(variant: variant, onTap: enabled ? () {} : null),
    const SizedBox(height: 16),
  ],
```

Full runnable version, including the showcase `Device` sizing, in
`references/patterns.md`.

Two reasons, and the second is the load-bearing one:

1. A reviewer sees the whole component in one image and spots the odd one
   out. Twenty separate PNGs get opened one at a time and compared from
   memory.
2. It's what makes exhaustive coverage affordable — one file and one
   comparison instead of forty, against a per-golden cost of §3's 1179x2556.

Size the custom `Device` to fit the content; a showcase that scrolls off the
bottom silently loses the variants below the fold. Split into separate
goldens only when combining is what makes the image unreadable:

- Already multiplied across a matrix (both themes × three scales × a long
  variant list) and the combined image becomes a wall.
- A state needs `action:` to reach — focus, text entry, expansion — since
  one `action:` drives one tree.
- Layout shifts so much between states that stacking tells you nothing.

## 6. Patterns

Full runnable code for each in `references/patterns.md`.

- **Labeled showcase** — §5's default.
- **Per-state goldens** — `action:` to reach focus/entered text/expansion.
- **Stateful controller wrapper** — `goldenTest` rebuilds the tree per
  device, so own any `TextEditingController` / `FocusNode` /
  `ScrollController` inside a small `StatefulWidget`, never a shared
  instance.
- **RTL variant** — one `Directionality` golden, only when the app ships an
  RTL locale (§4).
- **Reusable harness** — one thin helper for ambient setup every component
  test needs. A harness accumulating business logic means the component
  needs its own testing seam.
- **State management** — inject a mocked state however your project does
  DI. `references/patterns.md` has interchangeable BLoC/Cubit, Riverpod, Provider and
  plain `ChangeNotifier` examples.

## 7. Lifecycle hooks

```
setUpAll → setUp → setup: → build + settle → action: → 📸 → tearDown: → tearDown → tearDownAll
```

`setup:` / `action:` / `tearDown:` are `goldenTest` parameters scoped to one
golden; the rest are `flutter_test`'s group-level hooks.

| Hook | Use it for |
|---|---|
| `setUpAll` | Expensive, immutable, shareable: a loaded fixture file, `registerFallbackValue`. Never mutable state — one test corrupting it breaks the rest in order-dependent ways. |
| `setUp` | The shared baseline: fresh mocks, DI registration, the default happy-path stub. |
| `setup:` | Only what's *different* about this variant, plus anything that must be in effect before first build. |
| `action:` | States needing interaction — `enterText`, `tap`, `drag`, focus. Follow with `pump`/`pumpAndSettle`. |
| `tearDown:` | Undoing what `setup:`/`action:` did that outlives the tree — an overridden global, a static singleton, a channel handler. |
| `tearDown` | Disposing what `setUp` created: closing a bloc, `getIt.popScope()`, resetting mocks. |
| `tearDownAll` | Releasing `setUpAll` resources. Rarely needed. |

**A component can reach into DI too.** Don't assume only screens resolve
dependencies — a card that formats a distance or a timestamp may call a
service locator during its own `build`. Read the widget tree you're about
to snapshot, not just the widget's constructor, and register what it
reaches for in `setUp`.

**`setUp`/`tearDown` must pair up.** A test that mutates shared state with
nothing undoing it passes alone and fails in a full run — the hardest golden
failure to diagnose, because the image is wrong for a reason that isn't in
the test that produced it.

## 8. When a golden fails

The message gives both numbers: `Pixel test failed, 0.11%, 3362px diff
detected.` Four images land in `failures/`, next to the test:

| File | What it is |
|---|---|
| `<name>_masterImage.png` | the committed golden |
| `<name>_testImage.png` | what the code renders now |
| `<name>_isolatedDiff.png` | **only** the differing pixels — read this first |
| `<name>_maskedDiff.png` | the diff overlaid on the image |

`_isolatedDiff` answers the only question that matters in one look:

- **Readable shapes, solid regions, text, a shifted element** → a real
  change. If you caused it, regenerate. If you didn't, it's a regression.
- **Scattered speckle along anti-aliased edges, identical image
  dimensions** → cross-machine rasterisation noise. Fix the environment
  (same OS/Flutter/fonts as whoever generated them), don't paper over it.
- **A size mismatch** → the comparison aborts before diffing; the device
  config or the content changed shape.

Then:

```bash
flutter test path/to/widget_test.dart --update-goldens
```

Never commit `failures/` — it's build output.

**Deleting or renaming a test orphans its PNG.** `--update-goldens` only
writes files, it never removes them, so the old image stays in the repo
forever — passing nothing, reviewed by no one, and indistinguishable from a
real golden. Delete it by hand in the same commit, and check for strays
after a rename: the new name generates a new file beside the old one.

### An overflow is a bug report, not a golden

`RenderFlex overflowed` **throws**. The test fails with an exception, no
image is written, and `--update-goldens` cannot help you — there is nothing
to regenerate. This is the expected outcome of the text-scale axis (§4)
doing its job, so don't read it as a broken test:

- **Fix the widget** if you can. That's the whole point of having found it.
- **If you can't fix it now**, don't tune the fixture until the overflow
  disappears — that deletes the evidence and leaves a golden that asserts
  the bug is absent. Narrow the axis to the largest scale that passes, and
  file the overflow with the scale that triggers it.
- A failed `--update-goldens` run still creates the scale directory before
  the test throws, so delete the stray empty `goldens/<n>x/` folder it
  leaves behind.

A widget that overflows at large text is an accessibility bug in the app,
not a golden-testing problem.

**Finding the threshold.** `goldenTest` can't tell you the largest scale
that still renders, and a failing scale produces no image to inspect — so
binary-search it in a throwaway file, then delete it:

```dart
// scratch_scale_probe_test.dart — delete once you have the number
for (final scale in const [1.0, 1.15, 1.3, 1.5, 1.8, 2.0]) {
  goldenTest(
    name: 'probe $scale',
    supportedTextScales: [scale],
    builder: (_) => const MyWidget(),
  );
}
```

The scales that throw are your bug report; the largest that passes is the
axis you ship.

### A state that cannot render at all

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

### A `StateError` deep in a build is DI, not pixels

If a test throws from inside `build` with no image produced — an
unregistered service-locator type, a null provider — the widget tree
resolved a dependency you didn't stub. Leaf widgets do this as readily as
screens do (§7). Nothing about it is a golden failure; read the stack, not
the diff.

If the project configured `goldenTestDifferenceTolerance`, a real change
smaller than it passes silently. Green is not evidence the goldens still
match: **if the UI changed, regenerate regardless of whether the suite
failed.** Otherwise small real diffs accumulate under the threshold and eat
the headroom meant for platform noise.

## 9. Network images need no mocking

**2.x only** — on 1.x nothing is stubbed and a URL in the tree hangs; see
`golden_test-setup` §6.

`golden_test` stubs `NetworkImage` by default, so a component taking a URL —
an avatar, a thumbnail, a `DecorationImage` — renders a deterministic
checkerboard placeholder instead of hanging. No `HttpOverrides`, no
`debugNetworkImageHttpClientProvider`, no per-test mock `ImageProvider`.

- The placeholder is a fixed image: it exercises size, fit, clipping and
  border radius, but says nothing about the real asset. A component whose
  *look* depends on image content needs a local asset fixture.
- Loading and error states can't be captured — the stub always succeeds
  immediately. Inject a custom `ImageProvider` for those.
- Packages with their own loader (`cached_network_image` and friends) never
  touch `NetworkImage` and are wired once in `flutter_test_config.dart` —
  `golden_test-setup` §6, not here.

## 10. Non-negotiables

- **Zero insets** unless the widget is screen-shaped (§3). `Device.noInsets()`
  is the default; a custom showcase `Device` (§5) also qualifies — what
  matters is that no device chrome is in the frame, not which constructor
  you used.
- **Both themes explicitly** — don't inherit whatever global config happens
  to be.
- **One locale.** Cover text length through content variants (§4).
- **Label every variant** in a showcase — an unlabeled grid is unreviewable
  six months later. Labels are **test scaffolding, not app content**: write
  them in English (or whatever the team reviews code in) regardless of the
  app's locale, and describe the *case* rather than what the user sees —
  `no thumbnail`, `price: free`, `title wraps to 2 lines`. A showcase
  captioned in the product's language is unreadable to half the people
  reviewing it, and the label is for them, not for a user. Keep labels to
  characters the bundled font covers; an arrow or bullet renders as tofu for
  the same reason app text does (`golden_test-setup` §4).
- **Stateful wrapper** for any `TextEditingController` / `FocusNode` /
  `ScrollController`.
- **Stop infinite animations at the source.** `goldenTest` always ends with
  `pumpAndSettle()` and has no opt-out, so a shimmer or Lottie loop that
  never completes times the test out. Wrap in `TickerMode(enabled: false,
  child: ...)`, or have the app skip the animation via a flag set in
  `globalSetup`.
- **No `Future.delayed` / `.timeout()`** — use `action:` + `pump` /
  `pumpAndSettle`. To flush a microtask without advancing animation time,
  `pumpEventQueue()` beats an extra blind `pump()`.
- **Realistic test data** — factory helpers (`_mockItem()`), not inline
  literals.
- **Regenerate whenever the UI changed**, even if the suite passed (§8).

## 11. File structure & naming

- Mirror the source path: `lib/design_system/atoms/my_chip.dart` →
  `test/design_system/atoms/my_chip_test.dart`. Goldens land in a `goldens/`
  folder beside the test file.
- Test name: `'ComponentName - variant description'`, used verbatim as the
  filename.
- One `group('ComponentName', ...)` per file — even for a single golden
  today, since a second almost always follows. Split unrelated concerns into
  sibling groups with their own `setUp()`.
- Shared fixtures and DI harnesses go in `test/fixtures/` and
  `test/helpers/`, not duplicated per test file — a second file needing the
  same entity factory is the signal to lift it out. Keep per-file helpers
  local; lift only what two files actually share.
- `subdirectory:` separates goldens when one folder serves several apps or
  packages: `subdirectory: 'design_system/buttons'` →
  `goldens/design_system/buttons/en/light/MyButton - variants.png`.

## 12. Running tests

```bash
flutter test test/path/to/widget_test.dart --update-goldens  # generate
flutter test test/path/to/widget_test.dart                   # verify
```

**Then run it again without `--update-goldens`.** A golden that passes when
written and fails on the very next run is non-deterministic — a fixture
built from `DateTime.now()`, a real clock or locale, an unseeded shuffle, an
animation that hadn't settled. Regenerating hides it until it fails on
someone else's machine or in CI; fix the source of the variance instead.
Two commands, and it catches the whole class at the moment you introduced it.

Commit the PNGs alongside the test file. Tag golden tests
(`tags: 'golden_test'`) so CI can split a fast unit run from the visual
suite: `--exclude-tags=golden_test` vs `--tags=golden_test`.

## Reference

[`references/patterns.md`](references/patterns.md) — device sets, the full labeled showcase and
content-shape examples, stateful wrapper, Riverpod / Provider /
ChangeNotifier equivalents, RTL, harness, bottom sheets, and the golden
output path structure.
