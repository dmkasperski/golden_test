import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Replaces [goldenFileComparator] with a [LocalFileComparatorWithTolerance]
/// for the same test directory, so failure images land in a `failures/` folder
/// next to each golden file rather than one folder next to the test file.
///
/// Does nothing when the comparator is not file based, e.g. on the web.
void installGoldenTestComparator(double diffTolerance) {
  final GoldenFileComparator comparator = goldenFileComparator;
  if (comparator is LocalFileComparator) {
    goldenFileComparator = LocalFileComparatorWithTolerance(
      Uri.parse('${comparator.basedir}/test.dart'),
      diffTolerance,
    );
  }
}

class LocalFileComparatorWithTolerance extends LocalFileComparator {
  LocalFileComparatorWithTolerance(super.testFile, this.diffTolerance)
    : assert(
        diffTolerance >= 0 && diffTolerance <= 100,
        '[diffTolerance] must be within range from 0-100(%)',
      );

  /// Tolerance above which tests will be marked as Failed.
  /// Ranges from (0-1), both inclusive.
  final double diffTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (!result.passed && result.diffPercent * 100 <= diffTolerance) {
      debugPrint('''
        Difference: ${result.diffPercent * 100}%, 
        Acceptable tolerance: $diffTolerance%
        ''');

      return true;
    }

    if (!result.passed) {
      final Uri goldenPathWithoutFile = golden.replace(
        pathSegments: golden.pathSegments.sublist(
          0,
          golden.pathSegments.length - 1,
        ),
      );

      final Uri updatedBasedir = basedir.resolve(
        goldenPathWithoutFile.toString(),
      );

      final error = await generateFailureOutput(result, golden, updatedBasedir);
      throw FlutterError(error);
    }
    return result.passed;
  }
}
