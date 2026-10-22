import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  goldenTestDifferenceTolerance(0.05);

  group('navigatorBuilder', () {
    setUp(() {
      goldenTestNavigatorBuilder = (_, navigator) =>
          _Message(text: 'from goldenTestNavigatorBuilder', child: navigator!);
    });

    tearDown(() => goldenTestNavigatorBuilder = null);

    goldenTest(
      name: 'NavigatorBuilder',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [const Device.iphone15Pro()],
      navigatorBuilder: (_, navigator) =>
          _Message(text: 'from navigatorBuilder', child: navigator!),
      builder: (_) => const _RootRouteButton(),
      action: (tester) => tester.tap(find.byType(TextButton)),
      tearDown: (_) async {
        expect(find.text('from navigatorBuilder'), findsOneWidget);
      },
    );

    goldenTest(
      name: 'GlobalNavigatorBuilder',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [const Device.iphone15Pro()],
      builder: (_) => const _RootRouteButton(),
      action: (tester) => tester.tap(find.byType(TextButton)),
      tearDown: (_) async {
        expect(find.text('from goldenTestNavigatorBuilder'), findsOneWidget);
      },
    );
  });
}

class _Message extends InheritedWidget {
  const _Message({required this.text, required super.child});

  final String text;

  static String of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Message>()?.text ??
      'no message above the root navigator';

  @override
  bool updateShouldNotify(_Message oldWidget) => text != oldWidget.text;
}

class _RootRouteButton extends StatelessWidget {
  const _RootRouteButton();

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (context) =>
              Scaffold(body: Center(child: Text(_Message.of(context)))),
        ),
      ),
      child: const Text('Open'),
    ),
  );
}
