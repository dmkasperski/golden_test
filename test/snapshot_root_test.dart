import 'package:golden_test/golden_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  goldenTestDifferenceTolerance(0.05);

  // A builder is free to return its own app: server-driven UI, storybook-style
  // harnesses and nested navigators all do. The snapshot must still resolve to
  // a single widget.
  goldenTest(
    name: 'NestedApp',
    supportedLocales: [const Locale('en')],
    supportedThemes: [Brightness.light],
    supportedDevices: [const Device.iphone15Pro()],
    builder: (_) => const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('nested app'))),
    ),
  );
}
