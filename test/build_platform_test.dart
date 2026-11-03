import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, defaultTargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';
import 'package:material_ui/material_ui.dart';

/// Accepts every image, so these tests check the tree, not the pixels.
class _AcceptingComparator extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async => true;

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {}
}

void main() {
  final platforms = <TargetPlatform>[];
  final themePlatforms = <TargetPlatform>[];
  final fonts = <String?>[];

  setUp(() {
    final previous = goldenFileComparator;
    goldenFileComparator = _AcceptingComparator();
    platforms.clear();
    themePlatforms.clear();
    fonts.clear();
    addTearDown(() => goldenFileComparator = previous);
  });

  // Theme.of(context).platform and defaultTargetPlatform are separate paths.
  // Adaptive Material widgets, the back icon and the scroll physics read the
  // first, and it follows the device. The second is left alone on purpose:
  // every ThemeData built under an override resolves its typography from it,
  // and a test environment has fonts for Android only.
  Widget probe(BuildContext context) {
    platforms.add(defaultTargetPlatform);
    themePlatforms.add(Theme.of(context).platform);
    return const SizedBox.expand();
  }

  goldenTest(
    name: 'An iOS device builds for iOS',
    supportedLocales: [const Locale('en')],
    supportedThemes: [Brightness.light],
    supportedDevices: [const Device.iphone15Pro()],
    builder: probe,
    tearDown: (_) async {
      expect(themePlatforms, [TargetPlatform.iOS]);
      expect(platforms, [TargetPlatform.android], reason: 'the global stands');
    },
  );

  goldenTest(
    name: 'A macOS device builds for macOS',
    supportedLocales: [const Locale('en')],
    supportedThemes: [Brightness.light],
    supportedDevices: [const Device.browser()],
    builder: probe,
    tearDown: (_) async => expect(themePlatforms, [TargetPlatform.macOS]),
  );

  // `flutter test` reports Android whatever device a test runs on, and a
  // device that states no platform leaves that default alone.
  goldenTest(
    name: 'A device without a platform keeps the default',
    supportedLocales: [const Locale('en')],
    supportedThemes: [Brightness.light],
    supportedDevices: [const Device(name: 'plain')],
    builder: probe,
    tearDown: (_) async => expect(themePlatforms, [TargetPlatform.android]),
  );

  // Every device of one test is built for its own platform, in turn.
  goldenTest(
    name: 'Two devices, two platforms',
    supportedLocales: [const Locale('en')],
    supportedThemes: [Brightness.light],
    supportedDevices: [const Device.iphone15Pro(), const Device.pixel9ProXL()],
    builder: probe,
    tearDown: (_) async => expect(platforms, isNotEmpty),
  );

  // Every pose of a foldable is built for the same platform.
  goldenTest(
    name: 'Every posture of iPhone Duo',
    supportedLocales: [const Locale('en')],
    supportedThemes: [Brightness.light],
    supportedDevices: [Device.iphoneDuo()],
    builder: probe,
    tearDown: (_) async =>
        expect(themePlatforms, everyElement(TargetPlatform.iOS)),
  );

  // A ThemeData resolves its typography from defaultTargetPlatform when it is
  // built, and the platform's own fonts are not in a test environment. This
  // holds for a widget that builds an app of its own, too, which is why the
  // global is never overridden.
  goldenTest(
    name: 'The font does not follow the platform',
    supportedLocales: [const Locale('en')],
    supportedThemes: [Brightness.light],
    supportedDevices: [const Device.iphone15Pro(), const Device.browser()],
    builder: (context) {
      final theme = Theme.of(context);
      fonts.add(theme.textTheme.bodyMedium?.fontFamily);
      themePlatforms.add(theme.platform);
      // A nested app builds a ThemeData of its own, from the global.
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (inner) {
            fonts.add(Theme.of(inner).textTheme.bodyMedium?.fontFamily);
            return const SizedBox.expand();
          },
        ),
      );
    },
    tearDown: (_) async {
      expect(fonts, everyElement('Roboto'));
      expect(themePlatforms, isNot(everyElement(TargetPlatform.android)));
    },
  );

  // The override is global state; a leak would change every later test.
  test('the override is reset after the goldens', () {
    expect(debugDefaultTargetPlatformOverride, isNull);
  });
}
