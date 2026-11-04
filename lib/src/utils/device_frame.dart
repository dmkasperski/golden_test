import 'dart:ui' show DisplayFeature;

import 'package:material_ui/material_ui.dart';
import 'package:golden_test/src/android_navigation.dart';
import 'package:golden_test/src/utils/device_frame_painter.dart';
import 'package:golden_test/src/utils/keyboard_painter.dart';

class DeviceFrame extends Decoration {
  final Brightness brightness;
  final EdgeInsets insets;
  final ResolvedKeyboard? keyboard;
  final List<DisplayFeature> displayFeatures;

  /// The platform whose chrome to draw. A device that states none keeps the
  /// one look this package drew before there were two.
  final TargetPlatform? platform;

  /// How an Android device shows its navigation, read only when [platform]
  /// is Android.
  final AndroidNavigation navigation;

  const DeviceFrame(
    this.brightness,
    this.insets, {
    this.keyboard,
    this.displayFeatures = const [],
    this.platform,
    this.navigation = AndroidNavigation.gesture,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return DeviceFramePainter(
      brightness,
      insets,
      keyboard: keyboard,
      displayFeatures: displayFeatures,
      platform: platform,
      navigation: navigation,
    );
  }
}
