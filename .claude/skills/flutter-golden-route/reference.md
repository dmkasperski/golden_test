# flutter-golden-route — Reference

Full templates and patterns cited from `SKILL.md`. Read on demand.

## Full file template — Pattern A (constructor param)

```dart
import 'package:flutter/material.dart';
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
  final cubit = MockFeatureCubit();

  setUp(() {
    when(() => cubit.state).thenReturn(const FeatureInitial());
  });

  goldenTest(
    name: 'FeatureScreen - Loading',
    disableAnimations: true,
    setup: (_) async {
      when(() => cubit.state).thenReturn(const FeatureLoading());
    },
    builder: (_) => FeatureScreen(cubitForTesting: cubit),
  );

  goldenTest(
    name: 'FeatureScreen - Success',
    setup: (_) async {
      when(() => cubit.state).thenReturn(FeatureSuccess(items: _mockItems()));
    },
    builder: (_) => FeatureScreen(cubitForTesting: cubit),
  );

  goldenTest(
    name: 'FeatureScreen - Error',
    setup: (_) async {
      when(() => cubit.state).thenReturn(const FeatureError());
    },
    builder: (_) => FeatureScreen(cubitForTesting: cubit),
  );

  goldenTest(
    name: 'FeatureScreen - Empty',
    setup: (_) async {
      when(() => cubit.state).thenReturn(const FeatureSuccess(items: []));
    },
    builder: (_) => FeatureScreen(cubitForTesting: cubit),
  );
}

List<Item> _mockItems() => [/* realistic fixtures */];
```

---

## Pattern B — BlocProvider.value

```dart
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

---

## Pattern C — Riverpod

```dart
goldenTest(
  name: 'FeatureScreen - Success',
  builder: (_) => ProviderScope(
    overrides: [
      featureProvider.overrideWith((_) => FeatureSuccess(items: _mockItems())),
    ],
    child: const FeatureScreen(),
  ),
);
```

---

## Pattern D — GetIt scope

For screens whose cubit reads `getIt<T>()` during construction or `initState`.

```dart
late MockFeatureRepository mockRepository;

setUp(() {
  getIt.pushNewScope();
  mockRepository = MockFeatureRepository();
  getIt.registerLazySingleton<FeatureRepository>(() => mockRepository);
  when(() => mockRepository.dataStream)
      .thenAnswer((_) => const Stream.empty());
});

tearDown(() async {
  await getIt.popScope();
});

goldenTest(
  name: 'FeatureScreen - KYC pending',
  setup: (_) async {
    when(() => mockRepository.getStatus())
        .thenAnswer((_) async => KycStatus.pending);
    when(() => cubit.state).thenReturn(FeatureSuccess(/* ... */));
  },
  builder: (_) => FeatureScreen(cubitForTesting: cubit),
);
```

---

## Scroll & interaction recipes

### Scroll to bottom (short device forces overflow)

```dart
goldenTest(
  name: 'FeatureScreen - Scrolled to bottom',
  supportedDevices: [
    const Device(name: 'short', width: 390, height: 400, devicePixelRatio: 3),
  ],
  action: (WidgetTester tester) async {
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
  },
  setup: (_) async {
    when(() => cubit.state).thenReturn(FeatureSuccess(items: _manyItems()));
  },
  builder: (_) => BlocProvider<FeatureCubit>.value(
    value: cubit,
    child: const FeatureScreen(),
  ),
);
```

### Tap to expand sections

```dart
action: (WidgetTester tester) async {
  await tester.tap(find.byType(ExpansionTile).first);
  await tester.pumpAndSettle();
},
```

### Scroll until widget visible (lazy slivers)

```dart
action: (WidgetTester tester) async {
  await tester.scrollUntilVisible(find.byKey(const Key('footer')), 300);
  await tester.pump();
},
```

### Safe-area stress variants

```dart
goldenTest(
  name: 'FeatureScreen - safe area variants',
  supportedDevices: [
    const Device(name: 'standard', width: 390, height: 844,
        insets: EdgeInsets.only(top: 44, bottom: 34), devicePixelRatio: 3),
    const Device(name: 'no-insets', width: 390, height: 844,
        insets: EdgeInsets.zero, devicePixelRatio: 3),
    const Device(name: 'large-insets', width: 390, height: 844,
        insets: EdgeInsets.only(top: 100, bottom: 100), devicePixelRatio: 3),
  ],
  supportMultipleDevices: true,
  builder: (_) => const FeatureScreen(),
);
```

---

## Test data conventions

- Build fixtures with **dedicated helper functions** at the bottom: `_mockItems()`, `_buildState()`, etc.
- Use **`DateTime(2024, 1, 1)`** for timestamps that hit `.toLocal()` — `DateTime.utc(...)` makes goldens timezone-dependent.
- Exercise long strings, large numbers, and overflow-prone locales.

---

## Anti-patterns

- Calling `emit()` / `cubit.safeEmit()` on the cubit — stub `state` instead.
- `Future.delayed` / `.timeout()` — non-deterministic.
- Instantiating the screen without mocking when `initState` triggers network calls.
- Sharing GetIt registrations across tests without `pushNewScope` / `popScope`.
- One golden trying to capture "everything" on a complex screen — split by state.
