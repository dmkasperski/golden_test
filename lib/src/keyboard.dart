import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:golden_test/src/device.dart';

/// The look of the software keyboard drawn by [GoldenKeyboard].
enum GoldenKeyboardStyle {
  ios,

  /// Gboard, the default Android keyboard.
  android,
}

/// A software keyboard shown over the bottom of the screen in a golden test.
///
/// The keyboard is simulated, not opened: the view gets a bottom
/// `viewInsets` of the keyboard's height, exactly as a device reports an open
/// keyboard, and the keyboard is painted into that area like the status bar.
/// The widget under test lays out the way it would on a device, so a
/// `Scaffold` with `resizeToAvoidBottomInset` shrinks its body and anything
/// that does not fit overflows. Nothing needs to have focus. The keyboard
/// takes the taps over its area, as on a device, so `tester.tap` on a control
/// it covers does not reach the control.
///
/// ```dart
/// goldenTest(
///   name: 'SignIn keyboard',
///   builder: (_) => const SignInScreen(),
///   keyboard: const GoldenKeyboard(type: TextInputType.emailAddress),
/// );
/// ```
///
/// The keys are always the English QWERTY layout, whatever the test's locale,
/// so a keyboard golden changes only when the screen does. Layouts are those of
/// a phone in portrait; on a wider device the keys stretch to its width.
@immutable
class GoldenKeyboard {
  /// Creates a keyboard of [type], drawn in [style].
  const GoldenKeyboard({
    this.style,
    this.type = TextInputType.text,
    this.height,
  });

  /// Which platform's keyboard to draw.
  ///
  /// When `null`, it follows [Device.platform] of the device the test runs
  /// on, so one test over an iPhone and a Pixel draws each its own keyboard.
  /// A device without a platform falls back to [defaultTargetPlatform].
  final GoldenKeyboardStyle? style;

  /// The keyboard layout, as the field that opened it would request it.
  ///
  /// [TextInputType.number] and [TextInputType.phone] draw a number pad;
  /// [TextInputType.emailAddress] and [TextInputType.url] add their own keys
  /// to the letter layout; every other type draws the letter layout.
  final TextInputType type;

  /// The keyboard's height in logical pixels, measured from the bottom edge
  /// of the screen.
  ///
  /// When `null`, it is the height of the platform's keyboard of [type] on a
  /// phone in portrait, including the device's bottom inset.
  ///
  /// The keys keep their size and sit on the bottom of the keyboard; the
  /// suggestion bar above them takes up the difference. The height can be no
  /// lower than the [style]'s number pad on the device, which has no
  /// suggestion bar.
  final double? height;

  @override
  bool operator ==(Object other) =>
      other is GoldenKeyboard &&
      other.style == style &&
      other.type == type &&
      other.height == height;

  @override
  int get hashCode => Object.hash(style, type, height);
}
