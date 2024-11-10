import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/src/device.dart';
import 'package:golden_test/src/local_file_comparator_with_tolerance.dart';

/// List of supported localizations for all golden tests created in the project.
///
/// If you want to run specific test on specific localization configure that test individually.
/// See [goldenTest] parameter `supportedLocales`
List<Locale> goldenTestSupportedLocales = [const Locale('en', 'US')];

/// List of localizations delegates.
///
/// ```[
///     YourAppLocalizations.delegate,
///     ...
///     GlobalMaterialLocalizations.delegate,
///     GlobalWidgetsLocalizations.delegate,
///     GlobalCupertinoLocalizations.delegate,
///   ]
/// ```
List<LocalizationsDelegate<dynamic>> goldenTestLocalizationsDelegates = [];

/// List of supported localizations for all golden tests created in the project while
/// flag `supportMultipleDevices` is set to `true` for [goldenTest].
///
/// By default all tests run only on [Device] that represents Iphone 15 Pro.
///
/// If you want to run specific test on different devices configure that test individually.
/// See [goldenTest] parameter `supportedDevices`
List<Device> goldenTestSupportedDevices = [
  Device.noInsets(),
  Device.iphone15Pro(),
  Device.pixel9ProXL(),
  Device.ipadPro12(),
  Device.browser(),
];

/// List of supported theme modes for all golden tests created in the project.
///
/// If you want to run specific test on specific theme mode configure that test individually.
/// See [goldenTest] parameter `supportedModes`
List<Brightness> goldenTestSupportedThemes = [
  Brightness.light,
  Brightness.dark,
];

/// A default ThemeData of your application - light mode.
ThemeData goldenTestThemeInTests = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.red,
    brightness: Brightness.light,
  ),
);

/// A default ThemeData of your application - dark mode.
///
/// If not set it's the same as light mode.
/// If your app doesn't support dark mode or you don't want to generate goldens
/// for dark mode set [goldenTestSupportedThemes].
ThemeData goldenTestDarkThemeInTests = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.red,
    brightness: Brightness.dark,
  ),
);

/// A callback to globally setup all golden tests with any project specific configuration.
///
/// A flag to control whether infinite animations should be disabled during Golden Tests.
///
/// Note:
/// 1. You can use it to turn on flag which controls what UI is displayed
/// i.e. to disable animations in tests or replace images with placeholders, hiding embedded UI, or
/// with external dependencies.
/// 2. If your app use [Intl] for localizations and which hardcodes system locale [Intl.systemLocale]
/// to `en_US`. So to correctly translate localizations inside [Intl] you need to override in your project.
/// ```
///   globalSetup = (locale) async => Intl.defaultLocale = locale.languageCode;
/// ```
Future<void> Function(Locale locale)? globalSetup;

/// The golden test difference tolerance at which tests are considered failing.
/// Ranges from 0-100(%), inclusive.
///
/// Default value: [0].
void goldenTestDifferenceTolerance(double diffTolerance) {
  if (goldenFileComparator is LocalFileComparator) {
    goldenFileComparator = LocalFileComparatorWithTolerance(
      Uri.parse(
          '${(goldenFileComparator as LocalFileComparator).basedir}/test.dart'),
      diffTolerance,
    );
  }
}
