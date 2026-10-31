import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';
import 'package:material_ui/material_ui.dart';

const _iphone = Device.iphone15Pro();

void main() {
  goldenTestDifferenceTolerance(0.05);

  group('keyboard simulation', () {
    goldenTest(
      name: 'Keyboard appears when a field gains focus',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [_iphone],
      builder: (_) => const _Form(),
      action: (tester) async {
        await tester.tap(find.byKey(_Form.emailField));
        await tester.pumpAndSettle();
        final BuildContext context = tester.element(find.byType(_Form));
        expect(MediaQuery.viewInsetsOf(context).bottom, 336);
        expect(MediaQuery.paddingOf(context).bottom, 0);
        expect(tester.getSize(find.byKey(_Form.body)).height, 852 - 336);
      },
    );

    goldenTest(
      name: 'Keyboard follows the focused field',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [_iphone],
      builder: (_) => const _Form(),
      action: (tester) async {
        await tester.tap(find.byKey(_Form.emailField));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(_Form.amountField));
        await tester.pumpAndSettle();
        final BuildContext context = tester.element(find.byType(_Form));
        expect(MediaQuery.viewInsetsOf(context).bottom, 291);
      },
    );

    goldenTest(
      name: 'Keyboard hides when the field loses focus',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [_iphone],
      builder: (_) => const _Form(),
      action: (tester) async {
        await tester.tap(find.byKey(_Form.emailField));
        await tester.pumpAndSettle();
        FocusManager.instance.primaryFocus!.unfocus();
        await tester.pumpAndSettle();
        final BuildContext context = tester.element(find.byType(_Form));
        expect(MediaQuery.viewInsetsOf(context).bottom, 0);
        expect(MediaQuery.paddingOf(context).bottom, 34);
        expect(tester.getSize(find.byKey(_Form.body)).height, 852);
      },
    );

    goldenTest(
      name: 'Keyboard with enterText',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [_iphone],
      builder: (_) => const _Form(),
      action: (tester) async {
        await tester.enterText(
          find.byKey(_Form.emailField),
          'name@example.com',
        );
        await tester.pumpAndSettle();
        expect(find.text('name@example.com'), findsOneWidget);
        final BuildContext context = tester.element(find.byType(_Form));
        expect(MediaQuery.viewInsetsOf(context).bottom, 336);
      },
    );

    goldenTest(
      name: 'Keyboard set by the test wins over the focused field',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [_iphone],
      keyboard: const GoldenKeyboard(type: TextInputType.number),
      builder: (_) => const _Form(),
      action: (tester) async {
        await tester.tap(find.byKey(_Form.emailField));
        await tester.pumpAndSettle();
        final BuildContext context = tester.element(find.byType(_Form));
        expect(MediaQuery.viewInsetsOf(context).bottom, 291);
      },
    );

    group('turned off', () {
      setUp(() => goldenTestSimulateKeyboard = false);
      tearDown(() => goldenTestSimulateKeyboard = true);

      goldenTest(
        name: 'No keyboard when the simulation is off',
        supportedLocales: [const Locale('en')],
        supportedThemes: [Brightness.light],
        supportedDevices: [_iphone],
        builder: (_) => const _Form(),
        action: (tester) async {
          await tester.tap(find.byKey(_Form.emailField));
          await tester.pumpAndSettle();
          final BuildContext context = tester.element(find.byType(_Form));
          expect(MediaQuery.viewInsetsOf(context).bottom, 0);
          expect(tester.getSize(find.byKey(_Form.body)).height, 852);
        },
      );
    });
  });
}

class _Form extends StatelessWidget {
  const _Form();

  static const body = Key('body');
  static const emailField = Key('email');
  static const amountField = Key('amount');

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      key: body,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TextField(
              key: emailField,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              key: amountField,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Amount',
              ),
            ),
            const Spacer(),
            FilledButton(onPressed: () {}, child: const SizedBox(height: 24)),
          ],
        ),
      ),
    ),
  );
}
