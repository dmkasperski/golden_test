import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/src/device.dart';
import 'package:golden_test/src/local_file_comparator_with_tolerance.dart';

/// List of supported localizations for all golden tests created in the project.
///
/// If you want to run specific test on specific localization configure that test individually.
/// See [goldenTest] parameter `supportedLocales`
List<Locale> goldenTestSupportedLocales = [const Locale('en', 'US')];

/// List of localizations delegates for your own app.
///
/// ```dart
/// goldenTestLocalizationsDelegates = [YourAppLocalizations.delegate];
/// ```
///
/// `GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations` and
/// `GlobalCupertinoLocalizations` are appended automatically, so they do not
/// need to be listed or imported. Delegates listed here are resolved first,
/// so any of them can still be overridden.
List<LocalizationsDelegate<dynamic>> goldenTestLocalizationsDelegates = [];

/// The default device(s) used for all golden tests when no other device configuration is specified.
///
/// This is the device configuration used by default unless:
/// - The test explicitly provides `supportedDevices` parameter, OR
/// - The test has `supportMultipleDevices` flag enabled (which uses [goldenTestSupportedDevices] instead)
///
/// By default, tests run on [Device.iphone15Pro()].
/// You can customize this globally to match your primary design target device.
///
/// Example:
/// ```dart
/// goldenTestDefaultDevices = [Device.pixel9ProXL()]; // Use Pixel as default
/// ```
List<Device> goldenTestDefaultDevices = [Device.iphone15Pro()];

/// The list of devices used for multi-device testing when `supportMultipleDevices` is enabled.
///
/// This list is only used when:
/// - The test has `supportMultipleDevices: true` parameter, OR
/// - The global [goldenTestSupportMultipleDevices] flag is set to `true`
///
/// This allows you to maintain a separate set of devices for comprehensive multi-device testing
/// without affecting the default single-device testing behavior.
///
/// Example:
/// ```dart
/// goldenTestSupportedDevices = [
///   Device.iphone15Pro(),
///   Device.pixel9ProXL(),
///   Device.ipadPro12(),
/// ];
/// ```
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

/// List of text scale factors used for all golden tests when no per-test
/// configuration is provided.
///
/// Defaults to `[1.0]` — tests run at the default scale without a scale segment
/// in the golden path. Add more values (e.g. `2.0`) to run a text-scale matrix;
///
/// Per-test override via the `supportedTextScales` parameter takes precedence.
List<double> goldenTestSupportedTextScales = const [1.0];

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

/// Global flag to control whether golden tests should run on multiple devices by default.
///
/// When set to `true`, tests will run on all devices defined in [goldenTestSupportedDevices].
/// When set to `false`, tests will run only on the device specified in the `supportedDevices` parameter
/// or default to [Device.iphone15Pro()].
///
/// This reduces boilerplate by allowing you to set this once globally instead of
/// passing `supportMultipleDevices: true` to every test call.
bool goldenTestSupportMultipleDevices = false;

/// When true (default), [NetworkImage] loads during golden tests are resolved
/// with [goldenTestNetworkImageStubPng] instead of hitting the network,
/// preventing timeouts and ensuring deterministic output. Set to false in
/// `flutter_test_config.dart` to disable.
///
/// This covers every widget that paints through a [NetworkImage] —
/// `Image.network`, `FadeInImage`, a `DecorationImage` in a `BoxDecoration`,
/// and so on. It does not touch other `dart:io` HTTP traffic: `flutter_test`'s
/// own mock client keeps answering those with a 400.
///
/// It also does not govern image loaders registered through
/// [goldenTestImageLoaderSetups]; those run regardless of this flag, and decide
/// for themselves what to serve.
bool goldenTestStubNetworkImages = true;

/// Callbacks that install image-loading stubs, invoked at the start of every
/// golden test before the widget under test is built.
///
/// `golden_test` stubs [NetworkImage] itself (see
/// [goldenTestStubNetworkImages]), which covers `Image.network`, `FadeInImage`,
/// a `DecorationImage` in a `BoxDecoration`, and anything else that ultimately
/// paints a [NetworkImage]. Packages that load images through their own
/// machinery instead — a cache manager, a custom [ImageProvider], a bespoke
/// HTTP client — are out of reach, and register here.
///
/// Each callback runs once per test, so build fresh instances inside it rather
/// than capturing one: that keeps cache state from leaking between tests.
///
/// ```dart
/// // flutter_test_config.dart
/// goldenTestImageLoaderSetups.add(() {
///   SomePackage.imageLoader = MyInMemoryLoader();
/// });
/// ```
///
/// It is a list so that several packages can each register without clobbering
/// one another. Callbacks run in registration order.
///
/// These run even when [goldenTestStubNetworkImages] is false. A loader with
/// its own backend usually has no working un-stubbed mode inside Flutter's
/// fake-async test zone — it hangs rather than fails — so leaving it
/// unregistered is strictly worse than serving a placeholder.
///
/// For `cached_network_image`, use the `golden_test_cached_network_image`
/// package, which registers a working stub for you:
/// ```dart
/// import 'package:golden_test_cached_network_image/golden_test_cached_network_image.dart';
///
/// setupGoldenTestCachedNetworkImage();
/// ```
List<void Function()> goldenTestImageLoaderSetups = [];

/// The golden test difference tolerance at which tests are considered failing.
/// Ranges from 0-100(%), inclusive.
///
/// Default value: [0].
void goldenTestDifferenceTolerance(double diffTolerance) {
  if (goldenFileComparator is LocalFileComparator) {
    goldenFileComparator = LocalFileComparatorWithTolerance(
      Uri.parse(
        '${(goldenFileComparator as LocalFileComparator).basedir}/test.dart',
      ),
      diffTolerance,
    );
  }
}
