import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  goldenTestDifferenceTolerance(0.05);

  group('navigatorBuilder', () {
    setUp(() {
      goldenTestNavigatorBuilder = (_, navigator) =>
          _Message(text: 'from goldenTestNavigatorBuilder', child: navigator);
    });

    tearDown(() => goldenTestNavigatorBuilder = null);

    goldenTest(
      name: 'NavigatorBuilder',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [const Device.iphone15Pro()],
      navigatorBuilder: (_, navigator) =>
          _Message(text: 'from navigatorBuilder', child: navigator),
      builder: (_) => const _DialogButton(),
      action: _openDialogShowing('from navigatorBuilder'),
    );

    goldenTest(
      name: 'GlobalNavigatorBuilder',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [const Device.iphone15Pro()],
      builder: (_) => const _DialogButton(),
      action: _openDialogShowing('from goldenTestNavigatorBuilder'),
    );
  });
}

Future<void> Function(WidgetTester) _openDialogShowing(String text) =>
    (tester) async {
      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();
      expect(find.text(text), findsOneWidget);
    };

class _Message extends InheritedWidget {
  const _Message({required this.text, required super.child});

  final String text;

  static String of(BuildContext context) {
    final message = context.dependOnInheritedWidgetOfExactType<_Message>();
    if (message == null) {
      throw FlutterError('No _Message found above this context.');
    }
    return message.text;
  }

  @override
  bool updateShouldNotify(_Message oldWidget) => text != oldWidget.text;
}

class _DialogButton extends StatelessWidget {
  const _DialogButton();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: FilledButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) =>
                AlertDialog(content: Text(_Message.of(context))),
          ),
          child: const Text('Open dialog'),
        ),
      ),
    ),
  );
}
