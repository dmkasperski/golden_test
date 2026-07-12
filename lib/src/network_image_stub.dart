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
/// rather than as real content. Rendered with a transparent fill and a
/// white-halo + dark-stroke double outline, so it stays legible over both
/// light and dark app backgrounds without needing separate light/dark assets.
/// Override in `flutter_test_config.dart` to supply custom bytes, e.g.:
/// ```dart
/// goldenTestNetworkImageStubPng = myPlaceholderPngBytes;
/// ```
Uint8List goldenTestNetworkImageStubPng = base64Decode(
  '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'
  '0yl8vNrnEDdL6ao7rYFEQAcM1qQX1J8zrcuI2c0Ls64l1G1GccchJxYSC+qlocN5krmn'
  'h183FMd794CJraSC+jfT1mqPE7EOJae1bijWBbSvWRKrrg8BgtrfikI+V95xgrKn01pT'
  'SxPQAb8sXAriMoMmDfj+oZUe6GY/Qdl7HcrUUhu+2wADiHXBfQoYPBn29RfTIMbYdQj2'
  'BH1GCQRaDU8NcFtpmGRBdCfRLn5ZiNCQiiBr4KEBXp+sacAiCbUkan0eqTTFE5sRCxo8'
  'GWkUoVbxp1NPE6e7z5gL0VHr69t+rF9YYFoRr4AIYumCOmIB1mSh1mj31V3VZL41jqFE'
  '9/G6DGGoJTq4m+YRT6zq18rIt0MEwx9VJedX40Ot/v1GVI5Rjfbul7J+W9nEreJg39nU'
  '5e89lLXrBGVftMi9e7zR/W6EodY72koT39CEaQ/ay0VvwYLNkjsbmZK4OE5Q9vPxPZyB'
  '5rIQaXhuONYvdEtx8RINC1M9aNzVHup03FC0fudaLVVU00t/d1OUV/0vydWm6bgxm/tt'
  'I90bN1PC8MiLlZHvw9cH65IxXIqfiEOriXFavytxBKzmS61mXW5JcLGoQop/xn8yWB6x'
  'PF+wlK02govFtjX2vB38d0V4sfi2xoqp1RShw/pi0dXQ/zQ8bZZ3hBdriRpe/goj6tLL'
  'WGWwaLH6a8BqB5JZzuKvsEndZcOWIxFd569gVrZs2bJly5YtW7Zs2bJly5YtW7ZsJ7D/'
  'A/EVSy7LpI2JAAAAAElFTkSuQmCC',
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
  bool findProxyFromEnvironment = false;

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
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

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
