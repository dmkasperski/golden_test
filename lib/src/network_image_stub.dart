import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:golden_test/src/config.dart';

/// PNG bytes returned for every network image request during golden tests.
///
/// Defaults to a 300×300 stub depicting the standard "missing image" glyph
/// (frame, sun, mountains) so network image slots read clearly as placeholders
/// rather than as real content. The sun/mountains are solid-filled (not just
/// outlined) so a tight `BoxFit.cover` crop — e.g. a small circular avatar —
/// still lands on visible content instead of transparent empty space. Drawn
/// with a white-halo + dark-fill double outline, so it stays legible over
/// both light and dark app backgrounds without needing separate assets.
/// Override in `flutter_test_config.dart` to supply custom bytes, e.g.:
/// ```dart
/// goldenTestNetworkImageStubPng = myPlaceholderPngBytes;
/// ```
Uint8List goldenTestNetworkImageStubPng = base64Decode(
  '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',
);

/// Runs [body] with all `dart:io` HTTP requests and [NetworkImage] loads
/// intercepted and resolved with [goldenTestNetworkImageStubPng].
///
/// Does nothing when [goldenTestStubNetworkImages] is false.
///
/// Uses [HttpOverrides.global] (not runZoned) so the override is visible inside
/// [WidgetTester.runAsync], which escapes the FakeAsync zone.
Future<T> runWithNetworkImageStub<T>(Future<T> Function() body) async {
  if (!goldenTestStubNetworkImages) return body();

  goldenTestCachedNetworkImageManager?.call();
  final previousOverrides = HttpOverrides.current;
  HttpOverrides.global = _FakeHttpOverrides();
  debugNetworkImageHttpClientProvider = () => _FakeHttpClient();
  try {
    return await body();
  } finally {
    HttpOverrides.global = previousOverrides is _FakeHttpOverrides
        ? null
        : previousOverrides;
    debugNetworkImageHttpClientProvider = null;
  }
}

class _FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
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
  Future<HttpClientRequest> get(String host, int port, String path) async =>
      _FakeHttpClientRequest();

  @override
  void close({bool force = false}) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
    // Deliver data synchronously so consolidateHttpClientResponseBytes
    // collects the bytes in the same microtask, regardless of zone context.
    onData?.call(goldenTestNetworkImageStubPng);
    onDone?.call();
    return _CompletedStreamSubscription();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
