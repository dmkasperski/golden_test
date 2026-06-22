import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';
import 'package:golden_test_example/l10n/app_localizations.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  await (FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('assets/fonts/MaterialIcons-Regular.otf')))
      .load();

  goldenTestSupportedDevices = [
    const Device.iphone15Pro(),
    const Device.ipadPro12(),
  ];

  goldenTestSupportedLocales = AppLocalizations.supportedLocales;

  goldenTestLocalizationsDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  return testMain();
}
