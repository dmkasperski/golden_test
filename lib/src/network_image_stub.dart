import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:golden_test/src/config.dart';

/// PNG bytes returned for every network image request during golden tests.
///
/// Defaults to a 256×256 black-and-white checkerboard of 4×4 large squares,
/// instantly recognizable as a placeholder regardless of crop or `BoxFit`, and
/// legible over both light and dark app backgrounds without needing separate
/// assets.
///
/// Replacements should stay coarse. A fine-grained pattern aliases when scaled
/// into an arbitrarily sized box, and the interference depends on the
/// platform's image filtering, which makes goldens flaky across macOS / Linux /
/// Windows.
///
/// Override in `flutter_test_config.dart` to supply custom bytes, e.g.:
/// ```dart
/// goldenTestNetworkImageStubPng = myPlaceholderPngBytes;
/// ```
Uint8List goldenTestNetworkImageStubPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAAAAAB5Gfe6AAABQ0lEQVR42u3RQQ0AAAgDMfybBhH7'
  'sKRnYEk3E7Zh7fsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
  'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAADABwAPAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
  'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP0AAAEAAAAAAAAAAAAAAAAA'
  'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIB+'
  'AA8CAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
  'AAAAAAAAAAAAAAAAAAAA9QAHNY+HckZ+agwAAAAASUVORK5CYII=',
);

/// Runs [body] with [NetworkImage] loads resolved from
/// [goldenTestNetworkImageStubPng] instead of the network.
///
/// Only [NetworkImage] is affected. [HttpOverrides] is left alone, so other
/// `dart:io` traffic keeps reaching `flutter_test`'s own mock, which answers
/// everything with a 400.
///
/// Image stubbing is skipped when [goldenTestStubNetworkImages] is false;
/// [goldenTestImageLoaderSetups] run either way — see their documentation for
/// why.
Future<T> runWithNetworkImageStub<T>(Future<T> Function() body) async {
  // Runs before the early return below: a registered loader has no working
  // un-stubbed mode in the test zone.
  for (final setup in goldenTestImageLoaderSetups) {
    setup();
  }

  if (!goldenTestStubNetworkImages) return body();

  final previousProvider = debugNetworkImageHttpClientProvider;
  debugNetworkImageHttpClientProvider = () => _FakeHttpClient();
  try {
    return await body();
  } finally {
    debugNetworkImageHttpClientProvider = previousProvider;
  }
}

Never _unimplemented(Invocation invocation, String type) {
  final symbol = invocation.memberName.toString();
  final name = RegExp(r'"(.*)"').firstMatch(symbol)?.group(1) ?? symbol;
  throw UnsupportedError(
    "golden_test's network image stub does not implement $type.$name. The stub "
    'covers the requests NetworkImage makes; if you need broader HTTP faking, '
    'set goldenTestStubNetworkImages = false and install your own '
    'HttpOverrides or HttpClient.',
  );
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  int? maxConnectionsPerHost;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _unimplemented(invocation, 'HttpClient');
}

class _FakeHttpClientRequest implements HttpClientRequest {
  final _headers = _FakeHttpHeaders();

  @override
  HttpHeaders get headers => _headers;

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();

  @override
  Future<HttpClientResponse> get done async => _FakeHttpClientResponse();

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await stream.drain<void>();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _unimplemented(invocation, 'HttpClientRequest');
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  bool persistentConnection = false;

  @override
  bool chunkedTransferEncoding = false;

  @override
  int contentLength = -1;

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void remove(String name, Object value) {}

  @override
  void removeAll(String name) {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}

  @override
  void noFolding(String name) {}

  @override
  void clear() {}

  @override
  List<String>? operator [](String name) => null;

  @override
  String? value(String name) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _unimplemented(invocation, 'HttpHeaders');
}

/// A no-op [StreamSubscription] returned after synchronous delivery of stub data.
class _CompletedStreamSubscription implements StreamSubscription<List<int>> {
  @override
  bool get isPaused => false;

  @override
  Future<void> cancel() => Future<void>.value();

  @override
  void onData(void Function(List<int> data)? handleData) {}

  @override
  void onError(Function? handleError) {}

  @override
  void onDone(void Function()? handleDone) {}

  @override
  void pause([Future<void>? resumeSignal]) {}

  @override
  void resume() {}

  @override
  Future<E> asFuture<E>([E? futureValue]) => Future<E>.value(futureValue as E);
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  bool _listened = false;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => goldenTestNetworkImageStubPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    if (_listened) {
      throw StateError('Stream has already been listened to.');
    }
    _listened = true;

    // Deliver data synchronously so consolidateHttpClientResponseBytes
    // collects the bytes in the same microtask, regardless of zone context.
    onData?.call(goldenTestNetworkImageStubPng);
    onDone?.call();
    return _CompletedStreamSubscription();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      _unimplemented(invocation, 'HttpClientResponse');
}
