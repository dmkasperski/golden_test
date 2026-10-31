import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/src/device.dart';
import 'package:golden_test/src/keyboard.dart';
import 'package:golden_test/src/utils/keyboard_painter.dart';

/// Reports [keyboard] to the test view the way a device reports an open
/// keyboard: as a bottom `viewInsets`, with `padding` reduced by it because
/// the keyboard covers the bottom safe area.
void setKeyboardInsets({
  required WidgetTester tester,
  required Device device,
  required ResolvedKeyboard? keyboard,
}) {
  final double ratio = device.devicePixelRatio;
  final double keyboardHeight = keyboard?.height ?? 0;
  tester.view.padding = FakeViewPadding(
    left: device.insets.left * ratio,
    top: device.insets.top * ratio,
    right: device.insets.right * ratio,
    bottom: max(0, device.insets.bottom - keyboardHeight) * ratio,
  );
  tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight * ratio);
}

/// Shows and hides the software keyboard as the widget under test asks the
/// platform to, so a golden has a keyboard whenever a device would.
///
/// A text field that gains focus sends `TextInput.setClient` with its
/// configuration, then `TextInput.show`; losing focus sends `TextInput.hide`.
/// The simulation listens on [SystemChannels.textInput], resolves a
/// [GoldenKeyboard] of the field's `keyboardType` for [device], applies it to
/// the view with [setKeyboardInsets] and publishes it in [keyboard] for the
/// device frame to paint. Every message is forwarded to the handler
/// `flutter_test` has for the channel, so `enterText` keeps working.
class KeyboardSimulation {
  KeyboardSimulation._(
    this._tester,
    this._device,
    this._messenger,
    this._previousHandler,
  );

  /// Installs the simulation for the current test. Call [dispose] when the
  /// test ends, so the next test starts from the messenger it had.
  factory KeyboardSimulation.install({
    required WidgetTester tester,
    required Device device,
  }) {
    final TestDefaultBinaryMessenger messenger =
        tester.binding.defaultBinaryMessenger;
    final KeyboardSimulation simulation = KeyboardSimulation._(
      tester,
      device,
      messenger,
      messenger.allMessagesHandler,
    );
    messenger.allMessagesHandler = simulation._handleMessage;

    return simulation;
  }

  final WidgetTester _tester;
  final Device _device;
  final TestDefaultBinaryMessenger _messenger;
  final AllMessagesHandler? _previousHandler;

  TextInputType _keyboardType = TextInputType.text;
  bool _isVisible = false;

  /// The keyboard currently shown, or `null` while it is hidden.
  final ValueNotifier<ResolvedKeyboard?> keyboard = ValueNotifier(null);

  void dispose() {
    _messenger.allMessagesHandler = _previousHandler;
    keyboard.dispose();
  }

  Future<ByteData?>? _handleMessage(
    String channel,
    MessageHandler? handler,
    ByteData? message,
  ) {
    if (channel == SystemChannels.textInput.name && message != null) {
      _onTextInputCall(
        SystemChannels.textInput.codec.decodeMethodCall(message),
      );
    }

    final AllMessagesHandler? previousHandler = _previousHandler;
    if (previousHandler != null) {
      return previousHandler(channel, handler, message);
    }
    if (handler != null) {
      return handler(message);
    }

    return _messenger.delegate.send(channel, message);
  }

  void _onTextInputCall(MethodCall call) {
    switch (call.method) {
      // Arguments are the client id and the configuration.
      case 'TextInput.setClient':
        final List<Object?> arguments = call.arguments as List<Object?>;
        _keyboardType = _keyboardTypeOf(arguments[1] as Map<Object?, Object?>);
      case 'TextInput.updateConfig':
        _keyboardType = _keyboardTypeOf(
          call.arguments as Map<Object?, Object?>,
        );
      case 'TextInput.show':
        _isVisible = true;
      case 'TextInput.hide':
        _isVisible = false;
      default:
        return;
    }

    // A device ignores TextInput.show for TextInputType.none, which fields
    // with their own input UI use, and a desktop has no keyboard to show.
    final bool opensKeyboard =
        _isVisible &&
        _keyboardType.index != TextInputType.none.index &&
        hasSoftwareKeyboard(_device);
    final ResolvedKeyboard? shownKeyboard = opensKeyboard
        ? ResolvedKeyboard.of(GoldenKeyboard(type: _keyboardType), _device)
        : null;
    setKeyboardInsets(
      tester: _tester,
      device: _device,
      keyboard: shownKeyboard,
    );
    keyboard.value = shownKeyboard;
  }

  /// Reads `inputType` from a text input configuration, the JSON that
  /// [TextInputConfiguration.toJson] produces.
  TextInputType _keyboardTypeOf(Map<Object?, Object?> configuration) {
    final Map<Object?, Object?> inputType =
        configuration['inputType'] as Map<Object?, Object?>;
    final Object? name = inputType['name'];
    final TextInputType namedType = TextInputType.values.firstWhere(
      (value) => value.toJson()['name'] == name,
      orElse: () => TextInputType.text,
    );
    if (namedType.index != TextInputType.number.index) return namedType;

    return TextInputType.numberWithOptions(
      signed: inputType['signed'] as bool?,
      decimal: inputType['decimal'] as bool?,
    );
  }
}
