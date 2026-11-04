import 'dart:math';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:golden_test/src/android_navigation.dart';
import 'package:golden_test/src/utils/keyboard_painter.dart';
import 'package:material_ui/material_ui.dart';

/// One degree in radians, so that measured angles can be written as read.
const double _degrees = pi / 180;
const double _halfPi = pi / 2;

/// How far in from the edges of the screen Android's status bar sets its
/// clock and its icons.
const double _androidStatusBarPadding = 16;

/// Half the width of the punch-hole camera, as drawn.
///
/// Android reports a cutout as the region it reserves, which is wider and
/// taller than the hole itself — on a Pixel 6a a 55.2 x 50.3 region around a
/// hole of roughly 24 across. The region is what the app has to lay out
/// around and what [DisplayFeature] carries; this is only what the frame
/// paints inside it.
const double _androidLensRadius = 12;

/// The radius of the Duo status indicator's ring, along the middle of its
/// stroke. Its signal dots sit on the same circle.
const double _indicatorRadius = 18.8;

class DeviceFramePainter extends BoxPainter {
  final Brightness brightness;
  final EdgeInsets insets;
  final ResolvedKeyboard? keyboard;
  final List<DisplayFeature> displayFeatures;

  /// The platform the device runs, which decides the chrome drawn around the
  /// app: the layout of the status bar, and whether the bottom inset carries
  /// an iOS home indicator or an Android navigation bar.
  ///
  /// A device that states no platform keeps the one look this package drew
  /// before there were two, so its goldens do not move.
  final TargetPlatform? platform;

  /// How the Android device shows its navigation. Read only when [platform]
  /// is Android.
  final AndroidNavigation navigation;

  DeviceFramePainter(
    this.brightness,
    this.insets, {
    this.keyboard,
    this.displayFeatures = const [],
    this.platform,
    this.navigation = AndroidNavigation.gesture,
  });

  /// Whether the device draws Android's own chrome. A device with no platform
  /// keeps the iOS-shaped chrome this package has always drawn.
  bool get _isAndroid => switch (platform) {
    null || TargetPlatform.iOS || TargetPlatform.macOS => false,
    TargetPlatform.android ||
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.windows => true,
  };

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
    // A cutout means two different things. On an iOS foldable it is the
    // status cluster, which replaces the status bar outright. On Android it
    // is the punch-hole camera, a hole in an ordinary status bar that is
    // drawn around it.
    if (cutouts.isNotEmpty && !_isAndroid) {
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
        if (_isAndroid) {
          _drawAndroidStatusBar(canvas, size);
        } else {
          _drawStatusBar(canvas, size);
        }
      }

      // The punch-hole camera, which Android reserves a region for and the
      // app has to draw around.
      if (_isAndroid) {
        for (final Rect cutout in cutouts) {
          _drawLens(
            canvas,
            Rect.fromCircle(center: cutout.center, radius: _androidLensRadius),
          );
        }
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
      if (_isAndroid) {
        _drawAndroidNavigation(canvas, size);
      } else {
        _drawHomeIndicator(canvas, size);
      }
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
    _drawIosStatusIcons(canvas, size.width, centerY, color);
  }

  /// Android's status bar: the clock hard against the left edge, and the
  /// status icons against the right, in Android's own order.
  ///
  /// iOS centres its clock in the left half of the bar; Android does not,
  /// which is the clearest difference between the two at a glance.
  void _drawAndroidStatusBar(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, insets.top),
      Paint()..color = _backgroundColor,
    );

    final color = _contentColor;
    final centerY = insets.top / 2;

    _drawTime(canvas, centerY, color, left: _androidStatusBarPadding);
    _drawAndroidStatusIcons(canvas, size.width, centerY, color);
  }

  /// The signal, Wi-Fi and battery of an iOS status bar, laid out from the
  /// right edge of [width].
  void _drawIosStatusIcons(
    Canvas canvas,
    double width,
    double centerY,
    Color color,
  ) {
    _drawBattery(canvas, width - 10.5, centerY, color);
    _drawWifi(canvas, width - 42, centerY, color);
    _drawSignalBars(canvas, width - 65, centerY, color);
  }

  /// The same icons as an Android status bar orders them, laid out from the
  /// right edge of [width]: the battery last on the right, then the signal,
  /// then Wi-Fi. iOS puts Wi-Fi between the signal and the battery instead.
  void _drawAndroidStatusIcons(
    Canvas canvas,
    double width,
    double centerY,
    Color color,
  ) {
    const double gap = 7;
    double right = width - _androidStatusBarPadding;
    right = _drawBattery(canvas, right, centerY, color) - gap;
    right = _drawSignalBars(canvas, right, centerY, color) - gap;
    _drawWifi(canvas, right, centerY, color);
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
        _drawIosStatusIcons(canvas, cluster.width, centerY, color);
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

    // The lens fills its reserved region exactly here, because that is what
    // the iPhone Duo simulator reports: a region the size of the camera.
    for (final Rect camera in cameras) {
      _drawLens(canvas, camera);
    }
  }

  /// A camera lens, which stays black in both brightnesses because it is a
  /// hole in the display rather than something drawn on it.
  void _drawLens(Canvas canvas, Rect bounds) =>
      canvas.drawOval(bounds, Paint()..color = const Color(0xFF000000));

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
    double left = 24,
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
        centerX == null ? left : centerX - painter.width / 2,
        centerY - painter.height / 2,
      ),
    );
  }

  /// The battery, with the right edge of its cap at [right]. Returns the x of
  /// its left edge, so a cluster can be laid out from the right.
  double _drawBattery(
    Canvas canvas,
    double right,
    double centerY,
    Color color,
  ) {
    const bodyWidth = 25.0;
    const bodyHeight = 12.0;
    const capWidth = 2.0;
    const capGap = 1.5;
    final bodyRight = right - capWidth - capGap;
    final x = bodyRight - bodyWidth;
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
        Rect.fromLTWH(right - capWidth, centerY - 2, capWidth, 4),
        const Radius.circular(1),
      ),
      Paint()..color = color.withAlpha(80),
    );

    return x;
  }

  /// Wi-Fi, with the right edge of its box at [right]. Returns the x of its
  /// left edge.
  double _drawWifi(Canvas canvas, double right, double centerY, Color color) {
    const double halfWidth = 9;
    final wifiCenterX = right - halfWidth;
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

    return wifiCenterX - halfWidth;
  }

  /// The signal bars, with the right edge of the tallest at [right]. Returns
  /// the x of the left edge of the shortest.
  double _drawSignalBars(
    Canvas canvas,
    double right,
    double centerY,
    Color color,
  ) {
    const barCount = 4;
    const barWidth = 3.0;
    const barGap = 1.5;
    const maxH = 11.0;
    const minH = 3.0;
    final bottomY = centerY + maxH / 2;

    for (var i = 0; i < barCount; i++) {
      final h = minH + (maxH - minH) * (i / (barCount - 1));
      final x = right - (barCount - 1 - i) * (barWidth + barGap) - barWidth;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, bottomY - h, barWidth, h),
          const Radius.circular(0.75),
        ),
        Paint()..color = color,
      );
    }

    return right - (barCount - 1) * (barWidth + barGap) - barWidth;
  }

  /// Android's navigation over the bottom inset: one handle for gestures, or
  /// back, home and recents for the three-button bar.
  ///
  /// Nothing fills the bar behind them. Modern Android draws edge to edge and
  /// lets the app's own background show through, and a device that dims it
  /// instead does so with a separate system overlay, independent of the mode.
  void _drawAndroidNavigation(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = _contentColor.withAlpha(0xDD);
    final double centerY = size.height - insets.bottom / 2;

    switch (navigation) {
      case AndroidNavigation.gesture:
        final Rect handle = Rect.fromCenter(
          center: Offset(size.width / 2, centerY),
          width: 108,
          height: 4,
        );
        if (_landsOnHalfOpenFold(handle)) {
          return;
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(handle, const Radius.circular(2)),
          paint,
        );

      case AndroidNavigation.threeButton:
        // Evenly spaced across the bar, as stock Android places them.
        final double back = size.width / 4;
        final double home = size.width / 2;
        final double recents = size.width * 3 / 4;

        canvas.drawPath(
          Path()
            ..moveTo(back - 7, centerY)
            ..lineTo(back + 7, centerY - 8)
            ..lineTo(back + 7, centerY + 8)
            ..close(),
          paint,
        );
        canvas.drawCircle(Offset(home, centerY), 7.5, paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(recents, centerY),
              width: 14,
              height: 14,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
    }
  }

  /// Whether [bounds] land on a fold or hinge the device is held half open
  /// at, where nothing should be drawn.
  ///
  /// A handle or an indicator centred on the window lands on the crease of a
  /// device held half open like a book. A device puts it somewhere else, and
  /// nothing documents where, so draw nothing rather than invent a position.
  /// The bottom inset is still reserved either way.
  bool _landsOnHalfOpenFold(Rect bounds) {
    for (final DisplayFeature feature in displayFeatures) {
      if (feature.type != DisplayFeatureType.cutout &&
          feature.state == DisplayFeatureState.postureHalfOpened &&
          feature.bounds.overlaps(bounds)) {
        return true;
      }
    }
    return false;
  }

  void _drawHomeIndicator(Canvas canvas, Size size) {
    final y = size.height - insets.bottom / 2 + 2;
    final Rect indicator = Rect.fromCenter(
      center: Offset(size.width / 2, y),
      width: 134,
      height: 5,
    );

    if (_landsOnHalfOpenFold(indicator)) {
      return;
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(indicator, const Radius.circular(2.5)),
      Paint()..color = _contentColor.withAlpha(80),
    );
  }
}
