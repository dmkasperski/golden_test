import 'dart:math';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:golden_test/src/utils/keyboard_painter.dart';
import 'package:material_ui/material_ui.dart';

/// One degree in radians, so that measured angles can be written as read.
const double _degrees = pi / 180;
const double _halfPi = pi / 2;

/// The radius of the Duo status indicator's ring, along the middle of its
/// stroke. Its signal dots sit on the same circle.
const double _indicatorRadius = 18.8;

class DeviceFramePainter extends BoxPainter {
  final Brightness brightness;
  final EdgeInsets insets;
  final ResolvedKeyboard? keyboard;
  final List<DisplayFeature> displayFeatures;

  DeviceFramePainter(
    this.brightness,
    this.insets, {
    this.keyboard,
    this.displayFeatures = const [],
  });

  Color get _contentColor =>
      brightness == Brightness.light ? Colors.black : Colors.white;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final bgPaint = Paint()..color = _backgroundColor;
    final double devicePixelRatio = configuration.devicePixelRatio ?? 1;

    for (final DisplayFeature feature in displayFeatures) {
      if (feature.type != DisplayFeatureType.cutout &&
          feature.state == DisplayFeatureState.postureHalfOpened) {
        _drawFoldEdges(canvas, feature.bounds, devicePixelRatio);
      }
    }

    final List<Rect> cutouts = [
      for (final DisplayFeature feature in displayFeatures)
        if (feature.type == DisplayFeatureType.cutout) feature.bounds,
    ];
    if (cutouts.isNotEmpty) {
      // A device whose status bar is a cluster, such as iPhone Duo. The rest
      // of the insets, such as its strip, is the app's to draw in.
      _drawStatusClusters(canvas, cutouts);
    } else {
      if (insets.left != 0) {
        canvas.drawRect(
          Rect.fromLTWH(0, insets.top, insets.left, size.height - insets.top),
          bgPaint,
        );
      }

      if (insets.right != 0) {
        canvas.drawRect(
          Rect.fromLTWH(
            size.width - insets.right,
            insets.top,
            insets.right,
            size.height - insets.top,
          ),
          bgPaint,
        );
      }

      if (insets.top != 0) {
        _drawStatusBar(canvas, size);
      }
    }

    final ResolvedKeyboard? keyboard = this.keyboard;
    if (keyboard != null) {
      paintKeyboard(
        canvas: canvas,
        area: Rect.fromLTRB(
          0,
          size.height - keyboard.height,
          size.width,
          size.height,
        ),
        keyboard: keyboard,
        brightness: brightness,
        devicePixelRatio: configuration.devicePixelRatio ?? 1,
      );
    }

    if (insets.bottom != 0) {
      _drawHomeIndicator(canvas, size);
    }
  }

  Color get _backgroundColor =>
      brightness == Brightness.light ? Colors.white : Colors.black;

  void _drawStatusBar(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, insets.top),
      Paint()..color = _backgroundColor,
    );

    final color = _contentColor;
    final centerY = insets.top / 2;

    _drawTime(canvas, centerY, color);
    _drawBattery(canvas, size.width, centerY, color);
    _drawWifi(canvas, size.width, centerY, color);
    _drawSignalBars(canvas, size.width, centerY, color);
  }

  /// Marks the edges of a fold or hinge while the device is half open, with
  /// solid lines aligned to physical pixels and drawn without antialiasing,
  /// so that they rasterise the same on every machine.
  void _drawFoldEdges(Canvas canvas, Rect fold, double devicePixelRatio) {
    double snap(double value) =>
        (value * devicePixelRatio).roundToDouble() / devicePixelRatio;
    final double thickness = 2 / devicePixelRatio;
    final paint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFF8E8E93);
    final Rect snapped = Rect.fromLTRB(
      snap(fold.left),
      snap(fold.top),
      snap(fold.right),
      snap(fold.bottom),
    );

    if (snapped.height >= snapped.width) {
      canvas
        ..drawRect(
          Rect.fromLTRB(
            snapped.left,
            snapped.top,
            snapped.left + thickness,
            snapped.bottom,
          ),
          paint,
        )
        ..drawRect(
          Rect.fromLTRB(
            snapped.right - thickness,
            snapped.top,
            snapped.right,
            snapped.bottom,
          ),
          paint,
        );
    } else {
      canvas
        ..drawRect(
          Rect.fromLTRB(
            snapped.left,
            snapped.top,
            snapped.right,
            snapped.top + thickness,
          ),
          paint,
        )
        ..drawRect(
          Rect.fromLTRB(
            snapped.left,
            snapped.bottom - thickness,
            snapped.right,
            snapped.bottom,
          ),
          paint,
        );
    }
  }

  /// Draws the status clusters among [cutouts] with the time, signal, Wi-Fi
  /// and battery in them, and the cameras among them.
  void _drawStatusClusters(Canvas canvas, List<Rect> cutouts) {
    bool isCamera(Rect rect) => rect.longestSide < 50;
    final List<Rect> cameras = cutouts.where(isCamera).toList();
    final color = _contentColor;

    // Nothing fills a cluster: the device draws these over whatever the app
    // paints there. Measured on the simulator, the strip carries the app's
    // own background from the top edge of the screen down to the bottom.
    for (final Rect cluster in cutouts.where((rect) => !isCamera(rect))) {
      if (cluster.width >= cluster.height) {
        // A row, as in the top right corner of the inner display in portrait.
        canvas.save();
        canvas.translate(cluster.left, cluster.top);
        final double centerY = cluster.height / 2;
        _drawTime(canvas, centerY, color, centerX: 30);
        _drawBattery(canvas, cluster.width, centerY, color);
        _drawWifi(canvas, cluster.width, centerY, color);
        _drawSignalBars(canvas, cluster.width, centerY, color);
        canvas.restore();
        continue;
      }

      // A column in the strip. Measured on the iPhone Duo simulator
      // (iOS 27.2) on the cover display, where the cluster is 84 x 170 and
      // the camera is 37 wide, 29.3 in from the top right corner:
      //
      //   camera     y  29.3 ..  66.0
      //   time       y  86.7 ..  98.3
      //   indicator  y 109.7 .. 150.5, its ring centred on y 130.3
      //
      // All three are centred on the camera's axis rather than on the strip,
      // which puts them 47.8 in from the right edge of the screen.
      final Rect? camera = cameras
          .where(cluster.overlaps)
          .fold<Rect?>(null, (first, next) => first ?? next);
      final double centreX = camera?.center.dx ?? cluster.center.dx;
      final double timeY = (camera?.bottom ?? cluster.top) + 26.5;
      final double indicatorY = timeY + 37.8;
      if (indicatorY + _indicatorRadius + 2 > cluster.bottom) {
        continue;
      }

      _drawTime(canvas, timeY, color, centerX: centreX, fontSize: 15);
      _drawCombinedIndicator(canvas, Offset(centreX, indicatorY), color);
    }

    // The lens fills its reserved region exactly, and stays black in both
    // brightnesses, as it is a hole in the display rather than a drawing.
    for (final Rect camera in cameras) {
      canvas.drawOval(camera, Paint()..color = const Color(0xFF000000));
    }
  }

  /// The one indicator iPhone Duo shows in its strip in place of separate
  /// signal, Wi-Fi and battery icons: a ring open at the bottom, Wi-Fi inside
  /// it, and the signal as four dots sitting in the opening, on the ring's
  /// own circle. Measured on the simulator, where the ring is 40.6 across.
  void _drawCombinedIndicator(Canvas canvas, Offset centre, Color color) {
    // Half the opening at the bottom of the ring, where the signal dots go.
    const double gap = 52 * _degrees;

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: _indicatorRadius),
      _halfPi + gap,
      2 * pi - 2 * gap,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3,
    );

    // Wi-Fi inside the ring: three arcs about a common origin, the innermost
    // so short that it reads as the dot of the glyph.
    for (final double r in const [1.4, 5.45, 9.95]) {
      canvas.drawArc(
        Rect.fromCircle(center: centre.translate(0, 4.5), radius: r),
        -_halfPi - 64 * _degrees,
        128 * _degrees,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.7,
      );
    }

    // The signal, as four dots spaced along the opening.
    for (final double angle in const [-31.5, -10.5, 10.5, 31.5]) {
      canvas.drawCircle(
        centre.translate(
          _indicatorRadius * sin(angle * _degrees),
          _indicatorRadius * cos(angle * _degrees),
        ),
        1.7,
        Paint()..color = color.withAlpha(64),
      );
    }
  }

  void _drawTime(
    Canvas canvas,
    double centerY,
    Color color, {
    double? centerX,
    double fontSize = 15,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: '9:41',
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(
        centerX == null ? 24 : centerX - painter.width / 2,
        centerY - painter.height / 2,
      ),
    );
  }

  void _drawBattery(
    Canvas canvas,
    double screenWidth,
    double centerY,
    Color color,
  ) {
    const rightPadding = 14.0;
    const bodyWidth = 25.0;
    const bodyHeight = 12.0;
    final x = screenWidth - rightPadding - bodyWidth;
    final y = centerY - bodyHeight / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, bodyWidth, bodyHeight),
        const Radius.circular(2.5),
      ),
      Paint()
        ..color = color.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    const pad = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x + pad,
          y + pad,
          (bodyWidth - pad * 2) * 0.8,
          bodyHeight - pad * 2,
        ),
        const Radius.circular(1.5),
      ),
      Paint()..color = color,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(screenWidth - rightPadding + 1.5, centerY - 2, 2, 4),
        const Radius.circular(1),
      ),
      Paint()..color = color.withAlpha(80),
    );
  }

  void _drawWifi(
    Canvas canvas,
    double screenWidth,
    double centerY,
    Color color,
  ) {
    const rightPadding = 14.0;
    const batteryWidth = 25.0;
    final wifiCenterX = screenWidth - rightPadding - batteryWidth - 12;
    final wifiDotY = centerY + 4;

    canvas.drawCircle(
      Offset(wifiCenterX, wifiDotY),
      1.5,
      Paint()..color = color,
    );

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    for (var i = 1; i <= 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(wifiCenterX, wifiDotY), radius: 3.0 * i),
        -pi * 3 / 4,
        pi / 2,
        false,
        arcPaint,
      );
    }
  }

  void _drawSignalBars(
    Canvas canvas,
    double screenWidth,
    double centerY,
    Color color,
  ) {
    const rightPadding = 14.0;
    const batteryWidth = 25.0;
    const wifiGap = 12.0;
    final signalRight =
        screenWidth - rightPadding - batteryWidth - wifiGap - 14;

    const barCount = 4;
    const barWidth = 3.0;
    const barGap = 1.5;
    const maxH = 11.0;
    const minH = 3.0;
    final bottomY = centerY + maxH / 2;

    for (var i = 0; i < barCount; i++) {
      final h = minH + (maxH - minH) * (i / (barCount - 1));
      final x =
          signalRight - (barCount - 1 - i) * (barWidth + barGap) - barWidth;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, bottomY - h, barWidth, h),
          const Radius.circular(0.75),
        ),
        Paint()..color = color,
      );
    }
  }

  void _drawHomeIndicator(Canvas canvas, Size size) {
    final y = size.height - insets.bottom / 2 + 2;
    final Rect indicator = Rect.fromCenter(
      center: Offset(size.width / 2, y),
      width: 134,
      height: 5,
    );

    // Centred on the window, it lands on the crease of a device held half
    // open like a book. A device puts it somewhere else, and nothing
    // documents where, so draw nothing rather than invent a position. The
    // bottom inset is still reserved either way.
    for (final DisplayFeature feature in displayFeatures) {
      if (feature.type != DisplayFeatureType.cutout &&
          feature.state == DisplayFeatureState.postureHalfOpened &&
          feature.bounds.overlaps(indicator)) {
        return;
      }
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(indicator, const Radius.circular(2.5)),
      Paint()..color = _contentColor.withAlpha(80),
    );
  }
}
