import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';
import 'package:material_ui/material_ui.dart';

/// Accepts every image, so these tests check the tree, not the pixels.
class _AcceptingComparator extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async => true;

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {}
}

void main() {
  setUp(() {
    final previous = goldenFileComparator;
    goldenFileComparator = _AcceptingComparator();
    addTearDown(() => goldenFileComparator = previous);
  });

  goldenTest(
    name: 'Snackbar above the bottom navigation bar',
    supportedLocales: [const Locale('en')],
    supportedThemes: [Brightness.light],
    supportedDevices: [const Device.iphone15Pro()],
    builder: (_) => const _Screen(key: Key('screen')),
    action: (tester) async {
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // As in an app, the snackbar is in the widget's own Scaffold, above its
      // navigation bar, not in the harness's.
      final snackBar = find.byType(SnackBar);
      expect(snackBar, findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('screen')),
          matching: snackBar,
        ),
        findsOneWidget,
      );
      expect(
        tester.getRect(snackBar).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(NavigationBar)).top),
      );
    },
  );

  goldenTest(
    name: 'Snackbar in each of two Scaffolds side by side',
    supportedLocales: [const Locale('en')],
    supportedThemes: [Brightness.light],
    supportedDevices: [const Device.ipadPro12()],
    builder: (_) => const Row(
      children: [
        Expanded(child: _Screen()),
        Expanded(child: _Screen()),
      ],
    ),
    action: (tester) async {
      await tester.tap(find.text('Show').first);
      await tester.pumpAndSettle();

      // Flutter shows a snackbar in every Scaffold of the messenger that is
      // not inside another one, here both.
      expect(find.byType(SnackBar), findsNWidgets(2));
    },
  );
}

class _Screen extends StatelessWidget {
  const _Screen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved'))),
          child: const Text('Show'),
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    ),
  );
}
