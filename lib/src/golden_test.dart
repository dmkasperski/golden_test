import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/src/consts.dart';
import 'package:golden_test/src/device.dart';
import 'package:golden_test/src/utils/device_frame.dart';
import 'package:meta/meta.dart';

@isTest
void goldenTest({
  required String name,
  required WidgetBuilder builder,
  List<Device> devices = const [Device.iphone15Pro()],
  bool supportMultipleDevices = false,
  List<Brightness> supportedModes = const [],
  List<Locale>? supportedLocales,
  List<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Future<void> Function(WidgetTester tester)? setup,
  Future<void> Function(WidgetTester tester)? tearDown,
  Future<void> Function(WidgetTester tester)? action,
  bool skip = false,
}) {
  final testModes = supportedModes.isNotEmpty ? supportedModes : goldenTestSupportedModes;
  final testDevices = supportMultipleDevices ? goldenTestSupportedDevices : devices;

  for (final mode in testModes) {
    for (final device in testDevices) {
      testWidgets(name, (WidgetTester tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = mode;
        debugDisableShadows = false;
        disableInfiniteAnimationsInGoldenTests = true;
        _setupSize(device, tester);
        try {
          if (setup != null) {
            setup(tester);
          }

          final widget = _themedWidget(
            Container(
              alignment: Alignment.topLeft,
              child: Builder(builder: builder),
            ),
            mode == Brightness.light ? goldenTestThemeInTests : goldenTestDarkThemeInTests,
            supportedLocales ?? goldenTestSupportedLocales,
            localizationsDelegates: localizationsDelegates ?? goldenTestLocalizationsDelegates,
          );

          final edgeInsets = EdgeInsets.fromViewPadding(tester.view.padding, tester.view.devicePixelRatio);
          await tester.pumpWidget(
            DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: DeviceFrame(mode, edgeInsets),
              child: widget,
            ),
          );

          if (action != null) {
            await tester.pumpAndSettle();
            action(tester);
          }

          await tester.pumpAndSettle();
          await _takeAScreenshot(supportMultipleDevices
              ? 'goldens/${mode.name}/${device.name}/$name.png'
              : 'goldens/${mode.name}/$name.png');
        } finally {
          debugDisableShadows = true;
          disableInfiniteAnimationsInGoldenTests = true;

          if (tearDown != null) {
            tearDown(tester);
          }
        }
      }, skip: skip);
    }
  }
}

Widget _themedWidget(
  Widget child,
  ThemeData theme,
  List<Locale> supportedLocales, {
  List<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  LocaleResolutionCallback? localeResolutionCallback,
  NavigatorObserver? navigatorObserver,
  RouteFactory? onGenerateRoute,
}) =>
    MaterialApp(
        theme: theme,
        color: Colors.white,
        debugShowCheckedModeBanner: false,
        supportedLocales: supportedLocales,
        localizationsDelegates: localizationsDelegates,
        localeResolutionCallback: localeResolutionCallback ?? ((Locale? local, Iterable<Locale> locales) => null),
        navigatorObservers: [if (navigatorObserver != null) navigatorObserver],
        onGenerateRoute: onGenerateRoute,
        onUnknownRoute: (settings) => _unknownPage(settings),
        home: Scaffold(body: child));

/// Sets size of test device
void _setupSize(Device device, WidgetTester tester) {
  tester.view.physicalSize = Size(device.width * device.devicePixelRatio, device.height * device.devicePixelRatio);
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
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(key, version: version));

PageRouteBuilder _unknownPage(RouteSettings settings) => PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, _, __) =>
          Text('Unknown route ${settings.toString()}', style: Theme.of(context).textTheme.bodyLarge),
    );
