import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:golden_test/src/device.dart';
import 'package:material_ui/material_ui.dart';

// Window metrics of iPhone Duo, in logical pixels.
//
// The cover display in portrait is measured on the iPhone Duo simulator
// (iOS 27.2), down to the camera and the status cluster. The inner display
// and the landscape rotations are not: the simulator cannot be folded or
// turned from the command line, so those figures are duo_kit's
// (https://pub.dev/packages/duo_kit, FoldTestPose), unverified here.
const _coverWidth = 466.0;
const _coverHeight = 678.0;
const _innerLongSide = 951.0;
const _innerShortSide = 669.0;

const _stripWidth = 84.0;
const _homeIndicatorHeight = 34.0;
const _innerPortraitTopInset = 82.0;
const _coverStatusClusterHeight = 170.0;
const _coverLandscapeStatusClusterHeight = 82.0;
const _innerLandscapeStatusClusterHeight = 120.0;
const _innerPortraitStatusClusterWidth = 134.0;
const _foldThickness = 40.0;
const _foldOffset = 455.5;
const _cameraInset = 29.3;
const _cameraSize = 37.0;

const _rightStrip = EdgeInsets.only(
  right: _stripWidth,
  bottom: _homeIndicatorHeight,
);
const _leftStrip = EdgeInsets.only(
  left: _stripWidth,
  bottom: _homeIndicatorHeight,
);
const _innerPortraitInsets = EdgeInsets.only(
  top: _innerPortraitTopInset,
  bottom: _homeIndicatorHeight,
);

DisplayFeature _cutout(Rect bounds) => DisplayFeature(
  bounds: bounds,
  type: DisplayFeatureType.cutout,
  state: DisplayFeatureState.unknown,
);

DisplayFeature _halfOpenFold(Rect bounds) => DisplayFeature(
  bounds: bounds,
  type: DisplayFeatureType.fold,
  state: DisplayFeatureState.postureHalfOpened,
);

/// A pose of iPhone Duo, Apple's foldable, for [Device.iphoneDuo].
///
/// The inner display is one panel that folds down the middle. Half open, the
/// fold is a 40 pt band, and the system reports it only then: lying flat, the
/// display has no fold. The status bar sits in a cluster at the top of a strip
/// along the side of the window, 84 pt wide, except on the inner display in
/// portrait, where it is in the top right corner. On the inner display the
/// strip stays on the right in both landscape rotations; on the cover display
/// it follows the camera.
enum IphoneDuoPose {
  /// The cover display of the closed device.
  closed('closed', Size(_coverWidth, _coverHeight), _rightStrip),

  /// The cover display in landscape, with the camera and the strip on the
  /// left.
  closedLandscapeLeft(
    'closed, landscape left',
    Size(_coverHeight, _coverWidth),
    _leftStrip,
  ),

  /// The cover display in landscape, with the camera and the strip on the
  /// right.
  closedLandscapeRight(
    'closed, landscape right',
    Size(_coverHeight, _coverWidth),
    _rightStrip,
  ),

  /// Half open like a book: the inner display in landscape, with a fold from
  /// top to bottom.
  halfOpenBook(
    'half open, book',
    Size(_innerLongSide, _innerShortSide),
    _rightStrip,
  ),

  /// Half open like a laptop: the inner display in portrait, with a fold from
  /// edge to edge across the middle.
  halfOpenLaptop(
    'half open, laptop',
    Size(_innerShortSide, _innerLongSide),
    _innerPortraitInsets,
  ),

  /// The inner display lying flat, in landscape.
  open('open', Size(_innerLongSide, _innerShortSide), _rightStrip),

  /// The inner display lying flat, in portrait.
  openPortrait(
    'open, portrait',
    Size(_innerShortSide, _innerLongSide),
    _innerPortraitInsets,
  );

  const IphoneDuoPose(this.label, this.size, this.insets);

  /// The poses an iPhone Duo golden shows unless told otherwise: the cover
  /// display, both ways of holding the device half open, and the inner
  /// display lying flat.
  static const List<IphoneDuoPose> defaults = [
    closed,
    halfOpenBook,
    halfOpenLaptop,
    open,
  ];

  /// The name of the pose, written under its screen in the golden.
  final String label;

  /// The size of the window, in logical pixels.
  final Size size;

  /// The safe area: the strip or the status bar, and the home indicator.
  final EdgeInsets insets;

  /// The status cluster, the camera of the cover display and the fold, in
  /// window coordinates, as a plugin that publishes them reports them.
  List<DisplayFeature> get displayFeatures => switch (this) {
    closed => [
      _cutout(
        const Rect.fromLTWH(
          _coverWidth - _cameraInset - _cameraSize,
          _cameraInset,
          _cameraSize,
          _cameraSize,
        ),
      ),
      _cutout(
        const Rect.fromLTRB(
          _coverWidth - _stripWidth,
          0,
          _coverWidth,
          _coverStatusClusterHeight,
        ),
      ),
    ],
    closedLandscapeLeft => [
      _cutout(
        const Rect.fromLTWH(
          _cameraInset,
          _cameraInset,
          _cameraSize,
          _cameraSize,
        ),
      ),
      _cutout(
        const Rect.fromLTRB(
          0,
          0,
          _stripWidth,
          _coverLandscapeStatusClusterHeight,
        ),
      ),
    ],
    closedLandscapeRight => [
      _cutout(
        const Rect.fromLTWH(
          _coverHeight - _cameraInset - _cameraSize,
          _coverWidth - _cameraInset - _cameraSize,
          _cameraSize,
          _cameraSize,
        ),
      ),
      _cutout(
        const Rect.fromLTRB(
          _coverHeight - _stripWidth,
          _coverWidth - _coverLandscapeStatusClusterHeight,
          _coverHeight,
          _coverWidth,
        ),
      ),
    ],
    halfOpenBook => [
      _innerLandscapeStatusCluster,
      _halfOpenFold(
        const Rect.fromLTWH(_foldOffset, 0, _foldThickness, _innerShortSide),
      ),
    ],
    halfOpenLaptop => [
      _innerPortraitStatusCluster,
      _halfOpenFold(
        const Rect.fromLTWH(0, _foldOffset, _innerShortSide, _foldThickness),
      ),
    ],
    open => [_innerLandscapeStatusCluster],
    openPortrait => [_innerPortraitStatusCluster],
  };

  static final DisplayFeature _innerLandscapeStatusCluster = _cutout(
    const Rect.fromLTRB(
      _innerLongSide - _stripWidth,
      0,
      _innerLongSide,
      _innerLandscapeStatusClusterHeight,
    ),
  );

  static final DisplayFeature _innerPortraitStatusCluster = _cutout(
    const Rect.fromLTRB(
      _innerShortSide - _innerPortraitStatusClusterWidth,
      0,
      _innerShortSide,
      _innerPortraitTopInset,
    ),
  );

  /// This pose as a screen of [Device.iphoneDuo].
  Device toDevice({required bool reportsDisplayFeatures}) => Device(
    name: label,
    devicePixelRatio: 3,
    width: size.width,
    height: size.height,
    insets: insets,
    platform: TargetPlatform.iOS,
    displayFeatures: displayFeatures,
    reportsDisplayFeatures: reportsDisplayFeatures,
  );
}
