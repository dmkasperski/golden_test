import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';
import 'package:golden_test/src/utils/keyboard_painter.dart';
import 'package:material_ui/material_ui.dart';

const _iphone = Device.iphone15Pro();
const _pixel = Device.pixel9ProXL();

void main() {
  goldenTestDifferenceTolerance(0.05);

  group('keyboard', () {
    int submitted = 0;

    for (final (Device device, String style) in <(Device, String)>[
      (_iphone, 'iOS'),
      (_pixel, 'Android'),
    ]) {
      for (final (TextInputType type, String typeName)
          in <(TextInputType, String)>[
            (TextInputType.text, 'text'),
            (TextInputType.emailAddress, 'email'),
            (TextInputType.url, 'url'),
            (TextInputType.number, 'number'),
            (const TextInputType.numberWithOptions(decimal: true), 'decimal'),
            (TextInputType.phone, 'phone'),
          ]) {
        for (final Brightness mode in [
          Brightness.light,
          if (typeName == 'text' || typeName == 'number') Brightness.dark,
        ]) {
          goldenTest(
            name: 'Keyboard $style $typeName ${mode.name}',
            supportedLocales: [const Locale('en')],
            supportedThemes: [mode],
            supportedDevices: [device],
            keyboard: GoldenKeyboard(type: type),
            builder: (_) => const _Form(),
          );
        }
      }
    }

    goldenTest(
      name: 'Keyboard follows the device',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [_iphone, _pixel],
      keyboard: const GoldenKeyboard(),
      builder: (_) => const _Form(),
    );

    goldenTest(
      name: 'Keyboard iOS without a bottom inset',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [const Device.noInsets()],
      keyboard: const GoldenKeyboard(style: GoldenKeyboardStyle.ios),
      builder: (_) => const _Form(),
    );

    goldenTest(
      name: 'Keyboard on a device without a platform',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [const Device.noInsets()],
      keyboard: const GoldenKeyboard(),
      builder: (_) => const _Form(),
    );

    goldenTest(
      name: 'Keyboard reported as view insets',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [_iphone],
      keyboard: const GoldenKeyboard(),
      builder: (_) => const _Form(),
      action: (tester) async {
        final BuildContext context = tester.element(find.byType(_Form));
        expect(MediaQuery.viewInsetsOf(context).bottom, 336);
        expect(MediaQuery.viewPaddingOf(context).bottom, 34);
        expect(MediaQuery.paddingOf(context).bottom, 0);
        expect(tester.getSize(find.byKey(_Form.body)).height, 852 - 336);
      },
    );

    goldenTest(
      name: 'Keyboard without resizeToAvoidBottomInset',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [_iphone],
      keyboard: const GoldenKeyboard(),
      builder: (_) =>
          _Form(resizeToAvoidBottomInset: false, onSubmit: () => submitted++),
      action: (tester) async {
        expect(tester.getSize(find.byKey(_Form.body)).height, 852);
        await tester.tap(find.byType(FilledButton), warnIfMissed: false);
        expect(submitted, 0, reason: 'the keyboard covers the button');
      },
    );

    goldenTest(
      name: 'Keyboard with an explicit style and height',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [_iphone],
      keyboard: const GoldenKeyboard(
        style: GoldenKeyboardStyle.android,
        height: 300,
      ),
      builder: (_) => const _Form(),
      action: (tester) async {
        final BuildContext context = tester.element(find.byType(_Form));
        expect(MediaQuery.viewInsetsOf(context).bottom, 300);
      },
    );

    test('A height lower than the keys fails', () {
      expect(
        () => ResolvedKeyboard.of(
          const GoldenKeyboard(style: GoldenKeyboardStyle.ios, height: 250),
          _iphone,
        ),
        throwsAssertionError,
      );
    });

    goldenTest(
      name: 'No keyboard',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [_iphone],
      builder: (_) => const _Form(),
      action: (tester) async {
        final BuildContext context = tester.element(find.byType(_Form));
        expect(MediaQuery.viewInsetsOf(context).bottom, 0);
        expect(MediaQuery.paddingOf(context).bottom, 34);
        expect(tester.getSize(find.byKey(_Form.body)).height, 852);
      },
    );
  });
}

class _Form extends StatelessWidget {
  const _Form({this.resizeToAvoidBottomInset = true, this.onSubmit});

  static const Key body = Key('body');

  final bool resizeToAvoidBottomInset;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    body: SafeArea(
      key: body,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TextField(
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
            const Spacer(),
            FilledButton(
              onPressed: onSubmit ?? () {},
              child: const SizedBox(height: 24),
            ),
          ],
        ),
      ),
    ),
  );
}
