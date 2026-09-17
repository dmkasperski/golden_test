---
name: golden_test-route
description: >-
  Write Flutter golden tests for full screens — every visual state a screen
  can render (loading, success, error, empty, scrolled, and domain-specific
  variants). Use when adding screen-level goldens or visual regression for
  navigation destinations — not isolated DS components (use
  golden_test-widget for those).
---

# Flutter Golden Tests — Screens & Routes

Full-screen snapshots of the states a screen can render. For isolated
components use `golden_test-widget`.

Assumes `flutter_test_config.dart` exists — if not, run
`golden_test-setup` first.

Nothing here assumes a particular state-management library; use whatever the
project already uses to get the screen into a given state.

## 1. API shape

```dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';

void main() {
  group('FeatureScreen', () {
    goldenTest(
      name: 'FeatureScreen - Loading',
      setup: (_) async {
        // stub whatever state the screen reads (§3)
      },
      builder: (_) => const FeatureScreen(),
    );
  });
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
  subdirectory: 'feature/cards',         // inserted after 'goldens/'
  tags: 'golden_test',
  skip: false,
);
```

No `disableAnimations` parameter exists — see §9 for infinite animations.

## 2. When to write one

**Write**: navigation destinations, screens with several visual states,
anything where a regression would ship a broken page.

**Skip**: isolated components and design-system widgets
(`golden_test-widget`), pure logic (unit test), screens that are one
static column of text and never change.

## 3. Get the screen into each state

**Stub state directly, as shallow as the screen allows.** Don't drive the
screen through real business logic, network calls, or storage just to reach
a visual state. Only fake a repository/service if the screen still reaches
it during build or first frame.

| Pattern | When to use |
|---|---|
| **Constructor param** | Screen exposes a state/data param for testing |
| **State-management override** | Inject a stub through whatever the app already uses — a Cubit/BLoC instance, a Riverpod override, a Provider value, a plain `ChangeNotifier` |
| **Service-locator / DI override** | Something in the tree resolves a dependency itself (GetIt, a manual locator, a singleton) during build — **including leaf widgets**, not just the screen: a card that formats a distance or a timestamp may reach the locator on its own. Read the tree you're snapshotting, not just the screen's constructor |
| **Static screen** | No state management — build it directly |

Rule of thumb either way: stub the **state**, not the plumbing that produces
it. If a screen has no seam for injecting a pre-built state, adding one is
usually worth it — it makes every pattern here unnecessary.

Copy-pasteable recipes for Cubit/BLoC, Riverpod, Provider, plain
`ChangeNotifier` and a service locator are in `references/patterns.md`. Pick one,
ignore the rest.

## 4. States are the unit; axes multiply them

The economics are the opposite of a component test. A component's variants
stack inside one image, so you enumerate them exhaustively. **A screen state
is a whole screenshot — nothing combines.** Each state is its own golden, at
1179x2556 for a typical phone preset, and every axis multiplies the entire
state list:

```
6 states                    →  6 goldens
6 states × 2 themes         → 12
      × 2 devices           → 24
      × 2 locales           → 48
```

So: **enumerate states deliberately, and be stingy with axes.** The
checklist below is a prompt to weigh against the screen in front of you, not
a quota — a static settings screen needs far less than a checkout flow.

### Core states — every screen

- [ ] **Loading** — if it has visually distinct sub-phases (an initial
      spinner vs. a later "still working" message), capture each one that
      actually looks different, not every internal step.
- [ ] **Success** with representative data (factory helpers, not inline
      literals)
- [ ] **Error**
- [ ] **Empty** — the success state with an empty collection

### Conditional states — when the screen has them

- [ ] **Data-shape states** — every branch in the rendering code that changes pixels: absent fields, sentinel values, relationships between fields (see below). Usually the largest and most valuable group
- [ ] **Domain variants** — tabs, filters, expanded/collapsed sections, and
      tiers/roles/plans when they change the visuals meaningfully (a
      loyalty-tier badge, an admin-only banner, a plan-gated section)
- [ ] **Flagged variants** — one golden per feature flag or kill switch that
      changes this screen, against a baseline (see below). Not a matrix
- [ ] **Form edge cases** — invalid input, boundary-length input, an empty
      required field
- [ ] **Scrolled to bottom** — on a short device (§5). For *content* coverage prefer a tall device (above); keep a scrolled golden for what scrolling itself changes — a collapsing header, a sticky bar, a trailing spinner
- [ ] **Pushed-route chrome** — if a back arrow or close affordance appears
      only when `Navigator.canPop(context)` is true, wrap in
      `simulateRouteStack(...)` (`references/patterns.md`)

### Data-shape states — read the formatting code

The core states above come from the *state machine*, and four goldens is
where most suites stop. The states that actually catch regressions come from
the **data**: the same `success` state rendered with a field missing, a
sentinel value, or two fields in an unusual relationship.

These aren't product trivia you need a spec for — they're branches in the
presentation code, and you can read them:

```dart
if (item.subtitle != null) Text(item.subtitle!),   // ← two states
Text(count == 0 ? 'None yet' : '$count items'),    // ← two states
if (end != null && _sameDay(start, end)) ...       // ← a relation
```

**The procedure.** Before writing the success golden, open the widgets the
screen renders and find every conditional that changes pixels — `if`, `??`,
a ternary inside a `children:` list, `switch`, `.isEmpty`, a null check, a
comparison between two fields. Each branch is a candidate golden; build a
fixture that reaches it.

Three kinds, in increasing order of value and of how often they're missed:
**absent fields** (nullable or empty — watch for code where `null` and `''`
diverge); **sentinel values** (a magic value the type doesn't advertise —
`-1` meaning free, `0` meaning unlimited — findable only by reading the
code); and **relationships between fields** (a start and end on the same
day, a discount equal to the full price, a value past the threshold where
its unit changes), which are highest value and most often missed because no
single field looks interesting alone. `references/patterns.md` works each
through with fixtures and golden names.

**Bound it — the goal is distinct renderings, not coverage of inputs.**

- **One golden per distinct rendering, not per input value.** If `null`,
  `-1` and `0` all render an em dash, that is *one* case. Test the branch,
  not the value that reaches it.
- **Don't cross-product independent shapes.** A missing subtitle and a free
  price don't interact; cover each once rather than every pairing. Combine
  only where branches actually meet — two collapses that leave a container
  with nothing in it.
- **Skip branches that don't change pixels** — a different semantic label,
  an analytics call, a value that formats identically either way.
- **Bundle, because a screen golden is a whole PNG.** One fixture can carry
  several unrelated shapes at once (a missing header image *and* an empty
  section further down) and still be one image to review. Split them only
  where you need to isolate a failure, or where the shapes interact.

The check is the first bullet, applied honestly: **would these two fixtures
produce the same image?** If yes, they're one golden. If no, they're two —
even when the difference is one chip in one corner, and even when that chip
is where another golden already varies. Four renderings of a date formatter
are four goldens; four *inputs* that produce three renderings are three.

Don't reach for "they look similar" as a reason to cut. Screen goldens
mostly look similar to each other; that's what screens are. A screen with
thirty data-shape goldens is a sign you enumerated inputs rather than
renderings — go back to the four rules above, not to deleting distinct
renderings.

Name these after the data condition rather than the widget: `no end date`,
`free of charge`, `same-day range`, `subtitle missing`. A reviewer then
knows what broke without opening the image.

**One tell worth chasing.** Where one widget guards a field and another
doesn't — a summary row that handles a null name, and a detail row three
files away that force-unwraps it — the unguarded one is a crash, not just a
missing golden. The fixture you were about to write is the reproduction.

`references/patterns.md` has a worked example of each of the three kinds: the branch,
the fixtures that reach it, and the goldens that come out.

### Feature flags, kill switches and experiments

A flag is not an axis. Sweeping every combination is how a screen with five
flags acquires thirty-two goldens, most for states no user is in.

**Start from a baseline: the flags as production has them right now** — not
the code defaults, not everything off. That's the app users have, and where
a regression costs most. Set it in `setUp()` and write down what it is.

Then **one golden per flag, flipped away from that baseline**, and only for
flags that change *this* screen. Five flags means six goldens. Don't
cross-product: two flags gating unrelated regions tell you nothing together
that they didn't apart. Combine only where one genuinely changes the
other's rendering.

**A kill switch's tripped state is the highest-value golden on the screen**
— it's the branch nobody looks at until the day it matters, and that day is
an incident. Snapshot the degraded layout now, while you can look at it
calmly.

Two things keep this from rotting: a flag that doesn't change pixels gets no
golden, and **when the baseline moves, move the goldens with it** — a flag
rolled out to 100% and deleted means regenerating the baseline and deleting
the now-unreachable variant.

Baseline in `setUp()`, the single flip in that golden's own `setup:`. Worked
example, and the same reasoning for A/B arms and remote config, in
[`references/patterns.md`](references/patterns.md).

### Size each golden to what it is testing

A phone-sized device captures one screenful; a tall device captures
everything. Neither is right for every golden — choose per test, from what
the test is actually about.

**A full-page golden** — "does the whole screen still compose?" — wants the
height the content needs. Without it, the `loaded` golden compares a hero
image and a heading while the price, description, location and related
content below the fold are never compared against anything.

Keep the real width — layout depends on it — and raise only the height.
Always pass `name:`; it becomes the golden's path segment.

**Pick the pixel ratio deliberately.** It multiplies file size quadratically
and nothing warns you: the same frame at ratio 3 is nine times the bytes of
ratio 1. Use the device's real ratio when rendering fidelity is the point
(a component showcase, anything with hairlines or shadows). Drop to 1 for
tall composition goldens, where you're checking that the page assembles and
a 4000pt canvas at ratio 3 is a 12000px image nobody will zoom into. Note
that re-framing a golden onto a real phone preset can make the file *larger*
even as the frame gets smaller, because the ratio went up.

**A data-shape golden** — "does this one region render correctly in this
case?" — wants that region *framed*, not the whole page. A 4000pt image
whose only point of interest is one date chip is hard to review: the reader
has to hunt for the difference, and a reviewer who doesn't know the screen
won't find it at all. Work down this list:

1. **Already in the first viewport** — use the default device. Nothing to do.
2. **Below the fold** — scroll to it with `action:` and keep the device
   phone-sized. The golden then shows the region, in context, at a size
   someone can actually read:

   Use `action:` with `scrollUntilVisible` — recipe in
   [`references/patterns.md`](references/patterns.md). Most widgets have no
   `Key`, so reach for `find.byType` or a text finder first. Adding a `Key` to production code purely so a test can scroll to
   it is a real cost — fine if the widget is hard to find another way, not
   something to do by reflex.
3. **Scrolling can't isolate it** — not scrollable, or content shorter than
   the viewport. Raise the height, and comment why, so nobody "fixes" it
   back to a phone.
4. **The region is taller than the viewport** — raise the height until it
   fits. Clipping the thing under test is worse than a tall image.

**Then check the image — both ends of the mistake.** Open the PNG:

- **Is the subject fully visible?** Too short clips it, and the suite stays
  green either way: a clipped golden passes, and keeps passing. This is the
  failure the runner will never tell you about.
- **Is there a strip of background below the content?** That strip is the
  proof nothing was cut. Aim for a visible margin, not a void — past roughly
  a quarter of the image the height was a guess.

Expect to do this two or three times: generate, open, adjust the number,
regenerate. There is no way to compute the right height up front, and no
tooling that checks it for you.

**Large text needs the most room.** At 2.0 the content roughly doubles, so a
phone-height golden can be a title and nothing else — exactly the states you
added the axis to inspect are the ones pushed off screen. Pair the scale
with a taller device, then trim as above.

Two things a tall device does *not* replace:

- **One real-device golden** of the same state. Viewport-dependent chrome —
  a collapsing app bar, a bottom action bar, safe-area padding — sits
  differently on a 4000pt canvas than on a phone, so the tall golden is the
  wrong place to check it.
- **Scrolled goldens** where scrolling itself changes something: a shrinking
  header, a sticky section header, a "load more" spinner at the bottom.
  Those capture behaviour, not just content.

### Axes — turn on deliberately

| Axis | Default | Turn it on when |
|---|---|---|
| **Themes** | both | always, unless dark mode isn't implemented for this screen |
| **Devices** | one | layout meaningfully changes per form factor — a tablet two-pane split, not a slightly wider phone |
| **Locales** | one | translated copy has real overflow risk in a tight layout |
| **Text scales** | one | the screen is text-heavy or tightly laid out |

### Stress variants — one representative state, not the whole matrix

These catch layout bugs, and a layout bug visible in the success state is
visible in all of them. Add each as **one extra golden on the richest
state** rather than as an axis across every state — and only where the
product can actually render it. *Don't snapshot a state the app cannot
reach:* an RTL golden in an app with no RTL locale is a permanent
maintenance cost against zero coverage.

- **RTL** — **only if the app ships an RTL locale** (`ar`, `he`, `fa`, `ur`
  …). Check the supported locales before writing this one: if the app ships
  only left-to-right languages no user ever sees the screen mirrored, so the
  golden cannot catch a real regression but still fails on every layout
  change.
  When the app does ship RTL, wrap the builder in
  `Directionality(textDirection: TextDirection.rtl, ...)` if layout is
  directional (icon placement, row order, alignment, asymmetric padding).
- **Tight layout** — shrink a real device preset by ~30% with
  `.copyWith(width: ..., height: ...)` to force overflow before an unusually
  small real device does.
- **Large text** — one golden at `AndroidFontScale.maximum.value` or similar,
  if you didn't turn on the text-scale axis. **Give it a tall device**: at
  2.0 a phone-height canvas shows a heading and little else.

## 5. Scroll & interaction actions

`action:` runs after the first settle, before the screenshot — that's where
you scroll, tap, enter text, or pull to refresh to reach a state the builder
alone can't produce. Follow every gesture with `pump`/`pumpAndSettle`.

Copy-pasteable recipes (scroll to bottom, tap to expand, scroll until
visible, pull to refresh) are in
[`references/patterns.md`](references/patterns.md).

## 6. Lifecycle hooks & isolation

```
setUpAll → setUp → setup: → build + settle → action: → 📸 → tearDown: → tearDown → tearDownAll
```

`setup:` / `action:` / `tearDown:` are `goldenTest` parameters scoped to one
golden; the rest are `flutter_test`'s group-level hooks.

| Hook | Use it for |
|---|---|
| `setUpAll` | Expensive, immutable, shareable: a loaded fixture file, `registerFallbackValue`. Never mutable state. |
| `setUp` | The shared happy-path baseline: fresh mocks, DI/provider registration, the "just works" stub most goldens need. |
| `setup:` | Only the one thing that differs for this state — re-stub the state, not the whole scenario. |
| `action:` | States needing interaction — scroll, tap, text entry (§5). |
| `tearDown:` | Undoing what `setup:`/`action:` did that outlives the tree — an overridden global, a static singleton. |
| `tearDown` | Disposing what `setUp` created: `getIt.popScope()`, closing a bloc, resetting mocks. |
| `tearDownAll` | Releasing `setUpAll` resources. Rarely needed. |

**Leaking stubs between goldens is the screen-level failure mode.** A
service locator registered in one test and never reset makes a later golden
render a state no `setup:` asked for — and the image is wrong for a reason
that isn't in the test that produced it. Scope registrations per test
(`getIt.pushNewScope()` in `setUp`, `popScope()` in `tearDown`) so
`setUp`/`tearDown` always pair up.

When a screen has distinct scenario clusters rather than a short list of
simple states — different account types, a multi-step flow, unrelated edge
cases — give each cluster a nested `group()` with its own `setUp()` layering
on the shared one. That scales better than one flat `setUp()` serving every
combination, or re-stubbing the same thing in every `setup:`.

## 7. When a golden fails

The message gives both numbers: `Pixel test failed, 0.11%, 3362px diff
detected.` Four images land in `failures/`, next to the test:

| File | What it is |
|---|---|
| `<name>_masterImage.png` | the committed golden |
| `<name>_testImage.png` | what the code renders now |
| `<name>_isolatedDiff.png` | **only** the differing pixels — read this first |
| `<name>_maskedDiff.png` | the diff overlaid on the image |

`_isolatedDiff` answers the question in one look:

- **Readable shapes, solid regions, a shifted element** → a real change.
  Regenerate if you caused it; it's a regression if you didn't.
- **Scattered speckle along anti-aliased edges, identical dimensions** →
  cross-machine rasterisation noise. Fix the environment, don't paper over
  it.
- **A size mismatch** → the comparison aborts before diffing; device config
  or content changed shape.

On a screen test, also suspect **leaked state** (§6) before assuming a UI
regression: if the diff shows a state this golden never stubbed, the
previous test is the culprit. Confirm by running the file alone — a failure
that disappears in isolation is a leak, not a regression.

Never commit `failures/` — it's build output.

**Deleting or renaming a test orphans its PNG.** `--update-goldens` only
writes files, it never removes them, so the old image stays in the repo
forever — passing nothing, reviewed by no one, and indistinguishable from a
real golden. Delete it by hand in the same commit, and check for strays
after a rename: the new name generates a new file beside the old one.

### No image at all? It isn't a golden failure

Two common cases produce an exception and **no PNG**, so there is nothing
to diff and `--update-goldens` cannot help:

- **`RenderFlex overflowed`.** Expected when the text-scale or tight-layout
  variants (§4) do their job. Fix the screen if you can; if you can't now,
  narrow the axis to the largest scale that passes and file the overflow —
  do **not** shrink the fixture until the overflow disappears, which
  deletes the evidence and leaves a golden asserting the bug is absent. A
  failed `--update-goldens` still creates the scale directory first, so
  remove the stray empty `goldens/<n>x/` folder.

  **Sometimes the largest passing scale is 1.0** — the screen overflows at
  every scale you'd want to test. There is then no axis left to narrow, and
  no golden. Don't force one: skip it with the bug named (below), and if you
  still want large-text coverage, take it on a simpler *real* state of the
  same screen (an empty collection, fewer sections) rather than inventing a
  fixture that exists only to fit.
- **A `StateError` from inside `build`** — an unregistered service-locator
  type or a null provider. Something in the tree resolved a dependency you
  didn't stub (§3). Read the stack, not the diff.

### A state that cannot render at all

An overflow still produces a screen. Sometimes the state simply throws — a
null-check on data the screen doesn't guard, a crash from a dependency
boundary — and no golden is possible until the app is fixed.

Don't delete the test, and don't reshape the fixture until the crash goes
away (that quietly redefines the state as one that works). Keep it in the
file with `skip: true`, and name the bug and the un-skip condition in a
comment beside it. The suite stays green, the gap is visible in the source
rather than absent from it, and whoever fixes the bug finds the test
waiting. Say so in the PR too — a skipped golden nobody mentions is a
deleted golden with extra steps. Worked example in
[`references/patterns.md`](references/patterns.md).

Comparison is pixel-exact unless the project configured
`goldenTestDifferenceTolerance` — most don't, and shouldn't. A real change
smaller than a configured tolerance passes silently, so green is not
evidence the goldens still match: **if the UI changed, regenerate
regardless.**

## 8. Network images need no mocking

**2.x only** — on 1.x nothing is stubbed and image URLs in the tree hang;
see `golden_test-setup` §6.

`golden_test` stubs `NetworkImage` by default, so a screen full of remote
avatars, thumbnails or hero images renders a deterministic checkerboard
placeholder instead of hanging on requests the runner never answers. No
`HttpOverrides`, no per-test mock `ImageProvider`.

Still needs stubbing the normal way: **other `dart:io` traffic** (a
repository call from `initState` still meets `flutter_test`'s mock client
and its 400 — stub the repository, §3); an **image widget's loading / error
branches** (the stub always succeeds immediately, so inject a custom
`ImageProvider` to reach them); and **packages with their own loader**
(`cached_network_image` and friends), wired once in
`flutter_test_config.dart` — `golden_test-setup` §6, not per test file.

## 9. Non-negotiables

- **Stub state directly** — never drive it through real reducers, notifiers,
  or business logic to reach a visual state.
- **Isolate DI/service-locator registrations per test** (§6).
- **Stop infinite animations at the source.** `goldenTest` always ends with
  `pumpAndSettle()` and has no opt-out, so a shimmer, spinner or Lottie loop
  that never completes times the test out. Wrap in `TickerMode(enabled:
  false, child: ...)`, or have the app skip the animation via a flag set in
  `globalSetup`.
- **No `Future.delayed` / `.timeout()`** — use `action:` + `pump` /
  `pumpAndSettle`. To flush a microtask (a repository call kicked off in
  `initState`) without advancing animation time, `pumpEventQueue()` beats an
  extra blind `pump()`.
- **Build each fixture as the same kind of instant the code under test reads.**
  The usual case is UI that calls `.toLocal()`, where a local
  `DateTime(2024, 1, 1)` is stable and `DateTime.utc(...)` makes the golden
  depend on the runner's timezone. But it inverts: code converting into a
  fixed zone (a `TZDateTime` / named-zone helper) or rebuilding an instant
  from UTC components wants `DateTime.utc(...)`, and a local fixture is the
  unstable one. Read the conversion before picking, and say which you chose in
  the fixture file.
- **Realistic fixtures** via factory helpers, not inline literals.
- **Regenerate whenever the UI changed**, even if the suite passed (§7).

## 10. File structure & naming

- Mirror the feature path: `lib/feature/ui/feature_screen.dart` →
  `test/feature/ui/feature_screen_test.dart`. Goldens land in a `goldens/`
  folder beside the test file:
  `test/feature/ui/goldens/en/light/FeatureScreen - Loading.png`.
- Test name: `'ScreenName - State description'`, used verbatim as the
  filename. `group('$FeatureScreen', …)` is a nice idiom — renaming the class
  renames the group for free — but **don't interpolate a type into
  `goldenTest(name:)`**: the name *is* the PNG filename, so a class rename
  silently renames every golden and orphans the old files.
- One `group('FeatureScreen', ...)` per file, with nested groups per
  scenario cluster (§6). Some codebases instead keep several topic groups as
  siblings in `main()` — either works, as long as tests aren't bare
  top-level calls.
- If the file also has non-golden widget/interaction tests, keep goldens
  under their own `group('golden tests', ...)` so they stay easy to spot and
  run selectively — or split them into a dedicated file.
- Shared fixtures and DI harnesses go in `test/fixtures/` and
  `test/helpers/`, not duplicated per test file — a second file needing the
  same entity factory is the signal to lift it out. Keep per-file helpers
  local; lift only what two files actually share.
- `subdirectory:` groups goldens by feature when one folder serves several
  features or apps: `subdirectory: 'feature/cards'` →
  `goldens/feature/cards/en/light/FeatureScreen - Loading.png`.

## 11. Running tests

```bash
flutter test test/path/to/feature_screen_test.dart --update-goldens  # generate
flutter test test/path/to/feature_screen_test.dart                   # verify
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

[`references/patterns.md`](references/patterns.md) — a full worked file covering every core
state, state-injection recipes (Cubit/BLoC, Riverpod, Provider,
ChangeNotifier, service locator), `simulateRouteStack`, RTL, safe-area and
tight-layout stress, fixture conventions, and anti-patterns.
