import 'package:flutter/material.dart';

class DeviceFramePainter extends BoxPainter {
  final Brightness brightness;
  final EdgeInsets insets;

  DeviceFramePainter(this.brightness, this.insets);

  Color get color => brightness == Brightness.light
      ? Colors.black.withOpacity(0.2)
      : Colors.white;

  Paint get background => Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.fill
    ..color = Colors.blue
    ..strokeWidth = 0;

  Paint get linePaint => Paint()
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..color = color
    ..strokeWidth = 4;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (insets.left != 0) {
      canvas.drawRect(
          Rect.fromLTWH(0, insets.top, insets.left, size!.height - insets.top),
          background);
    }
    if (insets.right != 0) {
      canvas.drawRect(
          Rect.fromLTWH(size!.width - insets.right, insets.top, insets.right,
              size.height - insets.top),
          background);
    }
    if (insets.top != 0) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size!.width, insets.top), background);
    }

    if (insets.bottom != 0) {
      final offset = (insets.bottom - 4) / 2;
      canvas.drawLine(Offset(size!.width * 0.3, size.height - offset),
          Offset(size.width * 0.7, size.height - offset), linePaint);
    }
  }
}
