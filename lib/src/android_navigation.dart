/// How an Android device shows its navigation.
///
/// It is not only a way of drawing: the mode decides how much of the screen
/// the system keeps for itself, so it sets `Device.insets.bottom` as well as
/// what the device frame draws there.
///
/// The numbers are measured on a Pixel 6a emulator (Android 16, API 36,
/// 1080 x 2400 at 420 dpi, so 411.4 x 914.3 logical at a device pixel ratio
/// of 2.625), switching modes with `adb shell cmd overlay enable-exclusive
/// --category com.android.internal.systemui.navbar.MODE`, where `MODE` is
/// `gestural`, `threebutton` or `twobutton`.
///
/// Android's old two-button mode is deliberately absent: a device set to it
/// reserves the same 24.0 as gestures and draws the gesture pill, so it is
/// not a mode of its own any more.
enum AndroidNavigation {
  /// Gesture navigation, Android's default since Android 10, drawn as one
  /// horizontal pill over a bottom inset of
  /// [AndroidNavigation.gestureBottomInset].
  gesture,

  /// The three-button bar — back, home and recents — over a bottom inset of
  /// [AndroidNavigation.threeButtonBottomInset].
  threeButton;

  /// The bottom inset this mode reserves, in logical pixels.
  double get bottomInset => switch (this) {
    AndroidNavigation.gesture => gestureBottomInset,
    AndroidNavigation.threeButton => threeButtonBottomInset,
  };

  /// The bottom inset [AndroidNavigation.gesture] reserves.
  ///
  /// A constant as well as [bottomInset], because a `const Device` has to be
  /// able to name it in its own initializer.
  static const double gestureBottomInset = 24.0;

  /// The bottom inset [AndroidNavigation.threeButton] reserves.
  static const double threeButtonBottomInset = 48.0;
}
