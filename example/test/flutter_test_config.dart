import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  await (FontLoader('Roboto')..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))).load();

  goldenTestSupportedDevices = [
    const Device.iphone15Pro(),
    const Device.ipadPro12(),
  ];

  return testMain();
}
