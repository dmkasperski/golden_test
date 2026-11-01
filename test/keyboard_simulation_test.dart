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

    goldenTest(
      name: 'No keyboard for TextInputType.none',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [_iphone],
      builder: (_) => const _Form(),
      action: (tester) async {
        await tester.tap(find.byKey(_Form.pinField));
        await tester.pumpAndSettle();
        final BuildContext context = tester.element(find.byType(_Form));
        expect(MediaQuery.viewInsetsOf(context).bottom, 0);
        expect(tester.testTextInput.isVisible, isTrue);
      },
    );

    goldenTest(
      name: 'No keyboard on a desktop device',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [
        const Device(
          name: 'desktop',
          width: 1024,
          height: 768,
          platform: TargetPlatform.macOS,
        ),
      ],
      builder: (_) => const _Form(),
      action: (tester) async {
        await tester.tap(find.byKey(_Form.emailField));
        await tester.pumpAndSettle();
        final BuildContext context = tester.element(find.byType(_Form));
        expect(MediaQuery.viewInsetsOf(context).bottom, 0);
      },
    );

    goldenTest(
      name: 'Keyboard stays through a password toggle',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [_iphone],
      builder: (_) => const _PasswordForm(),
      action: (tester) async {
        await tester.enterText(find.byType(TextField), 'hunter2');
        await tester.pumpAndSettle();
        // Toggling obscureText on a focused field sends TextInput.updateConfig
        // from didUpdateWidget, during build.
        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();
        expect(find.text('hunter2'), findsOneWidget);
        expect(find.text('Hide'), findsOneWidget);
        final BuildContext context = tester.element(find.byType(_PasswordForm));
        expect(MediaQuery.viewInsetsOf(context).bottom, 336);
      },
    );

    goldenTest(
      name: 'Keyboard follows a keyboardType change on the focused field',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [_iphone],
      builder: (_) => const _ContactForm(),
      action: (tester) async {
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        // Switching keyboardType on a focused field sends
        // TextInput.updateConfig from didUpdateWidget, during build.
        await tester.tap(find.text('Phone'));
        await tester.pumpAndSettle();
        final BuildContext context = tester.element(find.byType(_ContactForm));
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

/// A password field with a show/hide toggle, which changes `obscureText`.
class _PasswordForm extends StatefulWidget {
  const _PasswordForm();

  @override
  State<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<_PasswordForm> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          obscureText: _obscured,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'Password',
            // Text instead of an icon: the package tests load no icon font.
            suffixIcon: TextButton(
              onPressed: () => setState(() => _obscured = !_obscured),
              child: Text(_obscured ? 'Show' : 'Hide'),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A contact field whose `keyboardType` follows a segmented choice.
class _ContactForm extends StatefulWidget {
  const _ContactForm();

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  TextInputType _keyboardType = TextInputType.emailAddress;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<TextInputType>(
              // No check icon: the package tests load no icon font.
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: TextInputType.emailAddress,
                  label: Text('Email'),
                ),
                ButtonSegment(value: TextInputType.phone, label: Text('Phone')),
              ],
              selected: {_keyboardType},
              onSelectionChanged: (selected) =>
                  setState(() => _keyboardType = selected.single),
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: _keyboardType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Contact',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Form extends StatelessWidget {
  const _Form();

  static const body = Key('body');
  static const emailField = Key('email');
  static const amountField = Key('amount');
  static const pinField = Key('pin');

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
            const SizedBox(height: 16),
            // A field with its own input UI, which opens no system keyboard.
            const TextField(
              key: pinField,
              keyboardType: TextInputType.none,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'PIN',
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
