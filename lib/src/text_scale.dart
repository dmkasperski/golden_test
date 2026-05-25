/// Android **Settings → Display → Font size** presets.
///
/// Maps to [Configuration.fontScale](https://developer.android.com/reference/android/content/res/Configuration#fontScale)
/// values. On Android 14+ native apps use non-linear scaling; Flutter goldens
/// apply these as linear [textScaleFactor](https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/textScaleFactor.html)
/// values for layout regression testing.
///
/// ```dart
/// supportedTextScales: [1.0, AndroidFontScale.extraLarge.value],
/// ```
enum AndroidFontScale {
  /// Small (~85%).
  small(0.85),

  /// Default (100%).
  defaultScale(1.0),

  /// Large (~115%).
  large(1.15),

  /// Largest classic preset (~130%).
  largest(1.30),

  /// Common slider point (~150%).
  extraLarge(1.50),

  /// Common slider point (~180%).
  extraExtraLarge(1.80),

  /// Maximum commonly available on the font-size slider (~200%).
  maximum(2.0);

  const AndroidFontScale(this.value);

  /// Linear scale factor used by [goldenTest].
  final double value;
}

/// Android font-size slider points from **Largest** through maximum (~130%–200%).
///
/// Useful as a ready-made matrix alongside the default `1.0` baseline:
///
/// ```dart
/// supportedTextScales: [1.0, ...androidAccessibilityTextScalePresets],
/// ```
List<double> get androidAccessibilityTextScalePresets => [
      AndroidFontScale.largest.value,
      AndroidFontScale.extraLarge.value,
      AndroidFontScale.extraExtraLarge.value,
      AndroidFontScale.maximum.value,
    ];

/// iOS **Dynamic Type** content size categories.
///
/// Maps to approximate Flutter [textScaleFactor](https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/textScaleFactor.html)
/// values reported on iOS. Accessibility sizes (AX1–AX5) require **Larger
/// Accessibility Sizes** in system settings.
///
/// ```dart
/// supportedTextScales: [1.0, IosDynamicTypeScale.accessibilityLarge.value],
/// ```
enum IosDynamicTypeScale {
  /// Extra Small (~0.82×).
  extraSmall(0.82),

  /// Small (~0.88×).
  small(0.88),

  /// Medium (~0.94×).
  medium(0.94),

  /// Large — system default (~1.0×).
  large(1.0),

  /// Extra Large (~1.12×).
  extraLarge(1.12),

  /// Extra Extra Large (~1.23×).
  extraExtraLarge(1.23),

  /// Extra Extra Extra Large (~1.35×).
  extraExtraExtraLarge(1.35),

  /// Accessibility Medium / AX1 (~1.64×).
  accessibilityMedium(1.64),

  /// Accessibility Large / AX2 (~1.95×).
  accessibilityLarge(1.95),

  /// Accessibility Extra Large / AX3 (~2.35×).
  accessibilityExtraLarge(2.35),

  /// Accessibility Extra Extra Large / AX4 (~2.76×).
  accessibilityExtraExtraLarge(2.76),

  /// Accessibility Extra Extra Extra Large / AX5 (~3.12×).
  accessibilityExtraExtraExtraLarge(3.12);

  const IosDynamicTypeScale(this.value);

  /// Linear scale factor used by [goldenTest].
  final double value;
}

/// iOS accessibility Dynamic Type sizes (AX1–AX5).
///
/// Requires **Larger Accessibility Sizes** enabled in iOS settings. Useful as a
/// ready-made matrix alongside the default `1.0` baseline:
///
/// ```dart
/// supportedTextScales: [1.0, ...iosAccessibilityTextScalePresets],
/// ```
List<double> get iosAccessibilityTextScalePresets => [
      IosDynamicTypeScale.accessibilityMedium.value,
      IosDynamicTypeScale.accessibilityLarge.value,
      IosDynamicTypeScale.accessibilityExtraLarge.value,
      IosDynamicTypeScale.accessibilityExtraExtraLarge.value,
      IosDynamicTypeScale.accessibilityExtraExtraExtraLarge.value,
    ];
