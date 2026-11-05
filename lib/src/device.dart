import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:golden_test/src/android_navigation.dart';
import 'package:golden_test/src/iphone_duo.dart';
import 'package:material_ui/material_ui.dart';

class Device {
  final String? name;
  final double devicePixelRatio;
  final double width;
  final double height;
  final EdgeInsets insets;

  /// The platform the device runs.
  ///
  /// The widget under test is built for it, so it drives everything the
  /// framework reads from `defaultTargetPlatform`: `Theme.of(context)
  /// .platform`, the back icon, switches and other adaptive widgets, and
  /// whether a package that looks for platform features finds them. It also
  /// picks the keyboard a `GoldenKeyboard` draws when it has no style of its
  /// own.
  ///
  /// When it is null the framework's own default stands, which under
  /// `flutter test` is Android whatever the device.
  final TargetPlatform? platform;

  /// Folds, hinges and cutouts of the screen, in logical pixels.
  ///
  /// The frame draws them. The widget under test reads them from
  /// [MediaQueryData.displayFeatures] when [reportsDisplayFeatures] is true.
  final List<DisplayFeature> displayFeatures;

  /// Whether the platform reports [displayFeatures] to the app. Flutter does
  /// on Android; on iOS it reports none, unless a plugin publishes them.
  final bool reportsDisplayFeatures;

  /// The states a foldable can be in, each a screen of its own.
  ///
  /// Empty for an ordinary device. [Device.folding] is the way to fill it,
  /// because a device that has postures takes its window from them, not from
  /// its own fields, and only a constructor can keep the two from disagreeing.
  final List<Device> postures;

  /// How an Android device shows its navigation.
  ///
  /// The frame draws the gesture pill or the three-button bar for it, and it
  /// is what [insets] reserve at the bottom. Devices of another [platform]
  /// ignore it, so it is a field of every device only because any device may
  /// turn out to be the Android one.
  ///
  /// The Android device factories set it together with [insets], so the two
  /// cannot disagree; [copyWith] moves the bottom inset with it.
  final AndroidNavigation navigation;

  const Device._({
    required this.name,
    required this.devicePixelRatio,
    required this.width,
    required this.height,
    required this.insets,
    required this.platform,
    required this.displayFeatures,
    required this.reportsDisplayFeatures,
    required this.postures,
    required this.navigation,
  });

  const Device({
    String? name = 'default',
    double devicePixelRatio = 1,
    double width = 420,
    double height = 800,
    EdgeInsets insets = EdgeInsets.zero,
    TargetPlatform? platform,
    List<DisplayFeature> displayFeatures = const [],
    bool reportsDisplayFeatures = true,
    AndroidNavigation navigation = AndroidNavigation.gesture,
  }) : this._(
         name: name,
         devicePixelRatio: devicePixelRatio,
         width: width,
         height: height,
         insets: insets,
         platform: platform,
         displayFeatures: displayFeatures,
         reportsDisplayFeatures: reportsDisplayFeatures,
         postures: const [],
         navigation: navigation,
       );

  /// A foldable, as the [postures] it can be in, each a screen of its own.
  ///
  /// The widget under test is built once for every posture, from scratch,
  /// with its own `setup`, `action` and `tearDown`, and one golden shows them
  /// side by side, each named under its screen. The window of each comes from
  /// the posture; this device carries the [name] the golden is filed under and
  /// the [platform] the postures run.
  factory Device.folding({
    required String name,
    required List<Device> postures,
    TargetPlatform? platform,
  }) {
    assert(postures.isNotEmpty, 'A folding device needs at least one posture.');
    assert(
      postures.every((posture) => posture.postures.isEmpty),
      'A posture is one screen and cannot have postures of its own.',
    );
    assert(
      postures.every((posture) => posture.name != null),
      'Every posture needs a name, which the golden writes under its screen.',
    );
    assert(
      postures.map((posture) => posture.name).toSet().length == postures.length,
      'Two postures share a name, so the golden would label them alike.',
    );

    final Device first = postures.first;
    return Device._(
      name: name,
      devicePixelRatio: first.devicePixelRatio,
      width: first.width,
      height: first.height,
      insets: first.insets,
      platform: platform ?? first.platform,
      displayFeatures: const [],
      reportsDisplayFeatures: first.reportsDisplayFeatures,
      postures: postures,
      navigation: first.navigation,
    );
  }

  const Device.noInsets()
    : this(
        name: 'no insets',
        devicePixelRatio: 3,
        width: 393,
        height: 852,
        insets: const EdgeInsets.all(0),
      );

  const Device.iphone15Pro()
    : this(
        name: 'iphone 15 pro',
        devicePixelRatio: 3,
        width: 393,
        height: 852,
        insets: const EdgeInsets.only(top: 44, bottom: 34),
        platform: TargetPlatform.iOS,
      );

  /// A Pixel 9 Pro XL, in the given [navigation] mode.
  ///
  /// The mode sets the bottom inset — 24.0 for gestures, 48.0 for the
  /// three-button bar — and what the frame draws there. The three-button
  /// device is named apart, so a test that runs both modes files a golden
  /// under each instead of one overwriting the other.
  ///
  /// The insets and the cutout are measured on a Pixel 6a emulator
  /// (Android 16, API 36), which reports a 50.3 status bar and its punch-hole
  /// camera as a cutout. The cutout's horizontal bounds are scaled from that
  /// emulator's 411.4 logical width to this device's 430:
  /// `182.9 * 430 / 411.4 = 191.2` and `238.1 * 430 / 411.4 = 248.9`.
  const Device.pixel9ProXL({
    AndroidNavigation navigation = AndroidNavigation.gesture,
  }) : this(
         name: navigation == AndroidNavigation.threeButton
             ? 'pixel 9 pro xl 3-button'
             : 'pixel 9 pro xl',
         devicePixelRatio: 3,
         width: 430,
         height: 926,
         insets: navigation == AndroidNavigation.threeButton
             ? const EdgeInsets.only(
                 top: 50.3,
                 bottom: AndroidNavigation.threeButtonBottomInset,
               )
             : const EdgeInsets.only(
                 top: 50.3,
                 bottom: AndroidNavigation.gestureBottomInset,
               ),
         platform: TargetPlatform.android,
         navigation: navigation,
         displayFeatures: const [
           DisplayFeature(
             bounds: Rect.fromLTRB(191.2, 0, 248.9, 50.3),
             type: DisplayFeatureType.cutout,
             state: DisplayFeatureState.unknown,
           ),
         ],
       );

  const Device.ipadPro12()
    : this(
        name: 'ipad pro 12',
        devicePixelRatio: 2,
        width: 1024,
        height: 1366,
        insets: const EdgeInsets.only(top: 48, bottom: 40),
        platform: TargetPlatform.iOS,
      );

  /// iPhone Duo, Apple's first foldable, in the given [poses], side by side
  /// in one golden.
  ///
  /// The frame always shows the status cluster, the camera and, half open,
  /// the fold, as on the device. Whether the widget under test sees them in
  /// [MediaQueryData.displayFeatures] is [reportsDisplayFeatures]:
  ///
  /// * `false`, the default, is what Flutter itself reports on iOS: nothing.
  ///   The app does not know about the fold, so dialogs, sheets and layouts
  ///   span it. This is what an app without a plugin for the fold looks like.
  /// * `true` is what an app with such a plugin sees, for example `foldable`
  ///   with `DisplayFeatureBridgeMode.full`. Dialogs and
  ///   sheets then open on one side of the fold, and fold-aware layouts such
  ///   as `duo_kit`'s can split at it.
  ///
  /// The metrics of the cover display are measured on the iPhone Duo
  /// simulator (iOS 27.2); those of the inner display are `duo_kit`'s, as the
  /// simulator cannot be folded from the command line.
  factory Device.iphoneDuo({
    List<IphoneDuoPose> poses = IphoneDuoPose.defaults,
    bool reportsDisplayFeatures = false,
  }) {
    return Device.folding(
      name: 'iphone duo',
      platform: TargetPlatform.iOS,
      postures: [
        for (final pose in poses)
          pose.toDevice(reportsDisplayFeatures: reportsDisplayFeatures),
      ],
    );
  }

  const Device.browser()
    : this(
        name: 'browser',
        devicePixelRatio: 4,
        width: 3024,
        height: 1964,
        insets: const EdgeInsets.only(top: 120),
        platform: TargetPlatform.macOS,
      );

  Device copyWith({
    double? devicePixelRatio,
    double? width,
    double? height,
    EdgeInsets? insets,
    String? name,
    TargetPlatform? platform,
    List<DisplayFeature>? displayFeatures,
    bool? reportsDisplayFeatures,
    AndroidNavigation? navigation,
  }) {
    assert(
      postures.isEmpty ||
          (devicePixelRatio == null &&
              width == null &&
              height == null &&
              insets == null),
      'A folding device takes its window from its postures, so there is '
      'nothing here for a new size or insets to change.',
    );
    // A new navigation mode moves the bottom inset with it, because the mode
    // is what the Android system reserves that inset for. Insets given here
    // win, so a device can still state both.
    final AndroidNavigation nextNavigation = navigation ?? this.navigation;
    final bool navigationMoved =
        nextNavigation != this.navigation &&
        (platform ?? this.platform) == TargetPlatform.android;
    final EdgeInsets nextInsets =
        insets ??
        (navigationMoved
            ? this.insets.copyWith(bottom: nextNavigation.bottomInset)
            : this.insets);

    return Device._(
      name: name ?? this.name,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      width: width ?? this.width,
      height: height ?? this.height,
      insets: nextInsets,
      platform: platform ?? this.platform,
      displayFeatures: displayFeatures ?? this.displayFeatures,
      reportsDisplayFeatures:
          reportsDisplayFeatures ?? this.reportsDisplayFeatures,
      postures: postures,
      navigation: nextNavigation,
    );
  }
}
