import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/src/config.dart';
import 'package:golden_test/src/device.dart';
import 'package:golden_test/src/utils/device_frame.dart';
import 'package:meta/meta.dart';

/// The goldenTest method is designed to facilitate automated UI testing
/// of Flutter widgets by comparing their rendered output against a predefined golden image.
/// This ensures consistent visual behavior across different devices, theme modes, and locales.
///
/// Parameters
/// * [name]: A descriptive string that identifies the test case.
///
/// * [builder]: A WidgetBuilder function that constructs the widget to be tested.
///
/// * [supportedDevices]: An optional list specifying the devices on which the test should be run.
///   Defaults to [Device.iphone15Pro()].
///
/// * [supportMultipleDevices]: A boolean indicating whether the test should run on multiple devices simultaneously.
///   Defaults to false.
///
/// * [supportedModes]: An optional list specifying the Brightness on which the test should be run.
///   Defaults to an empty list. Global config defaults to light and dark mode.
///
/// * [supportedLocales]: An optional list of Locale specifying the locales in which the test should be run.
///   Defaults to an empty list. Global config defaults `en_US`.
///
/// * [localizationsDelegates]: An optional list of LocalizationsDelegate objects providing localization support for the test.
///
/// * [setup]: An optional asynchronous function that can be used to perform setup tasks before the test runs.
///
/// * [tearDown]: An optional asynchronous function that can be used to perform cleanup tasks after the test runs.
///
/// * [action]: An optional asynchronous function that can be used to perform additional actions on the widget tester during the test.
///
/// * [skip]: A boolean indicating whether the test should be skipped.
///   Defaults to false.
///
/// {@tool snippet}
/// ```dart
///   goldenTest(
///     name: 'Example',
///     builder: (_) => Scaffold(
///       body: Center(
///       child: Container(
///         height: 100,
///         color: Colors.red,
///         child: const Center(child: Text('Example')),
///         ),
///       ),
///     ),
///   );
/// ```
/// {@end-tool}
@isTest
void goldenTest({
  required String name,
  required WidgetBuilder builder,
  List<Device> supportedDevices = const [Device.iphone15Pro()],
  bool supportMultipleDevices = false,
  List<Brightness> supportedThemes = const [],
  List<Locale> supportedLocales = const [],
  List<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Future<void> Function(WidgetTester tester)? setup,
  Future<void> Function(WidgetTester tester)? tearDown,
  Future<void> Function(WidgetTester tester)? action,
  bool skip = false,
}) {
  assert(supportedDevices.isNotEmpty || goldenTestSupportedDevices.isNotEmpty,
      '$supportedDevices and $goldenTestSupportedDevices both cannot be empty');
  final testDevices =
      supportMultipleDevices ? goldenTestSupportedDevices : supportedDevices;

  assert(supportedThemes.isNotEmpty || goldenTestSupportedThemes.isNotEmpty,
      '$supportedThemes and $goldenTestSupportedThemes both cannot be empty');
  final testModes =
      supportedThemes.isNotEmpty ? supportedThemes : goldenTestSupportedThemes;

  assert(supportedLocales.isNotEmpty || goldenTestSupportedLocales.isNotEmpty,
      '$supportedLocales and $goldenTestSupportedLocales both cannot be empty');
  final testLocales = supportedLocales.isNotEmpty
      ? supportedLocales
      : goldenTestSupportedLocales;

  for (final locale in testLocales) {
    for (final mode in testModes) {
      for (final device in testDevices) {
        testWidgets(name, (WidgetTester tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = mode;
          debugDisableShadows = false;
          _setupSize(device, tester);
          try {
            if (globalSetup != null) {
              globalSetup!(locale);
            }

            if (setup != null) {
              setup(tester);
            }

            final widget = _themedWidget(
              child: Container(
                alignment: Alignment.topLeft,
                child: Builder(builder: builder),
              ),
              theme: mode == Brightness.light
                  ? goldenTestThemeInTests
                  : goldenTestDarkThemeInTests,
              supportedLocales: [locale],
              localizationsDelegates:
                  localizationsDelegates ?? goldenTestLocalizationsDelegates,
            );

            final edgeInsets = EdgeInsets.fromViewPadding(
                tester.view.padding, tester.view.devicePixelRatio);
            await tester.pumpWidget(
              DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: DeviceFrame(mode, edgeInsets),
                child: widget,
              ),
            );

            if (action != null) {
              await tester.pumpAndSettle();
              await action(tester);
            }

            await tester.pumpAndSettle();
            await _precacheImages(tester);

            await _takeAScreenshot(supportMultipleDevices
                ? 'goldens/${locale.languageCode}/${mode.name}/${device.name}/$name.png'
                : 'goldens/${locale.languageCode}/${mode.name}/$name.png');
          } finally {
            debugDisableShadows = true;
            if (tearDown != null) {
              tearDown(tester);
            }
          }
        }, skip: skip);
      }
    }
  }
}

/// Apply theme to pumped Widget.
Widget _themedWidget({
  required Widget child,
  required ThemeData theme,
  required List<Locale> supportedLocales,
  List<LocalizationsDelegate<dynamic>>? localizationsDelegates,
}) =>
    MaterialApp(
      theme: theme,
      color: Colors.white,
      debugShowCheckedModeBanner: false,
      locale: supportedLocales.first,
      supportedLocales: supportedLocales,
      localizationsDelegates: localizationsDelegates,
      localeResolutionCallback: ((Locale? local, Iterable<Locale> locales) =>
          supportedLocales.first),
      onUnknownRoute: (settings) => _unknownPage(settings),
      home: Scaffold(body: child),
    );

/// Sets size of test device
void _setupSize(Device device, WidgetTester tester) {
  tester.view.physicalSize = Size(device.width * device.devicePixelRatio,
      device.height * device.devicePixelRatio);
  tester.view.devicePixelRatio = device.devicePixelRatio;
  FakeViewPadding padding = FakeViewPadding(
      left: device.insets.left * device.devicePixelRatio,
      top: device.insets.top * device.devicePixelRatio,
      right: device.insets.right * device.devicePixelRatio,
      bottom: device.insets.bottom * device.devicePixelRatio);
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
}

Future<void> _takeAScreenshot(dynamic key, {int? version}) async =>
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile(key, version: version));

/// Fallback for route generator
PageRouteBuilder _unknownPage(RouteSettings settings) => PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, _, __) => Text(
          'Unknown route ${settings.toString()}',
          style: Theme.of(context).textTheme.bodyLarge),
    );



/// Adapted from the Alchemist library
/// (https://github.com/Betterment/alchemist/blob/0ef689574ea40f81b2268576ce7be33032e12da8/lib/src/pumps.dart#L43).
/// Grateful for the clear and effective solution provided there.
///
/// Ensures that the images for all [Image], [FadeInImage], and [DecoratedBox] 
/// widgets are loaded before the golden file is generated.
Future<void> _precacheImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    final images = <Future<void>>[];
    for (final element in find.byType(Image).evaluate()) {
      final widget = element.widget as Image;
      final image = widget.image;
      images.add(precacheImage(image, element));
    }
    for (final element in find.byType(FadeInImage).evaluate()) {
      final widget = element.widget as FadeInImage;
      final image = widget.image;
      images.add(precacheImage(image, element));
    }
    for (final element in find.byType(DecoratedBox).evaluate()) {
      final widget = element.widget as DecoratedBox;
      final decoration = widget.decoration;
      if (decoration is BoxDecoration && decoration.image != null) {
        final image = decoration.image!.image;
        images.add(precacheImage(image, element));
      }
    }
    await Future.wait(images);
  });
  await tester.pumpAndSettle();
}