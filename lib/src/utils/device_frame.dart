import 'package:material_ui/material_ui.dart';
import 'package:golden_test/src/utils/device_frame_painter.dart';
import 'package:golden_test/src/utils/keyboard_painter.dart';

class DeviceFrame extends Decoration {
  final Brightness brightness;
  final EdgeInsets insets;
  final ResolvedKeyboard? keyboard;

  const DeviceFrame(this.brightness, this.insets, {this.keyboard});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return DeviceFramePainter(brightness, insets, keyboard: keyboard);
  }
}
