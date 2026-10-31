import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:golden_test/src/device.dart';
import 'package:golden_test/src/keyboard.dart';
import 'package:material_ui/material_ui.dart';

/// A [GoldenKeyboard] resolved for the device a test runs on.
@immutable
class ResolvedKeyboard {
  const ResolvedKeyboard._({
    required this.style,
    required this.type,
    required this.layout,
    required this.height,
    required this.bottomArea,
  });

  factory ResolvedKeyboard.of(GoldenKeyboard keyboard, Device device) {
    final style = keyboard.style ?? _styleOf(device);
    final KeyboardLayout layout = _layoutOf(
      style: style,
      type: keyboard.type,
    );
    final bottomArea = switch (style) {
      // An iPhone without a home button keeps a row for the globe and
      // dictation keys below the letters, over the home indicator.
      GoldenKeyboardStyle.ios => device.insets.bottom > 0 ? 75.0 : 0.0,
      GoldenKeyboardStyle.android => device.insets.bottom,
    };
    final double keysHeight = _heightAboveBottomArea(
      style: style,
      layout: layout,
    );

    return ResolvedKeyboard._(
      style: style,
      type: keyboard.type,
      layout: layout,
      height: keyboard.height ?? keysHeight + bottomArea,
      bottomArea: bottomArea,
    );
  }

  final GoldenKeyboardStyle style;
  final TextInputType type;
  final KeyboardLayout layout;

  /// Height from the bottom edge of the screen, in logical pixels.
  final double height;

  /// Height of the area below the keys, inside [height].
  final double bottomArea;
}

/// Whether [device] shows a software keyboard at all. Desktop platforms take
/// input from a hardware keyboard, so a focused field opens nothing there.
bool hasSoftwareKeyboard(Device device) =>
    switch (device.platform ?? defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => true,
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => false,
    };

/// The arrangement of keys a keyboard shows for a text input type.
enum KeyboardLayout {
  /// QWERTY letters with the type's extra keys in the bottom row.
  letters,

  /// Digits in a 3- or 4-column grid.
  numberPad,

  /// Digits and punctuation on full-width rows: the iOS `123` layer, which iOS
  /// opens for types the number pad cannot serve.
  symbols,
}

KeyboardLayout _layoutOf({
  required GoldenKeyboardStyle style,
  required TextInputType type,
}) {
  final bool ios = style == GoldenKeyboardStyle.ios;
  if (type.index == TextInputType.phone.index) return KeyboardLayout.numberPad;
  // The iOS number pad has no minus key, so a signed number gets the symbols.
  if (type.index == TextInputType.number.index) {
    return ios && (type.signed ?? false)
        ? KeyboardLayout.symbols
        : KeyboardLayout.numberPad;
  }
  if (type.index == TextInputType.datetime.index) {
    return ios ? KeyboardLayout.symbols : KeyboardLayout.numberPad;
  }

  return KeyboardLayout.letters;
}

GoldenKeyboardStyle _styleOf(Device device) =>
    switch (device.platform ?? defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => GoldenKeyboardStyle.ios,
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.windows => GoldenKeyboardStyle.android,
    };

const double _iosSuggestionBar = 45;
const double _iosRowPitch = 54;
const double _androidSuggestionStrip = 48;
const double _androidRowPitch = 56;
const double _androidRowsPadding = 4;

double _heightAboveBottomArea({
  required GoldenKeyboardStyle style,
  required KeyboardLayout layout,
}) {
  final bool numberPad = layout == KeyboardLayout.numberPad;

  return switch (style) {
    GoldenKeyboardStyle.ios =>
      (numberPad ? 0 : _iosSuggestionBar) + 4 * _iosRowPitch,
    GoldenKeyboardStyle.android =>
      (numberPad ? 0 : _androidSuggestionStrip) +
          4 * _androidRowPitch +
          2 * _androidRowsPadding,
  };
}

/// Paints [keyboard] into [area], the bottom of the screen.
///
/// Every edge is snapped to a physical pixel, so keys do not straddle pixel
/// boundaries and only rounded corners, icons and labels are anti-aliased.
void paintKeyboard({
  required Canvas canvas,
  required Rect area,
  required ResolvedKeyboard keyboard,
  required Brightness brightness,
  required double devicePixelRatio,
}) {
  final colors = _KeyboardColors.of(keyboard.style, brightness);
  final painter = _KeyboardPainter(canvas, colors, devicePixelRatio);
  canvas.drawRect(area, Paint()..color = colors.background);

  final keysArea = Rect.fromLTRB(
    area.left,
    area.top,
    area.right,
    area.bottom - keyboard.bottomArea,
  );
  final bottomArea = Rect.fromLTRB(
    area.left,
    keysArea.bottom,
    area.right,
    area.bottom,
  );

  switch ((keyboard.style, keyboard.layout)) {
    case (GoldenKeyboardStyle.ios, KeyboardLayout.letters):
      painter.iosLetters(keysArea, keyboard.type);
    case (GoldenKeyboardStyle.ios, KeyboardLayout.numberPad):
      painter.iosNumberPad(keysArea, keyboard.type);
    case (GoldenKeyboardStyle.ios, KeyboardLayout.symbols):
      painter.iosSymbols(keysArea);
    case (GoldenKeyboardStyle.android, KeyboardLayout.letters):
      painter.androidLetters(keysArea, keyboard.type);
    // Gboard has a number pad for every numeric type, so the symbols layout
    // is never resolved for Android.
    case (
      GoldenKeyboardStyle.android,
      KeyboardLayout.numberPad || KeyboardLayout.symbols,
    ):
      painter.androidNumberPad(keysArea, keyboard.type);
  }

  if (bottomArea.height > 0) {
    switch (keyboard.style) {
      case GoldenKeyboardStyle.ios:
        painter.iosBottomArea(bottomArea);
      case GoldenKeyboardStyle.android:
        painter.androidNavigationArea(bottomArea);
    }
  }
}

class _KeyboardColors {
  const _KeyboardColors({
    required this.background,
    required this.key,
    required this.functionKey,
    required this.actionKey,
    required this.label,
    required this.actionLabel,
    this.keyShadow,
  });

  factory _KeyboardColors.of(GoldenKeyboardStyle style, Brightness brightness) {
    final light = brightness == Brightness.light;

    return switch (style) {
      GoldenKeyboardStyle.ios => _KeyboardColors(
        background: Color(light ? 0xFFD1D3D9 : 0xFF2C2C2E),
        key: Color(light ? 0xFFFFFFFF : 0xFF6B6B6F),
        functionKey: Color(light ? 0xFFABB0BC : 0xFF46464A),
        actionKey: Color(light ? 0xFFABB0BC : 0xFF46464A),
        label: Color(light ? 0xFF000000 : 0xFFFFFFFF),
        actionLabel: Color(light ? 0xFF000000 : 0xFFFFFFFF),
        keyShadow: Color(light ? 0xFF898A8D : 0xFF0C0C0C),
      ),
      GoldenKeyboardStyle.android => _KeyboardColors(
        background: Color(light ? 0xFFE9EEF6 : 0xFF1B1B1F),
        key: Color(light ? 0xFFFFFFFF : 0xFF3B3B3F),
        functionKey: Color(light ? 0xFFD3DBE5 : 0xFF2A2C31),
        actionKey: Color(light ? 0xFF0B57D0 : 0xFFA8C7FA),
        label: Color(light ? 0xFF1F1F1F : 0xFFE3E3E3),
        actionLabel: Color(light ? 0xFFFFFFFF : 0xFF062E6F),
      ),
    };
  }

  final Color background;
  final Color key;
  final Color functionKey;
  final Color actionKey;
  final Color label;
  final Color actionLabel;
  final Color? keyShadow;
}

enum _KeyKind { letter, function, action, blank }

enum _Icon { shift, backspace, enter, space }

class _Key {
  const _Key(this.label, {this.flex = 1, this.kind = _KeyKind.letter})
    : icon = null,
      sublabel = null,
      stretch = false;

  const _Key.icon(this.icon, {this.flex = 1, this.kind = _KeyKind.function})
    : label = null,
      sublabel = null,
      stretch = false;

  const _Key.digit(this.label, [this.sublabel])
    : flex = 1,
      kind = _KeyKind.letter,
      icon = null,
      stretch = false;

  const _Key.stretch(this.label, {this.kind = _KeyKind.letter})
    : flex = 1,
      icon = null,
      sublabel = null,
      stretch = true;

  const _Key.spacer() : this.stretch(null, kind: _KeyKind.blank);

  final String? label;
  final String? sublabel;
  final _Icon? icon;
  final double flex;
  final _KeyKind kind;

  /// Takes an equal share of the width the fixed keys leave in the row.
  final bool stretch;
}

const _letterRows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];

List<_Key> _letters(String row) => [for (final c in row.split('')) _Key(c)];

class _KeyboardPainter {
  _KeyboardPainter(this.canvas, this.colors, this.devicePixelRatio);

  final Canvas canvas;
  final _KeyboardColors colors;
  final double devicePixelRatio;

  double _snap(double value) =>
      (value * devicePixelRatio).roundToDouble() / devicePixelRatio;

  // iOS ----------------------------------------------------------------------

  void iosLetters(Rect area, TextInputType type) {
    final bottomRow = switch (type) {
      _ when type.index == TextInputType.emailAddress.index => [
        const _Key('@'),
        const _Key('.'),
      ],
      _ when type.index == TextInputType.url.index => [
        const _Key('.'),
        const _Key('/'),
        const _Key.stretch('.com'),
      ],
      _ when type.index == TextInputType.twitter.index => [
        const _Key('@'),
        const _Key('#'),
      ],
      _ when type.index == TextInputType.webSearch.index => [const _Key('.')],
      _ => const <_Key>[],
    };
    final _Key actionKey = type.index == TextInputType.webSearch.index
        ? const _Key('go', flex: 2.5, kind: _KeyKind.action)
        : const _Key.icon(_Icon.enter, flex: 2.5, kind: _KeyKind.action);
    _iosRows(
      area: area,
      rows: [
        _letters(_letterRows[0]),
        _letters(_letterRows[1]),
        [
          const _Key.icon(_Icon.shift, flex: 1.3),
          const _Key.spacer(),
          ..._letters(_letterRows[2]),
          const _Key.spacer(),
          const _Key.icon(_Icon.backspace, flex: 1.3),
        ],
        [
          const _Key('123', flex: 2.5, kind: _KeyKind.function),
          if (type.index != TextInputType.url.index) const _Key.stretch(null),
          ...bottomRow,
          actionKey,
        ],
      ],
    );
  }

  /// The iOS `123` layer: digits, then punctuation, then more punctuation.
  void iosSymbols(Rect area) {
    _iosRows(
      area: area,
      rows: [
        _letters('1234567890'),
        _letters('-/:;()\$&@"'),
        [
          const _Key('#+=', flex: 1.3, kind: _KeyKind.function),
          const _Key.spacer(),
          ..._letters(".,?!'"),
          const _Key.spacer(),
          const _Key.icon(_Icon.backspace, flex: 1.3),
        ],
        [
          const _Key('ABC', flex: 2.5, kind: _KeyKind.function),
          const _Key.stretch(null),
          const _Key.icon(_Icon.enter, flex: 2.5, kind: _KeyKind.action),
        ],
      ],
    );
  }

  /// Four rows of keys under the suggestion bar, as every full-width iOS
  /// layout has them. The 10 keys of the first row set the unit width.
  void _iosRows({
    required Rect area,
    required List<List<_Key>> rows,
  }) {
    _suggestionDividers(
      Rect.fromLTWH(area.left, area.top, area.width, _iosSuggestionBar),
    );

    const margin = 3.0;
    const gap = 6.0;
    final unit = (area.width - 2 * margin - 9 * gap) / 10;

    for (var i = 0; i < rows.length; i++) {
      final top = area.top + _iosSuggestionBar + i * _iosRowPitch + 6;
      _row(
        rows[i],
        left: area.left + margin,
        right: area.right - margin,
        top: top,
        height: 42,
        unit: unit,
        gap: gap,
        radius: 5,
        fontSize: 22,
      );
    }
  }

  void iosNumberPad(Rect area, TextInputType type) {
    const margin = 6.0;
    const gap = 6.0;
    final unit = (area.width - 2 * margin - 2 * gap) / 3;
    final phone = type.index == TextInputType.phone.index;
    final rows = [
      [
        const _Key.digit('1', ''),
        const _Key.digit('2', 'ABC'),
        const _Key.digit('3', 'DEF'),
      ],
      [
        const _Key.digit('4', 'GHI'),
        const _Key.digit('5', 'JKL'),
        const _Key.digit('6', 'MNO'),
      ],
      [
        const _Key.digit('7', 'PQRS'),
        const _Key.digit('8', 'TUV'),
        const _Key.digit('9', 'WXYZ'),
      ],
      [
        if (phone)
          const _Key('+ * #', kind: _KeyKind.blank)
        else if (type.decimal ?? false)
          const _Key('.', kind: _KeyKind.blank)
        else
          const _Key(null, kind: _KeyKind.blank),
        const _Key.digit('0'),
        const _Key.icon(_Icon.backspace, kind: _KeyKind.blank),
      ],
    ];

    for (var i = 0; i < rows.length; i++) {
      _row(
        rows[i],
        left: area.left + margin,
        right: area.right - margin,
        top: area.top + i * _iosRowPitch + 4,
        height: 46,
        unit: unit,
        gap: gap,
        radius: 5,
        fontSize: 25,
      );
    }
  }

  void iosBottomArea(Rect area) {
    final paint = _iconPaint(colors.label);
    final y = area.top + 22;

    final globe = Offset(area.left + 34, y);
    canvas.drawCircle(globe, 10, paint);
    canvas.drawOval(
      Rect.fromCenter(center: globe, width: 9, height: 20),
      paint,
    );
    canvas.drawLine(globe.translate(-10, 0), globe.translate(10, 0), paint);

    final mic = Offset(area.right - 34, y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: mic.translate(0, -3), width: 7, height: 12),
        const Radius.circular(3.5),
      ),
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: mic.translate(0, -1), width: 13, height: 13),
      0,
      pi,
      false,
      paint,
    );
    canvas.drawLine(mic.translate(0, 5.5), mic.translate(0, 9), paint);
  }

  void _suggestionDividers(Rect bar) {
    final paint = Paint()..color = colors.functionKey;
    for (final fraction in [1 / 3, 2 / 3]) {
      final x = _snap(bar.left + bar.width * fraction);
      canvas.drawRect(
        Rect.fromLTRB(x, _snap(bar.top + 10), x + 1, _snap(bar.bottom - 10)),
        paint,
      );
    }
  }

  // Android ------------------------------------------------------------------

  void androidLetters(Rect area, TextInputType type) {
    _suggestionStrip(
      Rect.fromLTWH(area.left, area.top, area.width, _androidSuggestionStrip),
    );

    const margin = 4.0;
    const gap = 6.0;
    final unit = (area.width - 2 * margin - 9 * gap) / 10;
    final email = type.index == TextInputType.emailAddress.index;
    final url = type.index == TextInputType.url.index;
    final rows = [
      _letters(_letterRows[0]),
      _letters(_letterRows[1]),
      [
        const _Key.icon(_Icon.shift, flex: 1.5),
        ..._letters(_letterRows[2]),
        const _Key.icon(_Icon.backspace, flex: 1.5),
      ],
      [
        const _Key('?123', flex: 1.5, kind: _KeyKind.function),
        _Key(email ? '@' : (url ? '/' : ','), kind: _KeyKind.function),
        const _Key.stretch(null),
        const _Key('.', kind: _KeyKind.function),
        const _Key.icon(_Icon.enter, flex: 1.5, kind: _KeyKind.action),
      ],
    ];

    for (var i = 0; i < rows.length; i++) {
      _row(
        rows[i],
        left: area.left + margin,
        right: area.right - margin,
        top:
            area.top +
            _androidSuggestionStrip +
            _androidRowsPadding +
            i * _androidRowPitch +
            5,
        height: 46,
        unit: unit,
        gap: gap,
        radius: 6,
        fontSize: 22,
      );
    }
  }

  void androidNumberPad(Rect area, TextInputType type) {
    const margin = 4.0;
    const gap = 6.0;
    final unit = (area.width - 2 * margin - 3 * gap) / 4;
    final (leftKey, rightKey) = switch (type) {
      _ when type.index == TextInputType.phone.index => ('*', '#'),
      _ when type.index == TextInputType.datetime.index => ('/', ':'),
      _ => (',', '.'),
    };
    final rows = [
      [
        const _Key('1'),
        const _Key('2'),
        const _Key('3'),
        const _Key('-', kind: _KeyKind.function),
      ],
      [
        const _Key('4'),
        const _Key('5'),
        const _Key('6'),
        const _Key.icon(_Icon.space),
      ],
      [
        const _Key('7'),
        const _Key('8'),
        const _Key('9'),
        const _Key.icon(_Icon.backspace),
      ],
      [
        _Key(leftKey, kind: _KeyKind.function),
        const _Key('0'),
        _Key(rightKey, kind: _KeyKind.function),
        const _Key.icon(_Icon.enter, kind: _KeyKind.action),
      ],
    ];

    for (var i = 0; i < rows.length; i++) {
      _row(
        rows[i],
        left: area.left + margin,
        right: area.right - margin,
        top: area.top + _androidRowsPadding + i * _androidRowPitch + 5,
        height: 46,
        unit: unit,
        gap: gap,
        radius: 6,
        fontSize: 24,
      );
    }
  }

  void _suggestionStrip(Rect strip) {
    final paint = Paint()..color = colors.label;
    final center = Offset(strip.left + 28, strip.center.dy);
    for (final dx in [-4.5, 1.5]) {
      for (final dy in [-4.5, 1.5]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(_snap(center.dx + dx), _snap(center.dy + dy), 3, 3),
            const Radius.circular(1),
          ),
          paint,
        );
      }
    }
  }

  void androidNavigationArea(Rect area) {
    final Offset center = Offset(
      area.left + 36,
      area.top + area.height / 2 - 2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 6, center.dy - 3)
        ..lineTo(center.dx, center.dy + 3)
        ..lineTo(center.dx + 6, center.dy - 3),
      _iconPaint(colors.label),
    );
  }

  // Keys ---------------------------------------------------------------------

  void _row(
    List<_Key> keys, {
    required double left,
    required double right,
    required double top,
    required double height,
    required double unit,
    required double gap,
    required double radius,
    required double fontSize,
  }) {
    double fixedWidth(_Key key) => key.flex * unit + (key.flex - 1) * gap;

    final fixed = keys
        .where((key) => !key.stretch)
        .fold<double>(0, (sum, key) => sum + fixedWidth(key));
    final stretchCount = keys.where((key) => key.stretch).length;
    final free = right - left - fixed - (keys.length - 1) * gap;
    final stretchWidth = stretchCount == 0 ? 0.0 : free / stretchCount;

    var x = stretchCount == 0 ? left + free / 2 : left;
    for (final key in keys) {
      final width = key.stretch ? stretchWidth : fixedWidth(key);
      _key(
        key: key,
        rect: Rect.fromLTRB(
          _snap(x),
          _snap(top),
          _snap(x + width),
          _snap(top + height),
        ),
        radius: radius,
        fontSize: fontSize,
      );
      x += width + gap;
    }
  }

  void _key({
    required _Key key,
    required Rect rect,
    required double radius,
    required double fontSize,
  }) {
    final fill = switch (key.kind) {
      _KeyKind.letter => colors.key,
      _KeyKind.function => colors.functionKey,
      _KeyKind.action => colors.actionKey,
      _KeyKind.blank => null,
    };
    final content = key.kind == _KeyKind.action
        ? colors.actionLabel
        : colors.label;

    if (fill != null) {
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
      final shadow = colors.keyShadow;
      if (shadow != null) {
        canvas.drawRRect(
          rrect.shift(const Offset(0, 1)),
          Paint()..color = shadow,
        );
      }
      canvas.drawRRect(rrect, Paint()..color = fill);
    }

    if (key.icon != null) {
      _icon(
        icon: key.icon!,
        center: rect.center,
        color: content,
      );
      return;
    }

    final label = key.label;
    if (label == null) return;

    final isWord = label.length > 1 && key.sublabel == null;
    final TextPainter main = _text(
      text: label,
      fontSize: isWord ? 15 : fontSize,
      color: content,
    );
    final sub = key.sublabel == null || key.sublabel!.isEmpty
        ? null
        : _text(
            text: key.sublabel!,
            fontSize: 10,
            color: content,
            letterSpacing: 1.5,
          );
    final subHeight = key.sublabel == null ? 0.0 : 12.0;
    final top = rect.center.dy - (main.height + subHeight) / 2;

    main.paint(
      canvas,
      Offset(_snap(rect.center.dx - main.width / 2), _snap(top)),
    );
    sub?.paint(
      canvas,
      Offset(
        _snap(rect.center.dx - sub.width / 2),
        _snap(top + main.height - 1),
      ),
    );
  }

  TextPainter _text({
    required String text,
    required double fontSize,
    required Color color,
    double? letterSpacing,
  }) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontFamily: 'Roboto',
        letterSpacing: letterSpacing,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  Paint _iconPaint(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _icon({
    required _Icon icon,
    required Offset center,
    required Color color,
  }) {
    final path = switch (icon) {
      _Icon.shift =>
        Path()
          ..moveTo(center.dx, center.dy - 8)
          ..lineTo(center.dx + 8, center.dy)
          ..lineTo(center.dx + 4, center.dy)
          ..lineTo(center.dx + 4, center.dy + 7)
          ..lineTo(center.dx - 4, center.dy + 7)
          ..lineTo(center.dx - 4, center.dy)
          ..lineTo(center.dx - 8, center.dy)
          ..close(),
      _Icon.backspace =>
        Path()
          ..moveTo(center.dx - 10, center.dy)
          ..lineTo(center.dx - 4, center.dy - 7)
          ..lineTo(center.dx + 10, center.dy - 7)
          ..lineTo(center.dx + 10, center.dy + 7)
          ..lineTo(center.dx - 4, center.dy + 7)
          ..close()
          ..moveTo(center.dx, center.dy - 3)
          ..lineTo(center.dx + 6, center.dy + 3)
          ..moveTo(center.dx, center.dy + 3)
          ..lineTo(center.dx + 6, center.dy - 3),
      _Icon.enter =>
        Path()
          ..moveTo(center.dx + 8, center.dy - 7)
          ..lineTo(center.dx + 8, center.dy + 2)
          ..lineTo(center.dx - 8, center.dy + 2)
          ..moveTo(center.dx - 4, center.dy - 2)
          ..lineTo(center.dx - 8, center.dy + 2)
          ..lineTo(center.dx - 4, center.dy + 6),
      _Icon.space =>
        Path()
          ..moveTo(center.dx - 8, center.dy - 2)
          ..lineTo(center.dx - 8, center.dy + 3)
          ..lineTo(center.dx + 8, center.dy + 3)
          ..lineTo(center.dx + 8, center.dy - 2),
    };
    canvas.drawPath(path, _iconPaint(color));
  }
}
