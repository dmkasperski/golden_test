import 'dart:typed_data';
import 'dart:ui'
    show DisplayFeature, DisplayFeatureState, DisplayFeatureType, Paragraph;

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';
import 'package:golden_test/src/utils/device_frame.dart';
import 'package:material_ui/material_ui.dart';

/// Accepts every image, so the golden tests here check the tree, not pixels.
class _AcceptingComparator extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async => true;

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {}
}

/// One thing the frame drew: the method, and where it landed.
typedef _Op = (String method, Rect? bounds);

/// A [Canvas] that records what is drawn on it instead of drawing it, so a
/// test can say what the frame paints without rasterising anything.
class _CanvasLog implements Canvas {
  final List<_Op> ops = [];
  Offset _origin = Offset.zero;

  List<_Op> get drawings =>
      ops.where((op) => op.$1.startsWith('draw')).toList();

  /// Everything drawn inside [band], by the centre of what was drawn.
  List<_Op> within(Rect band) => [
    for (final op in drawings)
      if (op.$2 != null && band.contains(op.$2!.center)) op,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final String name = invocation.memberName
        .toString()
        .replaceAll('Symbol("', '')
        .replaceAll('")', '');
    final List<Object?> args = invocation.positionalArguments;

    if (name == 'translate') {
      _origin += Offset(args[0]! as double, args[1]! as double);
      return null;
    }
    if (name == 'restore') {
      _origin = Offset.zero;
    }

    ops.add((name, _boundsOf(args)?.shift(_origin)));
    return null;
  }

  Rect? _boundsOf(List<Object?> args) {
    if (args.isEmpty) {
      return null;
    }
    final Object? first = args.first;
    return switch (first) {
      Rect() => first,
      RRect() => first.outerRect,
      Path() => first.getBounds(),
      Offset() when args.length > 1 && args[1] is double => Rect.fromCircle(
        center: first,
        radius: args[1]! as double,
      ),
      Paragraph() when args.length > 1 && args[1] is Offset =>
        (args[1]! as Offset) & Size(first.width, first.height),
      _ => null,
    };
  }
}

/// What the frame of [device] draws over a screen of its own size.
_CanvasLog _paintFrame(
  Device device, {
  Brightness brightness = Brightness.light,
  bool showStatusBar = true,
  bool showNavigation = true,
}) {
  final log = _CanvasLog();
  DeviceFrame(
    brightness,
    device.insets,
    displayFeatures: device.displayFeatures,
    platform: device.platform,
    navigation: device.navigation,
    showStatusBar: showStatusBar,
    showNavigation: showNavigation,
  ).createBoxPainter().paint(
    log,
    Offset.zero,
    ImageConfiguration(
      size: Size(device.width, device.height),
      devicePixelRatio: device.devicePixelRatio,
    ),
  );
  return log;
}

void main() {
  const Device plain = Device(
    name: 'plain',
    width: 393,
    height: 852,
    insets: EdgeInsets.only(top: 44, bottom: 34),
  );
  const Device pixel = Device.pixel9ProXL();
  const Device pixelButtons = Device.pixel9ProXL(
    navigation: AndroidNavigation.threeButton,
  );

  group('the navigation mode drives the bottom inset', () {
    test('gesture reserves 24 and the three-button bar 48', () {
      expect(pixel.navigation, AndroidNavigation.gesture);
      expect(pixel.insets.bottom, AndroidNavigation.gestureBottomInset);
      expect(pixel.insets.bottom, 24.0);

      expect(pixelButtons.navigation, AndroidNavigation.threeButton);
      expect(
        pixelButtons.insets.bottom,
        AndroidNavigation.threeButtonBottomInset,
      );
      expect(pixelButtons.insets.bottom, 48.0);
    });

    test('the measured status bar stands whichever mode it is', () {
      expect(pixel.insets.top, 50.3);
      expect(pixelButtons.insets.top, 50.3);
    });

    test('the two modes are named apart, so neither golden wins', () {
      expect(pixel.name, isNot(pixelButtons.name));
    });

    test('copyWith moves the bottom inset with the mode', () {
      final Device flipped = pixel.copyWith(
        navigation: AndroidNavigation.threeButton,
      );
      expect(flipped.insets.bottom, 48.0);
      expect(flipped.insets.top, 50.3, reason: 'the rest of the insets stand');
    });

    test('insets given to copyWith win over the mode', () {
      final Device fixed = pixel.copyWith(
        navigation: AndroidNavigation.threeButton,
        insets: const EdgeInsets.only(top: 1, bottom: 2),
      );
      expect(fixed.insets.bottom, 2);
      expect(fixed.navigation, AndroidNavigation.threeButton);
    });

    test('a device of another platform keeps its insets', () {
      final Device iphone = const Device.iphone15Pro().copyWith(
        navigation: AndroidNavigation.threeButton,
      );
      expect(iphone.insets.bottom, 34);
    });
  });

  group('the frame follows the platform', () {
    test('a device without a platform draws what an iOS one draws', () {
      final Device ios = plain.copyWith(platform: TargetPlatform.iOS);
      expect(_paintFrame(plain).ops, _paintFrame(ios).ops);
    });

    test('an Android device draws something else', () {
      final Device android = plain.copyWith(platform: TargetPlatform.android);
      expect(_paintFrame(plain).ops, isNot(_paintFrame(android).ops));
    });

    test('Android puts the clock against the left edge, iOS further in', () {
      Rect clockOf(Device device) =>
          _paintFrame(device).drawings
              .firstWhere((op) => op.$1 == 'drawParagraph')
              .$2!;

      expect(clockOf(plain.copyWith(platform: TargetPlatform.iOS)).left, 24);
      expect(
        clockOf(plain.copyWith(platform: TargetPlatform.android)).left,
        16,
      );
    });

    test('Android orders its status icons its own way', () {
      // Wi-Fi is the only icon drawn as a dot with arcs around it, and it
      // is the leftmost of the three on Android, where iOS puts the signal
      // bars outside it.
      Rect statusBarOf(Device device) =>
          Rect.fromLTWH(0, 0, device.width, device.insets.top);
      Rect wifiDotOf(Device device) =>
          _paintFrame(device)
              .within(statusBarOf(device))
              .firstWhere((op) => op.$1 == 'drawCircle')
              .$2!;
      Rect leftmostBarOf(Device device) =>
          _paintFrame(device)
              .within(statusBarOf(device))
              .where((op) => op.$1 == 'drawRRect' && op.$2!.height <= 11)
              .reduce((a, b) => a.$2!.left < b.$2!.left ? a : b)
              .$2!;

      final Device ios = plain.copyWith(platform: TargetPlatform.iOS);
      final Device android = plain.copyWith(platform: TargetPlatform.android);

      expect(leftmostBarOf(ios).left, lessThan(wifiDotOf(ios).left));
      expect(wifiDotOf(android).left, lessThan(leftmostBarOf(android).left));
    });
  });

  group('the Android navigation bar', () {
    Rect barOf(Device device) => Rect.fromLTRB(
      0,
      device.height - device.insets.bottom,
      device.width,
      device.height,
    );

    test('gesture draws one handle', () {
      final List<_Op> bar = _paintFrame(pixel).within(barOf(pixel));
      expect(bar, hasLength(1));
      expect(bar.single.$1, 'drawRRect');
      expect(bar.single.$2!.width, 108);
      expect(bar.single.$2!.center.dx, pixel.width / 2);
    });

    test('the three-button bar draws back, home and recents', () {
      final List<_Op> bar = _paintFrame(
        pixelButtons,
      ).within(barOf(pixelButtons));
      expect(bar.map((op) => op.$1), ['drawPath', 'drawCircle', 'drawRRect']);
      expect(
        bar.map((op) => op.$2!.center.dx),
        [
          pixelButtons.width / 4,
          pixelButtons.width / 2,
          pixelButtons.width * 3 / 4,
        ],
      );
    });

    test('iOS keeps its home indicator, not a navigation bar', () {
      const Device iphone = Device.iphone15Pro();
      final List<_Op> bar = _paintFrame(iphone).within(barOf(iphone));
      expect(bar, hasLength(1));
      expect(bar.single.$2!.width, 134, reason: 'the iOS pill is wider');
    });

    test(
      'nothing is drawn where the handle would land on a half-open fold',
      () {
        final Device folded = pixel.copyWith(
          displayFeatures: [
            DisplayFeature(
              bounds: Rect.fromLTRB(
                0,
                pixel.height - 40,
                pixel.width,
                pixel.height,
              ),
              type: DisplayFeatureType.fold,
              state: DisplayFeatureState.postureHalfOpened,
            ),
          ],
        );
        // The fold's own edges are still marked; the handle is not drawn.
        expect(
          _paintFrame(folded).within(barOf(folded)).map((op) => op.$1),
          isNot(contains('drawRRect')),
        );
      },
    );
  });

  group('the Android cutout', () {
    test('the Pixel reports its punch-hole camera', () {
      final DisplayFeature cutout = pixel.displayFeatures.single;
      expect(cutout.type, DisplayFeatureType.cutout);
      expect(cutout.bounds, const Rect.fromLTRB(191.2, 0, 248.9, 50.3));
      expect(pixel.reportsDisplayFeatures, isTrue);
    });

    test('the lens is drawn inside the reserved region, not over it', () {
      final Rect reserved = pixel.displayFeatures.single.bounds;
      final List<_Op> inside = _paintFrame(pixel).within(reserved);
      final _Op lens = inside.lastWhere((op) => op.$1 == 'drawOval');
      expect(reserved.contains(lens.$2!.topLeft), isTrue);
      expect(reserved.contains(lens.$2!.bottomRight), isTrue);
      expect(lens.$2!.width, lessThan(reserved.width));
      expect(lens.$2!.center, reserved.center);
    });

    test('the status bar is still drawn around it', () {
      // Unlike iPhone Duo, where the cutout is the status cluster and
      // replaces the bar, Android draws an ordinary bar with a hole in it.
      expect(
        _paintFrame(pixel).drawings.map((op) => op.$1),
        contains('drawParagraph'),
      );
    });
  });

  group('the harness sets what the mode reserves', () {
    late EdgeInsets padding;

    setUp(() {
      final previous = goldenFileComparator;
      goldenFileComparator = _AcceptingComparator();
      addTearDown(() => goldenFileComparator = previous);
    });

    goldenTest(
      name: 'Gesture navigation reaches the widget as a 24 bottom padding',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [pixel],
      builder: (context) {
        padding = MediaQuery.paddingOf(context);
        return const SizedBox.expand();
      },
      tearDown: (_) async {
        expect(padding.bottom, 24.0);
        expect(padding.top, closeTo(50.3, 0.001));
      },
    );

    goldenTest(
      name: 'The three-button bar reaches the widget as a 48 bottom padding',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light],
      supportedDevices: [pixelButtons],
      builder: (context) {
        padding = MediaQuery.paddingOf(context);
        return const SizedBox.expand();
      },
      tearDown: (_) async => expect(padding.bottom, 48.0),
    );
  });

  group('what the chrome looks like', () {
    // One flat mid-tone under the whole window, so that both halves of the
    // frame read against it: the status bar, which the frame fills with the
    // window's own background, and the navigation bar, which it does not
    // fill at all and leaves to the app, as edge-to-edge Android does.
    Widget body(BuildContext context) =>
        const ColoredBox(color: Color(0xFF7E8C9A), child: SizedBox.expand());

    // The one golden that says the platform decides the chrome. The same
    // window, drawn three ways: iOS puts the clock in the middle of the left
    // half and ends in a home indicator, Android pushes the clock to the
    // edge and orders its icons its own way, and the three-button bar is
    // twice the gesture bar's height.
    goldenTest(
      name: 'The chrome the platform draws',
      supportedLocales: [const Locale('en')],
      supportedThemes: [Brightness.light, Brightness.dark],
      supportedDevices: [
        const Device.iphone15Pro(),
        const Device.pixel9ProXL(),
        const Device.pixel9ProXL(navigation: AndroidNavigation.threeButton),
      ],
      builder: body,
    );
  });

  group('the mode draws the navigation, not the inset', () {
    // An inset is a poor signal for a bar. The top half of a split screen
    // reports no bottom inset and shows no navigation; the half below it
    // reports one and shows it. The device says which it is.
    const Device bare = Device(
      name: 'android reporting no inset',
      width: 400,
      height: 800,
      platform: TargetPlatform.android,
      navigation: AndroidNavigation.threeButton,
    );

    test('a window reporting no inset still draws the bar its mode has', () {
      final log = _paintFrame(bare);

      expect(
        log.within(const Rect.fromLTRB(0, 752, 400, 800)),
        hasLength(3),
        reason: 'back, home and recents, in the 48 the mode owns',
      );
    });

    test('none draws nothing, whatever the device reserves', () {
      final log = _paintFrame(
        const Device(
          name: 'edge to edge',
          width: 400,
          height: 800,
          insets: EdgeInsets.only(bottom: 48),
          platform: TargetPlatform.android,
          navigation: AndroidNavigation.none,
        ),
      );

      expect(log.within(const Rect.fromLTRB(0, 700, 400, 800)), isEmpty);
      expect(AndroidNavigation.none.bottomInset, 0);
    });

    test('an inset taller than the bar leaves the extra space above it', () {
      final log = _paintFrame(
        const Device(
          name: 'generous inset',
          width: 400,
          height: 800,
          insets: EdgeInsets.only(bottom: 30),
          platform: TargetPlatform.android,
        ),
      );

      final List<_Op> handle = log.within(
        const Rect.fromLTRB(0, 770, 400, 800),
      );
      expect(handle, hasLength(1));
      expect(
        handle.single.$2!.center.dy,
        800 - AndroidNavigation.gestureBottomInset / 2,
        reason: 'the bar sits in its own 24, not centred in the 30',
      );
    });
  });

  group('nothing fills a bar', () {
    // A real device draws its bars over the app. An app bar's colour runs to
    // the top edge and the clock sits on it, so a frame that filled the band
    // would hide a colour the device shows.
    test('the status bar paints no band over the app', () {
      const Device phone = Device(
        name: 'phone',
        width: 400,
        height: 800,
        insets: EdgeInsets.only(top: 50),
        platform: TargetPlatform.android,
      );

      for (final _Op op in _paintFrame(phone).drawings) {
        expect(
          op.$2,
          isNot(const Rect.fromLTRB(0, 0, 400, 50)),
          reason: 'the band itself is never painted',
        );
      }
    });
  });

  group('the frame can be turned off', () {
    const Device phone = Device(
      name: 'phone',
      width: 400,
      height: 800,
      insets: EdgeInsets.only(top: 50, bottom: 24),
      platform: TargetPlatform.android,
    );

    test('without the status bar the top of the window stays the app\'s', () {
      final log = _paintFrame(phone, showStatusBar: false);

      expect(log.within(const Rect.fromLTRB(0, 0, 400, 50)), isEmpty);
      expect(
        log.within(const Rect.fromLTRB(0, 776, 400, 800)),
        isNotEmpty,
        reason: 'the navigation is a separate switch',
      );
    });

    test('without the navigation the bottom of the window stays the app\'s', () {
      final log = _paintFrame(phone, showNavigation: false);

      expect(log.within(const Rect.fromLTRB(0, 776, 400, 800)), isEmpty);
      expect(log.within(const Rect.fromLTRB(0, 0, 400, 50)), isNotEmpty);
    });

    test('the iOS home indicator answers the same switch', () {
      final log = _paintFrame(
        const Device.iphone15Pro(),
        showNavigation: false,
      );
      final Device iphone = const Device.iphone15Pro();

      expect(
        log.within(
          Rect.fromLTRB(
            0,
            iphone.height - iphone.insets.bottom,
            iphone.width,
            iphone.height,
          ),
        ),
        isEmpty,
      );
    });
  });
}
