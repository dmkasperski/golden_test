import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class LocalFileComparatorWithTolerance extends LocalFileComparator {
  LocalFileComparatorWithTolerance(super.testFile, this.diffTolerance)
      : assert(diffTolerance >= 0 && diffTolerance <= 100, '[diffTolerance] must be within range from 0-100(%)');

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
      debugPrint(
        '''
        Difference: ${result.diffPercent * 100}%, 
        Acceptable tolerance: ${diffTolerance}%
        ''',
      );

      return true;
    }

    if (!result.passed) {
      final error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    return result.passed;
  }
}
