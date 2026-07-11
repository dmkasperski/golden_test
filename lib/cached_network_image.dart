/// Opt-in support for `cached_network_image`'s `CachedNetworkImage` widget in
/// golden tests. Not exported by `package:golden_test/golden_test.dart` —
/// import this file directly only if your project already uses
/// `CachedNetworkImage` (and therefore already depends on
/// `cached_network_image` and `flutter_cache_manager`).
library;

export 'src/cached_network_image_support.dart';
