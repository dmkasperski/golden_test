import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:golden_test/src/config.dart';

/// PNG bytes returned for every network image request during golden tests.
///
/// Defaults to a 100×100 [Placeholder]-style image (light gray fill + blue-grey
/// border and diagonals) so network image slots are clearly visible in goldens.
/// Override in `flutter_test_config.dart` to supply custom bytes, e.g.:
/// ```dart
/// goldenTestNetworkImageStubPng = myPlaceholderPngBytes;
/// ```
Uint8List goldenTestNetworkImageStubPng = base64Decode(
  // 100×100 Placeholder-style PNG: light gray fill, blue-grey (#455A64) border
  // and diagonals — visually matches Flutter's Placeholder widget.
  'iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAC5klEQVR4nO3aTW4jIRQE'
  'YLuVq+USWacuMZpllEv4cn0TR15EkyFuu3/eTxW8WtpuQHwCGvB5nucr/nycLp9/T5W8'
  '3AxuOb++vV8T21FpMtXI4MnN4mXpi0rcNPUz09ofVmyz1MfT0sgoFL/87Nt2Nvo1Qgol'
  'D2NxyiqUHIxFkPaBQonBeAjSPlgo/hhPQdoCCsUXYxVIW1Ch+GGsBmkLLBQfjE0gbcGF'
  'Yo+xGaStoFBsMXaBtBUVih3GbpC2wkI5mWAcAmkrHhkFRhiHQdoGjIgCQwwTkJFRYIxh'
  'BjIiChwwTEFGQoEThjnICChwxHAB6RkFzhhuID2iIADDFaQnFARhuIP0gIJAjBAQZRQE'
  'Y4SBKKIgASMURAkFSRjhIAooSMRIAWFGQTJGGggjCggwUkGYUECCkQ7CgAIiDAqQTBSQ'
  'YdCAZKCAEIMKJBIFpBh0IBEozBiUIJ4o7Bi0IB4oChjUIJYoKhj0IBYoShgSIEdQ1DBk'
  'QPagKGJIgWxBUcWQA1mDoowhCfIIRR1DFuQeSg8Y0iBLHa+MIQ/SY6RB8GRRV4wsCJo1'
  'I/vmcWgQLCzgPaDIgeDJ25Q6ihQIVr7aKqPIgGDjPkMVRQIEOzd9iij0IDi4A1dDoQaB'
  '0XGIEgotCIzPplRQKEHgdFCogEIHAudTW3YUKhAEHaEzo9CARN9nXEhRKECyLpcuhCjp'
  'INk3fRcylGlkDEaUaXQMNpQUEDYMJpRwEFYMFpRQEHYMBpQwEBWMbJQQEDWMTBR3EFWM'
  'LBRXEHWMDBQ3kF4wolFcQHrDiEQxB+kVIwrFFKR3jAgUM5BRMLxRTEBGw/BEOQwyKoYX'
  'yiGQ0TE8UHaDFIYPyi6QwvBD2QxSGL4om0AKwx9lNUhhxKCsAimMOJSnIIURi/IQpDDi'
  'URZBCiMH5S5IYeSh/AIpjFyU/0AKIx/l7pRVGP5Z6uOXex9m/wN85Jxf396v2Y2o/Mt5'
  'nufrbUTUNHVKzfes9AV7sDiM+4+DkwAAAABJRU5ErkJggg==',
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
