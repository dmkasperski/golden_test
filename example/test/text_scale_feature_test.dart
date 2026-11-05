import 'package:material_ui/material_ui.dart';
import 'package:golden_test/golden_test.dart';
import 'package:golden_test_example/widgets/text_scale_feature.dart';

void main() {
  // Glyph antialiasing differs between macOS versions. This test puts more
  // text on screen than any other, so it is the first one to cross the global
  // 0.05 tolerance when the host that generated the goldens and the host that
  // checks them are not the same. Also set on #35, against master.
  goldenTestDifferenceTolerance(0.1);

  goldenTest(
    name: 'supportedTextScales',
    builder: (_) => const TextScaleFeature(),
    supportedTextScales: [1.0, ...iosAccessibilityTextScalePresets],
    supportedDevices: [Device.noInsets()],
    supportedThemes: [Brightness.light],
    supportedLocales: [Locale('en')],
  );
}
