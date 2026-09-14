import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final defaultStubPng = goldenTestNetworkImageStubPng;

  void resetGlobals() {
    goldenTestStubNetworkImages = true;
    goldenTestNetworkImageStubPng = defaultStubPng;
    goldenTestImageLoaderSetups.clear();
    debugNetworkImageHttpClientProvider = null;
    PaintingBinding.instance.imageCache.clear();
  }

  setUp(resetGlobals);

  group('runWithNetworkImageStub', () {
    test('installs the stub for the duration of body only', () async {
      HttpClient? insideBody;

      await runWithNetworkImageStub(() async {
        insideBody = debugNetworkImageHttpClientProvider?.call();
      });

      expect(insideBody, isNotNull);
      expect(debugNetworkImageHttpClientProvider, isNull);
    });

    test(
      "restores the caller's own debugNetworkImageHttpClientProvider",
      () async {
        HttpClient callersClient() => HttpClient();
        debugNetworkImageHttpClientProvider = callersClient;

        await runWithNetworkImageStub(() async {
          expect(
            debugNetworkImageHttpClientProvider,
            isNot(same(callersClient)),
          );
        });

        expect(debugNetworkImageHttpClientProvider, same(callersClient));
      },
    );

    test('restores the provider when body throws', () async {
      HttpClient callersClient() => HttpClient();
      debugNetworkImageHttpClientProvider = callersClient;

      await expectLater(
        runWithNetworkImageStub(() async => throw StateError('boom')),
        throwsStateError,
      );

      expect(debugNetworkImageHttpClientProvider, same(callersClient));
    });

    test(
      'leaves HttpOverrides alone, so non-image HTTP is untouched',
      () async {
        final overridesBefore = HttpOverrides.current;

        await runWithNetworkImageStub(() async {
          expect(HttpOverrides.current, same(overridesBefore));

          // Replacing HttpOverrides.global would hand this request to a client
          // that only knows how to answer image GETs; flutter_test's own mock
          // answers everything with a 400 instead.
          final request = await HttpClient().openUrl(
            'GET',
            Uri.parse('https://example.com/api'),
          );
          final response = await request.close();
          expect(response.statusCode, 400);
        });

        expect(HttpOverrides.current, same(overridesBefore));
      },
    );

    test(
      'skips image stubbing when goldenTestStubNetworkImages is false',
      () async {
        goldenTestStubNetworkImages = false;
        var bodyRan = false;

        await runWithNetworkImageStub(() async {
          bodyRan = true;
          expect(debugNetworkImageHttpClientProvider, isNull);
        });

        expect(bodyRan, isTrue);
      },
    );

    test(
      'runs goldenTestImageLoaderSetups even when stubbing is off',
      () async {
        var calls = 0;
        goldenTestImageLoaderSetups.add(() => calls++);

        await runWithNetworkImageStub(() async {});
        expect(calls, 1);

        goldenTestStubNetworkImages = false;
        await runWithNetworkImageStub(() async {});
        expect(
          calls,
          2,
          reason:
              'a registered loader has no working un-stubbed mode in a test',
        );
      },
    );
  });

  group('stub HttpClient', () {
    Future<HttpClientResponse> stubbedGet(String url) async {
      final client = debugNetworkImageHttpClientProvider!();
      final request = await client.getUrl(Uri.parse(url));
      // NetworkImage forwards its `headers`; the stub accepts and discards them.
      request.headers.add('Authorization', 'Bearer token');
      return request.close();
    }

    test('serves goldenTestNetworkImageStubPng with a 200', () async {
      await runWithNetworkImageStub(() async {
        final response = await stubbedGet('https://example.com/a.png');

        expect(response.statusCode, HttpStatus.ok);
        expect(response.contentLength, goldenTestNetworkImageStubPng.length);
        expect(
          response.compressionState,
          HttpClientResponseCompressionState.notCompressed,
        );
        expect(
          await consolidateHttpClientResponseBytes(response),
          goldenTestNetworkImageStubPng,
        );
      });
    });

    test('serves an overridden stub image', () async {
      goldenTestNetworkImageStubPng = Uint8List.fromList([1, 2, 3, 4]);

      await runWithNetworkImageStub(() async {
        final response = await stubbedGet('https://example.com/a.png');
        expect(response.contentLength, 4);
        expect(await consolidateHttpClientResponseBytes(response), [
          1,
          2,
          3,
          4,
        ]);
      });
    });

    test('the response is single-subscription', () async {
      await runWithNetworkImageStub(() async {
        final response = await stubbedGet('https://example.com/a.png');

        var chunks = 0;
        response.listen((_) => chunks++);

        expect(() => response.listen((_) {}), throwsStateError);
        expect(chunks, 1, reason: 'bytes must not be handed out twice');
      });
    });

    test('unimplemented members fail by name', () async {
      await runWithNetworkImageStub(() async {
        final client = debugNetworkImageHttpClientProvider!();

        expect(
          () => client.postUrl(Uri.parse('https://example.com/api')),
          throwsA(
            isA<UnsupportedError>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('HttpClient.postUrl'),
                contains('goldenTestStubNetworkImages'),
              ),
            ),
          ),
        );
      });
    });
  });

  group('NetworkImage integration', () {
    Future<ui.Image> resolve(WidgetTester tester, String url) async {
      late ui.Image image;
      await tester.runAsync(() async {
        final completer = Completer<ImageInfo>();
        NetworkImage(url)
            .resolve(ImageConfiguration.empty)
            .addListener(
              ImageStreamListener(
                (info, _) => completer.complete(info),
                onError: (error, _) => completer.completeError(error),
              ),
            );
        image = (await completer.future).image;
      });
      return image;
    }

    testWidgets('resolves to the stub image', (tester) async {
      await runWithNetworkImageStub(() async {
        final image = await resolve(tester, 'https://example.com/resolved.png');
        expect(image.width, 256);
        expect(image.height, 256);
      });
    });

    testWidgets('fails to load when stubbing is disabled', (tester) async {
      goldenTestStubNetworkImages = false;

      // The load failure is also reported through FlutterError; intercept it so
      // the binding doesn't record it as an unexpected test exception.
      final reported = <Object>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) => reported.add(details.exception);

      Object? listenerError;
      try {
        await runWithNetworkImageStub(() async {
          await tester.runAsync(() async {
            final completer = Completer<void>();
            const NetworkImage('https://example.com/unstubbed.png')
                .resolve(ImageConfiguration.empty)
                .addListener(
                  ImageStreamListener(
                    (_, __) => completer.complete(),
                    onError: (error, _) {
                      listenerError = error;
                      completer.complete();
                    },
                  ),
                );
            await completer.future;
          });
        });
      } finally {
        FlutterError.onError = previousOnError;
      }

      // flutter_test's 400 surfaces as a plain load failure rather than the
      // indefinite hang an un-stubbed CachedNetworkImage would produce.
      expect(listenerError, isA<NetworkImageLoadException>());
      expect((listenerError! as NetworkImageLoadException).statusCode, 400);
      expect(reported, everyElement(isA<NetworkImageLoadException>()));
    });
  });

  group('default stub image', () {
    test('is a coarse 4x4 checkerboard', () async {
      final codec = await ui.instantiateImageCodec(
        goldenTestNetworkImageStubPng,
      );
      final image = (await codec.getNextFrame()).image;
      addTearDown(image.dispose);

      expect(image.width, 256);
      expect(image.height, 256);

      final pixels = (await image.toByteData())!;
      int luminanceAt(int x, int y) =>
          pixels.getUint8((y * image.width + x) * 4);

      // 64px blocks that alternate in both directions.
      expect(luminanceAt(32, 32), 0x00);
      expect(luminanceAt(96, 32), 0xFF);
      expect(luminanceAt(32, 96), 0xFF);
      expect(luminanceAt(96, 96), 0x00);

      // Each block is flat, which is what keeps the stub free of the
      // filtering-dependent moire a fine checkerboard produces when scaled.
      for (final offset in [2, 20, 40, 61]) {
        expect(
          luminanceAt(offset, offset),
          0x00,
          reason: 'pixel ($offset, $offset) should be inside the first block',
        );
      }
    });
  });
}
