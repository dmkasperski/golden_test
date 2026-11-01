import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';
import 'package:material_ui/material_ui.dart';

const Map<String, Color> _testImageColors = {
  'en': Color(0xFFFF0000),
  'es': Color(0xFF0000FF),
};

void main() {
  late Directory dir;
  late Locale locale;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('golden_test_');
    // The comparator `flutter test` installs, with no tolerance set, pointed
    // at a temporary directory.
    goldenFileComparator = LocalFileComparator(
      dir.uri.resolve('variants_test.dart'),
    );
    // Acts like `--update-goldens` for the screenshot `goldenTest` takes after
    // `action`. The temporary directory has no golden for it, so comparing it
    // would fail the test; the failure under test is the one in `action`.
    autoUpdateGoldenFiles = true;
  });

  tearDownAll(() async {
    autoUpdateGoldenFiles = false;
    await dir.delete(recursive: true);
  });

  // A failing golden can't be asserted through `goldenTest`'s own screenshot,
  // because the failure would fail this test. Instead each variant calls the
  // comparator `goldenTest` installed, as `matchesGoldenFile` does, with an
  // image that doesn't match.
  //
  // This test only writes the failure images; the next test asserts them.
  goldenTest(
    name: 'Variant',
    supportedLocales: [const Locale('en'), const Locale('es')],
    supportedThemes: [Brightness.light],
    supportedDevices: [const Device(width: 40, height: 40)],
    builder: (BuildContext context) {
      locale = Localizations.localeOf(context);
      return const SizedBox();
    },
    action: (WidgetTester tester) async {
      final Uri golden = Uri.parse(
        'goldens/${locale.languageCode}/light/Failing.png',
      );
      await tester.runAsync(() async {
        await goldenFileComparator.update(
          golden,
          await _solidPng(Colors.white),
        );
        await expectLater(
          goldenFileComparator.compare(
            await _solidPng(_testImageColors[locale.languageCode]!),
            golden,
          ),
          throwsA(isA<FlutterError>()),
        );
      });
    },
  );

  // Asserts the failure images the `Variant` tests above wrote, so it relies
  // on them running first, in file order. Run on its own (e.g. with `--name`
  // or from the editor) or in a random order, it fails as the files are
  // missing.
  testWidgets('each variant keeps its own failure images', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      for (final MapEntry(key: languageCode, value: color)
          in _testImageColors.entries) {
        final File testImage = File.fromUri(
          dir.uri.resolve(
            'goldens/$languageCode/light/failures/Failing_testImage.png',
          ),
        );
        expect(await _firstPixel(testImage), color);
      }
      expect(
        Directory.fromUri(dir.uri.resolve('failures/')).existsSync(),
        isFalse,
      );
    });
  });
}

Future<Uint8List> _solidPng(Color color) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  Canvas(recorder).drawColor(color, BlendMode.src);
  final ui.Image image = await recorder.endRecording().toImage(4, 4);
  final ByteData? bytes = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  image.dispose();
  return bytes!.buffer.asUint8List();
}

Future<Color> _firstPixel(File png) async {
  final ui.Codec codec = await ui.instantiateImageCodec(
    await png.readAsBytes(),
  );
  final ui.Image image = (await codec.getNextFrame()).image;
  final ByteData rgba = (await image.toByteData())!;
  image.dispose();
  return Color.fromARGB(
    rgba.getUint8(3),
    rgba.getUint8(0),
    rgba.getUint8(1),
    rgba.getUint8(2),
  );
}
