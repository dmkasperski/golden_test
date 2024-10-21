import 'package:flutter/material.dart';
import 'package:golden_test/src/utils/device_frame_painter.dart';

class DeviceFrame extends Decoration {
  final Brightness brightness;
  final EdgeInsets insets;

  const DeviceFrame(
    this.brightness,
    this.insets,
  );

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return DeviceFramePainter(brightness, insets);
  }
}
