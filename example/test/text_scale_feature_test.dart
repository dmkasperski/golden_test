import 'package:flutter/material.dart';
import 'package:golden_test/golden_test.dart';
import 'package:golden_test_example/widgets/text_scale_feature.dart';

void main() {
  goldenTest(
    name: 'supportedTextScales',
    builder: (_) => const TextScaleFeature(),
    supportedTextScales: [1.0, ...iosAccessibilityTextScalePresets],
    supportedDevices: [Device.noInsets()],
    supportedThemes: [Brightness.light],
    supportedLocales: [Locale('en')],
  );
}
