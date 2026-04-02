import 'dart:math';
import 'package:flutter/material.dart';

class DeviceFramePainter extends BoxPainter {
  final Brightness brightness;
  final EdgeInsets insets;

  DeviceFramePainter(this.brightness, this.insets);

  Color get _contentColor =>
      brightness == Brightness.light ? Colors.black : Colors.white;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final bgPaint = Paint()..color = _backgroundColor;

    if (insets.left != 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, insets.top, insets.left, size.height - insets.top),
        bgPaint,
      );
    }

    if (insets.right != 0) {
      canvas.drawRect(
        Rect.fromLTWH(size.width - insets.right, insets.top, insets.right,
            size.height - insets.top),
        bgPaint,
      );
    }

    if (insets.top != 0) {
      _drawStatusBar(canvas, size);
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

  void _drawTime(Canvas canvas, double centerY, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: '9:41',
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(canvas, Offset(24, centerY - painter.height / 2));
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
        Rect.fromCircle(
          center: Offset(wifiCenterX, wifiDotY),
          radius: 3.0 * i,
        ),
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
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, y),
          width: 134,
          height: 5,
        ),
        const Radius.circular(2.5),
      ),
      Paint()..color = _contentColor.withAlpha(80),
    );
  }
}
