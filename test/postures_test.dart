import 'dart:typed_data';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/golden_test.dart';
import 'package:material_ui/material_ui.dart';

/// Records what is compared instead of reading golden files, so these tests
/// check the postures without depending on how fonts render on a machine.
class _RecordingComparator extends GoldenFileComparator {
  final List<Uint8List> compared = [];

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    compared.add(imageBytes);
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {}
}

/// Width and height from the IHDR chunk of a PNG.
(int, int) _pngSize(Uint8List png) {
  final data = ByteData.sublistView(png);
  return (data.getUint32(16), data.getUint32(20));
}

void main() {
  final screens = <(Size, List<DisplayFeature>)>[];
  var initStates = 0;
  var taps = 0;

  /// Records what each posture of [duo] reaches the widget with, and checks
  /// it once every posture is compared.
  void postureGolden(
    String name,
    Device duo,
    void Function(List<(Size, List<DisplayFeature>)> screens) check,
  ) {
    group(name, () {
      setUp(() {
        final previousComparator = goldenFileComparator;
        final comparator = _RecordingComparator();
        goldenFileComparator = comparator;
        screens.clear();
        initStates = 0;
        taps = 0;

        // Runs after the whole goldenTest, once every posture is compared.
        addTearDown(() {
          goldenFileComparator = previousComparator;

          final postures = duo.postures;
          expect(initStates, postures.length, reason: 'built from scratch');
          expect(taps, postures.length, reason: 'action ran per posture');
          expect(screens.map((s) => s.$1).toList(), [
            const Size(466, 678),
            const Size(951, 669),
            const Size(669, 951),
            const Size(951, 669),
          ]);
          check(screens);

          expect(comparator.compared, hasLength(1), reason: 'one golden file');
          final (width, height) = _pngSize(comparator.compared.single);
          expect(
            width,
            greaterThan(postures.fold(0.0, (sum, p) => sum + p.width) * 3),
          );
          expect(height, greaterThan(951 * 3));
        });
      });

      goldenTest(
        name: name,
        supportedLocales: [const Locale('en')],
        supportedThemes: [Brightness.light],
        supportedDevices: [duo],
        builder: (_) => _Probe(
          onInit: () => initStates++,
          onTap: () => taps++,
          onBuild: (media) => screens.add((media.size, media.displayFeatures)),
        ),
        action: (tester) async {
          await tester.tap(find.text('Tap'));
          await tester.pump();
        },
      );
    });
  }

  postureGolden('Duo postures', Device.iphoneDuo(), (screens) {
    // Flutter reports no display features on iOS by itself.
    expect(screens.expand((s) => s.$2), isEmpty);
  });

  postureGolden(
    'Duo postures, display features reported',
    Device.iphoneDuo(reportsDisplayFeatures: true),
    (screens) {
      List<DisplayFeature> folds(int index) => [
        for (final feature in screens[index].$2)
          if (feature.type == DisplayFeatureType.fold) feature,
      ];
      expect(folds(0), isEmpty, reason: 'closed');
      expect(folds(1).single.bounds, const Rect.fromLTWH(455.5, 0, 40, 669));
      expect(folds(2).single.bounds, const Rect.fromLTWH(0, 455.5, 669, 40));
      expect(folds(3), isEmpty, reason: 'open flat');
      for (final index in [1, 2]) {
        expect(
          folds(index).single.state,
          DisplayFeatureState.postureHalfOpened,
        );
      }
      expect(
        screens.every(
          (s) => s.$2.any((f) => f.type == DisplayFeatureType.cutout),
        ),
        isTrue,
        reason: 'every pose has a status cluster',
      );
    },
  );

  group('Device.folding', () {
    test('takes its window from the first posture', () {
      final device = Device.folding(
        name: 'folding',
        postures: const [
          Device(name: 'a', devicePixelRatio: 3, width: 300, height: 600),
          Device(name: 'b', width: 400, height: 700),
        ],
      );

      expect(device.width, 300);
      expect(device.height, 600);
      expect(device.devicePixelRatio, 3);
      expect(device.postures, hasLength(2));
    });

    test('refuses a posture that has postures of its own', () {
      expect(
        () => Device.folding(name: 'nested', postures: [Device.iphoneDuo()]),
        throwsAssertionError,
      );
    });

    test('refuses postures that share a name', () {
      expect(
        () =>
            Device.folding(name: 'alike', postures: const [Device(), Device()]),
        throwsAssertionError,
      );
    });

    test('refuses no postures at all', () {
      expect(
        () => Device.folding(name: 'empty', postures: const []),
        throwsAssertionError,
      );
    });

    test('keeps its postures through copyWith, and guards the window', () {
      final duo = Device.iphoneDuo();

      expect(duo.copyWith(name: 'other').postures, duo.postures);
      expect(() => duo.copyWith(width: 500), throwsAssertionError);
    });
  });
}

class _Probe extends StatefulWidget {
  const _Probe({
    required this.onInit,
    required this.onTap,
    required this.onBuild,
  });

  final VoidCallback onInit;
  final VoidCallback onTap;
  final void Function(MediaQueryData media) onBuild;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) {
    widget.onBuild(MediaQuery.of(context));
    return TextButton(onPressed: widget.onTap, child: const Text('Tap'));
  }
}
