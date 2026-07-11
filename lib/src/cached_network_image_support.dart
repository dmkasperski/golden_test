// This file is intentionally not exported by golden_test.dart's main barrel
// and these packages are intentionally declared as dev_dependencies, not
// dependencies, in pubspec.yaml. Consumers who import this file directly
// only do so because they already use CachedNetworkImage, and therefore
// already have cached_network_image/flutter_cache_manager resolvable in
// their own dependency graph — golden_test doesn't force these packages on
// anyone who doesn't import this file.
// ignore: depend_on_referenced_packages
import 'package:cached_network_image/cached_network_image.dart';
// ignore: depend_on_referenced_packages
import 'package:file/file.dart' as f;
// ignore: depend_on_referenced_packages
import 'package:file/memory.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:golden_test/src/config.dart';
import 'package:golden_test/src/network_image_stub.dart';

/// A [BaseCacheManager] for golden tests that serves [goldenTestNetworkImageStubPng]
/// without any SQLite or platform-channel dependencies.
///
/// [flutter_cache_manager]'s default [CacheManager] uses SQLite for persistence.
/// SQLite relies on Flutter platform channels which do not function inside Flutter's
/// fake-async test zone, causing golden tests with [CachedNetworkImage] to hang or
/// silently stall on the loading state indefinitely. This stub bypasses the
/// persistence layer entirely — all "files" live in a [MemoryFileSystem] so every
/// read completes as a microtask and works within the normal [pumpAndSettle] loop.
class GoldenTestCacheManager implements BaseCacheManager {
  final _memFs = MemoryFileSystem();
  final _cache = <String, f.File>{};

  f.File _file(String url) {
    return _cache.putIfAbsent(url, () {
      final file = _memFs.file('/${url.hashCode}.png');
      file.writeAsBytesSync(goldenTestNetworkImageStubPng);
      return file;
    });
  }

  // Fixed, far-future expiry — this stub's entries never actually need to
  // expire, and a static date avoids wall-clock/timezone-dependent flakiness.
  static final _validTill = DateTime.utc(2100);

  FileInfo _info(String url) => FileInfo(
        _file(url),
        FileSource.Online,
        _validTill,
        url,
      );

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) async* {
    yield _info(url);
  }

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) async =>
      _info(url);

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async =>
      _cache.containsKey(key) ? _info(key) : null;

  @override
  Future<FileInfo?> getFileFromMemory(String key) async =>
      _cache.containsKey(key) ? _info(key) : null;

  @override
  Future<void> removeFile(String key) async => _cache.remove(key);

  @override
  Future<void> emptyCache() async => _cache.clear();

  @override
  Future<void> dispose() async {}

  // Satisfies remaining BaseCacheManager members not called by CachedNetworkImage in tests.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Registers [GoldenTestCacheManager] so [CachedNetworkImage] works in golden
/// tests out of the box.
///
/// Call this once in `flutter_test_config.dart`:
/// ```dart
/// import 'package:golden_test/cached_network_image.dart';
///
/// Future<void> testExecutable(FutureOr<void> Function() testMain) async {
///   ...
///   setupGoldenTestCachedNetworkImage();
///   return testMain();
/// }
/// ```
void setupGoldenTestCachedNetworkImage() {
  goldenTestCachedNetworkImageManager = () {
    CachedNetworkImageProvider.defaultCacheManager = GoldenTestCacheManager();
  };
}
