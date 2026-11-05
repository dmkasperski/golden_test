import 'dart:math' show max;
import 'dart:ui' as ui;

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/src/config.dart';
import 'package:golden_test/src/device.dart';
import 'package:golden_test/src/keyboard.dart';
import 'package:golden_test/src/local_file_comparator_with_tolerance.dart';
import 'package:golden_test/src/network_image_stub.dart';
import 'package:golden_test/src/utils/device_frame.dart';
import 'package:golden_test/src/utils/keyboard_painter.dart';
import 'package:golden_test/src/utils/keyboard_simulation.dart';
import 'package:meta/meta.dart';

/// The goldenTest method is designed to facilitate automated UI testing
/// of Flutter widgets by comparing their rendered output against a predefined golden image.
/// This ensures consistent visual behavior across different devices, theme modes, and locales.
///
/// Parameters
/// * [name]: A descriptive string that identifies the test case. The value is used
///   verbatim as the golden filename on disk, so avoid path separators and characters
///   that complicate filesystem tooling.
///
/// * [builder]: A WidgetBuilder function that constructs the widget to be tested.
///
/// * [supportedDevices]: An optional list specifying the devices on which the test should be run.
///   When provided, this takes precedence over all other device configurations.
///   When `null`, the device configuration is determined by [supportMultipleDevices] flag or global defaults.
///
/// * [supportMultipleDevices]: A boolean indicating whether the test should run on multiple devices.
///   When `true`, uses [goldenTestSupportedDevices] from global config.
///   When `false`, uses [goldenTestDefaultDevices] from global config.
///   Can also be controlled globally via [goldenTestSupportMultipleDevices].
///   This is ignored if [supportedDevices] is explicitly provided.
///   Defaults to false.
///
/// * [supportedThemes]: An optional list specifying the Brightness modes on which the test should be run.
///   Defaults to an empty list. Global config defaults to light and dark mode.
///
/// * [supportedLocales]: An optional list of Locale specifying the locales in which the test should be run.
///   Defaults to an empty list. Global config defaults to `en_US`.
///
/// * [supportedTextScales]: An optional list of `textScaleFactor` values to run the
///   test at, enabling accessibility regression testing. Defaults to an empty list,
///   which uses [goldenTestSupportedTextScales] (default `[1.0]`). Use
///   [AndroidFontScale] / [IosDynamicTypeScale] `.value`, or pass any custom
///   `double` values.
///
/// * [localizationsDelegates]: An optional list of LocalizationsDelegate objects providing localization support for the test.
///
/// * [navigatorBuilder]: An optional builder that wraps the app's root [Navigator],
///   so what it provides is also visible to every route pushed from the widget
///   under test, such as dialogs, sheets and menus. When `null`,
///   [goldenTestNavigatorBuilder] is used.
///
/// * [keyboard]: An optional software keyboard shown over the bottom of the
///   screen for the whole test. The view reports it as a bottom `viewInsets`,
///   so the widget under test lays out as it would with the keyboard open.
///   Without it, the keyboard appears by itself when a text field gains focus
///   and matches the field's `keyboardType`, while [simulateKeyboard] is
///   `true`. See [GoldenKeyboard].
///
/// * [simulateKeyboard]: Whether the keyboard appears by itself when a text
///   field gains focus and hides when it loses focus. When `null`,
///   [goldenTestSimulateKeyboard] is used. A [keyboard] turns it off.
///
/// * [setup]: An optional asynchronous function that can be used to perform setup tasks before the test runs.
///
/// * [tearDown]: An optional asynchronous function that can be used to perform cleanup tasks after the test runs.
///
/// * [action]: An optional asynchronous function that can be used to perform
///   additional actions on the widget tester during the test.
///
/// * [skip]: A boolean indicating whether the test should be skipped.
///   Defaults to false.
///
/// * [tags]: Optional tags to apply to the test. Accepts a single tag (String or
///   Tag object) or an `Iterable` of such tags — same shape as Flutter's own
///   `testWidgets` tags parameter. These tags can be used to filter which tests
///   to run. Defaults to null (no tags).
///
/// * [subdirectory]: An optional subdirectory path to organize golden files.
///   When provided, this subdirectory will be inserted after "goldens" in the path.
///   Useful for managing golden tests across multiple apps or design systems.
///   Example: 'app1' creates path 'goldens/app1/en/light/MyWidget.png'
///   Defaults to null (no subdirectory).
///
/// Device Selection Logic (priority from highest to lowest):
/// 1. If [supportedDevices] parameter is explicitly provided, use those devices.
/// 2. Else if [supportMultipleDevices] is `true` (local or global), use [goldenTestSupportedDevices].
/// 3. Otherwise, use [goldenTestDefaultDevices].
///
/// {@tool snippet}
/// Basic example:
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
///
/// Example with custom subdirectory for organizing golden files:
/// ```dart
///   goldenTest(
///     name: 'Button',
///     builder: (_) => MyButton(),
///     subdirectory: 'design_system/components',
///   );
/// ```
///
/// Example of a text-scale accessibility matrix with platform presets:
/// ```dart
///   goldenTest(
///     name: 'Settings',
///     builder: (_) => const SettingsScreen(),
///     supportedTextScales: [1.0, AndroidFontScale.maximum.value],
///   );
/// ```
///
/// Example of a screen with the keyboard open:
/// ```dart
///   goldenTest(
///     name: 'SignIn keyboard',
///     builder: (_) => const SignInScreen(),
///     keyboard: const GoldenKeyboard(type: TextInputType.emailAddress),
///   );
/// ```
/// {@end-tool}
bool _packageFontsLoaded = false;

Future<void> _ensurePackageFontsLoaded() async {
  if (_packageFontsLoaded) return;
  _packageFontsLoaded = true;
  await (FontLoader('Roboto')..addFont(
        rootBundle.load('packages/golden_test/lib/fonts/Roboto-Regular.ttf'),
      ))
      .load();
}

/// Flutter's default [LocalFileComparator] writes failure images to a single
/// `failures/` folder next to the test file, named after the golden file only.
/// Every locale, theme, device and text scale variant of a test shares that
/// name, so each failing variant overwrites the previous one's images.
/// [LocalFileComparatorWithTolerance] writes them next to the golden instead.
///
/// Only Flutter's own comparator is replaced, so a comparator set by the
/// project, including one from [goldenTestDifferenceTolerance], is kept.
void _ensureFailuresPerVariant() {
  if (goldenFileComparator.runtimeType == LocalFileComparator) {
    installGoldenTestComparator(0);
  }
}

@isTest
void goldenTest({
  required String name,
  required WidgetBuilder builder,
  List<Device>? supportedDevices,
  bool supportMultipleDevices = false,
  List<Brightness> supportedThemes = const [],
  List<Locale> supportedLocales = const [],
  List<double> supportedTextScales = const [],
  List<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  GoldenTestNavigatorBuilder? navigatorBuilder,
  GoldenKeyboard? keyboard,
  bool? simulateKeyboard,
  Future<void> Function(WidgetTester tester)? setup,
  Future<void> Function(WidgetTester tester)? tearDown,
  Future<void> Function(WidgetTester tester)? action,
  bool skip = false,
  Object? tags,
  String? subdirectory,
}) {
  final testDevices = _resolveTestDevices(
    supportedDevices,
    supportMultipleDevices,
  );
  final testModes = _resolveTestThemes(supportedThemes);
  final testLocales = _resolveTestLocales(supportedLocales);
  final textScaleConfig = _resolveTextScales(supportedTextScales);
  final testScales = textScaleConfig.scales;
  final includeTextScaleInPath = textScaleConfig.includeInPath;

  for (final locale in testLocales) {
    for (final mode in testModes) {
      for (final device in testDevices) {
        for (final scale in testScales) {
          testWidgets(
            name,
            (WidgetTester tester) async {
              _ensureFailuresPerVariant();
              await _ensurePackageFontsLoaded();
              tester.platformDispatcher.platformBrightnessTestValue = mode;
              tester.platformDispatcher.textScaleFactorTestValue = scale;
              debugDisableShadows = false;

              // Include device name in path only when testing multiple devices
              final shouldIncludeDeviceName = testDevices.length > 1;
              final goldenPath = _buildGoldenPath(
                locale: locale,
                mode: mode,
                device: device,
                name: name,
                includeDeviceName: shouldIncludeDeviceName,
                textScale: includeTextScaleInPath ? scale : null,
                subdirectory: subdirectory,
              );

              // A foldable is built once for every posture, and its golden
              // shows all of them side by side.
              final List<Device> screens = device.postures.isEmpty
                  ? [device]
                  : device.postures;
              final captures = <_PostureCapture>[];

              final ThemeData lightTheme = goldenTestThemeInTests;
              final ThemeData darkTheme = goldenTestDarkThemeInTests;

              // Outer finally: runWithNetworkImageStub can throw before
              // reaching its body, which would leak debugDisableShadows.
              try {
                await runWithNetworkImageStub(() async {
                  for (final (index, screen) in screens.indexed) {
                    _setupSize(
                      device: screen,
                      tester: tester,
                    );
                    // A device states the platform it runs, and the theme
                    // carries it, which is what adaptive widgets, the back
                    // icon and the scroll physics read.
                    //
                    // `defaultTargetPlatform` itself is deliberately left
                    // alone. Every `ThemeData` built while it is overridden
                    // resolves its typography from it, and a test
                    // environment has no fonts for a platform other than
                    // Android, so a widget that builds an app or a theme of
                    // its own would render every glyph as a blank box.
                    final TargetPlatform? platformOverride = screen.platform;
                    final ResolvedKeyboard? fixedKeyboard = keyboard == null
                        ? null
                        : ResolvedKeyboard.of(
                            keyboard: keyboard,
                            device: screen,
                          );
                    setKeyboardInsets(
                      tester: tester,
                      device: screen,
                      keyboard: fixedKeyboard,
                    );
                    final KeyboardSimulation? keyboardSimulation =
                        keyboard == null &&
                            (simulateKeyboard ?? goldenTestSimulateKeyboard)
                        ? KeyboardSimulation.install(
                            tester: tester,
                            device: screen,
                          )
                        : null;

                    try {
                      if (globalSetup != null) {
                        await globalSetup!(locale);
                      }

                      if (setup != null) {
                        await setup(tester);
                      }

                      final widget = _themedWidget(
                        child: Container(
                          alignment: Alignment.topLeft,
                          child: Builder(builder: builder),
                        ),
                        // A ThemeData freezes defaultTargetPlatform into its
                        // own `platform` when it is built, and the project's
                        // themes are top-level variables built once, before
                        // any override. Without this, adaptive widgets and
                        // anything reading Theme.of(context).platform would
                        // keep the platform of whichever test ran first.
                        theme: _applyPlatform(
                          mode == Brightness.light ? lightTheme : darkTheme,
                          platformOverride,
                        ),
                        supportedLocales: [locale],
                        localizationsDelegates:
                            localizationsDelegates ??
                            goldenTestLocalizationsDelegates,
                        navigatorBuilder:
                            navigatorBuilder ?? goldenTestNavigatorBuilder,
                        resizeToAvoidBottomInset:
                            fixedKeyboard == null && keyboardSimulation == null,
                      );

                      await tester.pumpWidget(
                        _GoldenTestRoot(
                          // A new key for every posture, so that each one is
                          // built from scratch, as a test of its own would be.
                          key: ValueKey<int>(index),
                          child: keyboardSimulation == null
                              ? _DeviceFrameBox(
                                  mode: mode,
                                  device: screen,
                                  keyboard: fixedKeyboard,
                                  child: widget,
                                )
                              : ValueListenableBuilder(
                                  valueListenable: keyboardSimulation.keyboard,
                                  builder: (_, keyboard, _) => _DeviceFrameBox(
                                    mode: mode,
                                    device: screen,
                                    keyboard: keyboard,
                                    child: widget,
                                  ),
                                ),
                        ),
                      );

                      if (action != null) {
                        await tester.pumpAndSettle();
                        await action(tester);
                      }

                      await tester.pumpAndSettle();
                      await _precacheImages(tester);

                      if (device.postures.isEmpty) {
                        await _takeAScreenshot(goldenPath);
                      } else {
                        captures.add(await _capturePosture(tester, screen));
                      }
                    } finally {
                      if (tearDown != null) {
                        await tearDown(tester);
                      }
                      keyboardSimulation?.dispose();
                    }
                  }

                  if (captures.isNotEmpty) {
                    await _matchPostures(
                      tester: tester,
                      captures: captures,
                      mode: mode,
                      goldenPath: goldenPath,
                    );
                  }
                });
              } finally {
                for (final capture in captures) {
                  capture.image.dispose();
                }
                debugDisableShadows = true;
              }
            },
            skip: skip,
            tags: tags,
          );
        }
      }
    }
  }
}

/// Resolves which devices to use for testing.
/// Priority: explicit parameter > multi-device flag > global default
List<Device> _resolveTestDevices(
  List<Device>? supportedDevices,
  bool supportMultipleDevices,
) {
  final List<Device> testDevices;

  if (supportedDevices != null) {
    // 1. Explicit per-test device configuration (highest priority)
    testDevices = supportedDevices;
  } else {
    // 2. Check if multi-device testing is enabled (local or global flag)
    final shouldUseMultipleDevices =
        supportMultipleDevices || goldenTestSupportMultipleDevices;
    testDevices = shouldUseMultipleDevices
        ? goldenTestSupportedDevices
        : goldenTestDefaultDevices;
  }

  assert(testDevices.isNotEmpty, 'No devices specified for testing');
  return testDevices;
}

/// Resolves which theme modes to use for testing.
/// Priority: local parameter > global config
List<Brightness> _resolveTestThemes(List<Brightness> supportedThemes) {
  final testModes = supportedThemes.isNotEmpty
      ? supportedThemes
      : goldenTestSupportedThemes;

  assert(testModes.isNotEmpty, 'No themes specified for testing');
  return testModes;
}

/// Resolves which locales to use for testing.
/// Priority: local parameter > global config
List<Locale> _resolveTestLocales(List<Locale> supportedLocales) {
  final testLocales = supportedLocales.isNotEmpty
      ? supportedLocales
      : goldenTestSupportedLocales;

  assert(testLocales.isNotEmpty, 'No locales specified for testing');
  return testLocales;
}

/// Resolved text-scale configuration for a golden test run.
typedef _TextScaleConfig = ({List<double> scales, bool includeInPath});

/// Resolves which text scale factors to use for testing.
///
/// A scale segment is included in the golden path only when [scales] contains
/// more than one value. A single scale — including the default `[1.0]` — runs
/// without a scale folder.
_TextScaleConfig _resolveTextScales(List<double> supportedTextScales) {
  final scales = supportedTextScales.isNotEmpty
      ? supportedTextScales
      : goldenTestSupportedTextScales;

  assert(scales.isNotEmpty, 'No text scales specified for testing');
  return (scales: scales, includeInPath: scales.length > 1);
}

/// Builds the golden file path based on configuration and test parameters.
///
/// The path structure is:
/// - goldens/[subdir]/locale/theme/[device]/[textScale]/name.png
///
/// The [subdir] and device segments are included when configured. The [textScale]
/// segment is the last directory before the filename and is only included when
/// more than one scale is active.
String _buildGoldenPath({
  required Locale locale,
  required Brightness mode,
  required Device device,
  required String name,
  required bool includeDeviceName,
  double? textScale,
  String? subdirectory,
}) {
  final pathSegments = <String>['goldens'];

  if (subdirectory != null && subdirectory.isNotEmpty) {
    pathSegments.add(subdirectory);
  }

  pathSegments.add(locale.languageCode);

  pathSegments.add(mode.name);

  if (includeDeviceName) {
    pathSegments.add(device.name ?? 'default');
  }

  if (textScale != null) {
    pathSegments.add('${_formatTextScale(textScale)}x');
  }

  pathSegments.add('$name.png');

  return pathSegments.join('/');
}

/// Formats a text scale factor for inclusion in the golden path.
/// Trims trailing zeros so `1.0` becomes `1`, `1.30` becomes `1.3`, etc.
String _formatTextScale(double scale) {
  final s = scale.toStringAsFixed(2);
  return s.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// The theme as the device's platform would build it, or unchanged when the
/// test builds for the default platform.
/// The theme as the device's platform sees it.
///
/// Only [ThemeData.platform] moves, which is what adaptive widgets read.
/// The typography stays as the theme was built with, because the platform's
/// own fonts are not in a test environment.
ThemeData _applyPlatform(ThemeData theme, TargetPlatform? platform) =>
    platform == null ? theme : theme.copyWith(platform: platform);

/// Apply theme to pumped Widget.
Widget _themedWidget({
  required Widget child,
  required ThemeData theme,
  required List<Locale> supportedLocales,
  List<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  GoldenTestNavigatorBuilder? navigatorBuilder,
  bool resizeToAvoidBottomInset = true,
}) => MaterialApp(
  theme: theme,
  color: Colors.white,
  debugShowCheckedModeBanner: false,
  builder: navigatorBuilder == null
      ? null
      : (context, navigator) => navigatorBuilder(context, navigator!),
  locale: supportedLocales.first,
  supportedLocales: supportedLocales,
  localizationsDelegates: [
    ...?localizationsDelegates,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  localeResolutionCallback: ((Locale? local, Iterable<Locale> locales) =>
      supportedLocales.first),
  onUnknownRoute: (settings) => _unknownPage(settings),
  // A Scaffold that resizes for the keyboard also removes the inset from the
  // MediaQuery of its body. When a keyboard can show, this one must not, or
  // the widget under test would always be shrunk and see viewInsets.bottom ==
  // 0, whatever its own resizeToAvoidBottomInset says. Left alone, the inset
  // reaches the widget's own Scaffold, which handles it as on a device.
  //
  // The widget under test gets a ScaffoldMessenger of its own. Snackbars go to
  // the outermost Scaffolds of a messenger, and without it that would be this
  // one: a snackbar would span the whole screen, over the widget's own bottom
  // navigation bar, and a screen with two Scaffolds side by side would show
  // one snackbar instead of one in each, as it does in an app.
  home: Scaffold(
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    body: ScaffoldMessenger(child: child),
  ),
);

/// Sets size of test device. The keyboard, which changes `padding` and
/// `viewInsets`, is applied separately with [setKeyboardInsets].
void _setupSize({
  required Device device,
  required WidgetTester tester,
}) {
  final double ratio = device.devicePixelRatio;
  tester.view.physicalSize = Size(device.width * ratio, device.height * ratio);
  tester.view.devicePixelRatio = ratio;
  tester.view.viewPadding = FakeViewPadding(
    left: device.insets.left * ratio,
    top: device.insets.top * ratio,
    right: device.insets.right * ratio,
    bottom: device.insets.bottom * ratio,
  );
  tester.view.displayFeatures = device.reportsDisplayFeatures
      ? device.displayFeatures
      : const [];
}

/// Paints the device frame, and the keyboard when there is one, over the app.
///
/// The keyboard also takes the taps over its area, as on a device, so a tap
/// on a control it covers does not reach the control.
class _DeviceFrameBox extends StatelessWidget {
  const _DeviceFrameBox({
    required this.mode,
    required this.device,
    required this.keyboard,
    required this.child,
  });

  final Brightness mode;
  final Device device;
  final ResolvedKeyboard? keyboard;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ResolvedKeyboard? keyboard = this.keyboard;

    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: DeviceFrame(
        mode,
        device.insets,
        keyboard: keyboard,
        displayFeatures: device.displayFeatures,
        platform: device.platform,
        navigation: device.navigation,
        showStatusBar: goldenTestShowStatusBar,
        showNavigation: goldenTestShowNavigation,
      ),
      // The app stays the first child with or without a keyboard, so its
      // state survives the keyboard coming and going.
      child: Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.topLeft,
        children: [
          child,
          if (keyboard != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: keyboard.height,
              child: const AbsorbPointer(child: SizedBox.expand()),
            ),
        ],
      ),
    );
  }
}

/// Marks the root of the pumped tree, so the snapshot finder matches exactly
/// one widget whatever the test builds.
///
/// The type is private, so it cannot collide with a widget under test. It
/// builds no [RenderObject] of its own, so the rasterised image is unchanged:
/// [matchesGoldenFile] captures the nearest enclosing [RepaintBoundary], which
/// remains the view.
class _GoldenTestRoot extends StatelessWidget {
  const _GoldenTestRoot({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

Future<void> _takeAScreenshot(dynamic key, {int? version}) async =>
    await expectLater(
      find.byType(_GoldenTestRoot),
      matchesGoldenFile(key, version: version),
    );

/// One posture of a foldable, rasterised for [_matchPostures].
typedef _PostureCapture = ({Device posture, ui.Image image});

Future<_PostureCapture> _capturePosture(
  WidgetTester tester,
  Device posture,
) async {
  final Element root = find.byType(_GoldenTestRoot).evaluate().single;
  final ui.Image? image = await tester.runAsync(() => captureImage(root));
  return (posture: posture, image: image!);
}

/// Compares the postures of a foldable, side by side and each named under
/// its screen, with one golden file.
///
/// A fold or hinge that splits the screen is marked in the margin, with a
/// bar across its width above and below the screen, or left and right of a
/// horizontal one. Nothing is drawn over the screen, so its pixels are the
/// app's own, and the bars are solid and aligned to whole pixels, so they
/// rasterise the same everywhere. A fold open flat has no width and is not
/// marked.
Future<void> _matchPostures({
  required WidgetTester tester,
  required List<_PostureCapture> captures,
  required Brightness mode,
  required String goldenPath,
}) async {
  final double ratio = captures
      .map((capture) => capture.posture.devicePixelRatio)
      .reduce(max);
  final double margin = 32 * ratio;
  final double labelHeight = 40 * ratio;
  final double markGap = (4 * ratio).roundToDouble();
  final double markThickness = (6 * ratio).roundToDouble();
  final double screensHeight = captures
      .map((capture) => capture.image.height.toDouble())
      .reduce(max);
  final double width =
      margin * (captures.length + 1) +
      captures.fold(0.0, (sum, capture) => sum + capture.image.width);
  final double labelTop = margin + screensHeight + markGap + markThickness;
  final double height = labelTop + labelHeight + margin / 2;
  final Paint markPaint = Paint()
    ..isAntiAlias = false
    ..color = const Color(0xFF8E8E93);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width, height),
    Paint()
      ..color = mode == Brightness.light
          ? const Color(0xFFD1D1D6)
          : const Color(0xFF2C2C2E),
  );

  double left = margin;
  for (final capture in captures) {
    canvas.drawImage(capture.image, Offset(left, margin), Paint());

    final Rect screen = Rect.fromLTWH(
      left,
      margin,
      capture.image.width.toDouble(),
      capture.image.height.toDouble(),
    );
    for (final ui.DisplayFeature feature in capture.posture.displayFeatures) {
      if (feature.type == ui.DisplayFeatureType.cutout) {
        continue;
      }
      final Rect fold = feature.bounds;
      final double scale = capture.posture.devicePixelRatio;
      if (fold.width > 0 && fold.height >= fold.width) {
        final double from = (left + fold.left * scale).roundToDouble();
        final double to = (left + fold.right * scale).roundToDouble();
        canvas
          ..drawRect(
            Rect.fromLTRB(
              from,
              screen.top - markGap - markThickness,
              to,
              screen.top - markGap,
            ),
            markPaint,
          )
          ..drawRect(
            Rect.fromLTRB(
              from,
              screen.bottom + markGap,
              to,
              screen.bottom + markGap + markThickness,
            ),
            markPaint,
          );
      } else if (fold.height > 0 && fold.width > fold.height) {
        final double from = (margin + fold.top * scale).roundToDouble();
        final double to = (margin + fold.bottom * scale).roundToDouble();
        canvas
          ..drawRect(
            Rect.fromLTRB(
              screen.left - markGap - markThickness,
              from,
              screen.left - markGap,
              to,
            ),
            markPaint,
          )
          ..drawRect(
            Rect.fromLTRB(
              screen.right + markGap,
              from,
              screen.right + markGap + markThickness,
              to,
            ),
            markPaint,
          );
      }
    }

    final label = TextPainter(
      text: TextSpan(
        text: capture.posture.name,
        style: TextStyle(
          color: mode == Brightness.light ? Colors.black : Colors.white,
          fontSize: 15 * ratio,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(
      canvas,
      Offset(
        left + (capture.image.width - label.width) / 2,
        labelTop + (labelHeight - label.height) / 2,
      ),
    );
    label.dispose();

    left += capture.image.width + margin;
  }

  final ui.Picture picture = recorder.endRecording();
  final ui.Image? composite = await tester.runAsync(
    () => picture.toImage(width.ceil(), height.ceil()),
  );
  picture.dispose();

  try {
    await expectLater(composite!, matchesGoldenFile(goldenPath));
  } finally {
    composite?.dispose();
  }
}

/// Fallback for route generator
PageRouteBuilder _unknownPage(RouteSettings settings) => PageRouteBuilder(
  settings: settings,
  pageBuilder: (context, _, __) => Text(
    'Unknown route ${settings.toString()}',
    style: Theme.of(context).textTheme.bodyLarge,
  ),
);

/// Code from Alchemist Library (MIT License)
/// Portions of this software are derived from the Alchemist library,
/// which is subject to the MIT License.
/// (https://github.com/Betterment/alchemist/blob/0ef689574ea40f81b2268576ce7be33032e12da8/lib/src/pumps.dart#L43).
///
/// Original Copyright (c) 2022 Betterment LLC
///
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
