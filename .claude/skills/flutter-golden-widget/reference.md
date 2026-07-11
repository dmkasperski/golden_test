# flutter-golden-widget — Reference

Full examples cited from `SKILL.md`. Read on demand.

## Device sets

### Isolated component (no chrome)

```dart
supportedDevices: [const Device.noInsets()],
```

### Common responsive breakpoints

Use when the widget reflows at narrow widths.

```dart
const List<Device> _devices = [
  Device(name: 'narrow', width: 330, height: 600, devicePixelRatio: 2),
  Device(name: 'iphone-se', width: 375, height: 667, devicePixelRatio: 2),
  Device.iphone15Pro(),
  Device.pixel9ProXL(),
];

goldenTest(
  name: 'MyWidget - responsive',
  supportedDevices: _devices,
  supportMultipleDevices: true,
  builder: (_) => const MyWidget(),
);
```

### Catalog showcase device

```dart
supportedDevices: [const Device(name: 'showcase', width: 600, height: 2000)],
```

---

## Pattern: variant column

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

## Pattern: BlocProvider-wrapped widget

```dart
class MockMyCubit extends Mock implements MyCubit {
  @override
  Stream<MyState> get stream => const Stream.empty();

  @override
  Future<void> close() => Future.value();
}

void main() {
  final cubit = MockMyCubit();

  setUp(() {
    when(() => cubit.state).thenReturn(const MyInitial());
  });

  goldenTest(
    name: 'MyWidget - success',
    setup: (_) async {
      when(() => cubit.state).thenReturn(MySuccess(data: _mockData()));
    },
    builder: (_) => BlocProvider<MyCubit>.value(
      value: cubit,
      child: const MyWidget(),
    ),
  );
}
```

### Riverpod

```dart
builder: (_) => ProviderScope(
  overrides: [myProvider.overrideWith((_) => mockNotifier)],
  child: const MyWidget(),
),
```

### Provider / ChangeNotifier

```dart
builder: (_) => ChangeNotifierProvider<MyController>.value(
  value: mockController,
  child: const MyWidget(),
),
```

---

## Pattern: catalog showcase (enum loop)

```dart
goldenTest(
  name: 'MyButton showcase',
  supportedDevices: [const Device(name: 'showcase', width: 400, height: 2000)],
  builder: (_) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final variant in MyButtonVariant.values) ...[
          Text(variant.name, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          MyButton(variant: variant, label: variant.name),
          const SizedBox(height: 16),
        ],
      ],
    ),
  ),
);
```

---

## Pattern: bottom-sheet content

Test the content widget directly — never call `showModalBottomSheet` in goldens.

```dart
goldenTest(
  name: 'MySheet - default',
  builder: (_) => Scaffold(
    body: SingleChildScrollView(
      child: MySheetContent(onConfirm: () {}),
    ),
  ),
);
```

---

## Minimal file template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';

void main() {
  goldenTest(
    name: 'MyComponent - all variants',
    supportedDevices: [const Device.noInsets()],
    builder: (_) => Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyComponent(variant: MyVariant.a, onTap: () {}),
            const SizedBox(height: 12),
            MyComponent(variant: MyVariant.b, onTap: null),
          ],
        ),
      ),
    ),
  );
}
```

---

## Golden output path structure

`goldens/{subdirectory?}/{locale}/{brightness}/{deviceName?}/{name}.png`

Examples:
- `goldens/en/light/MyComponent - all variants.png` (single device)
- `goldens/en/dark/iphone 15 pro/MyWidget - success.png` (multi-device)
- `goldens/design_system/en/light/showcase/MyButton showcase.png` (subdirectory)

Mirror `lib/` structure under `test/`.
