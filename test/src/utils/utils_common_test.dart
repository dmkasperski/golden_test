import 'package:flutter_test/flutter_test.dart';
import 'package:golden_test/src/utils/utils_common.dart';

void main() {
  group('xnor - ', () {
    test('All true conditions returns true', () {
      expect(xnor([true, true, true]), isTrue);
    });

    test('All false conditions returns true', () {
      expect(xnor([false, false, false]), isTrue);
    });

    test('Mixed conditions (some true, some false) returns false', () {
      expect(xnor([true, false, true]), isFalse);
      expect(xnor([true, false, false]), isFalse);
    });

    test('Empty list returns true', () {
      expect(xnor([]), isTrue);
    });

    test('Single true condition returns true', () {
      expect(xnor([true]), isTrue);
    });

    test('Single false condition returns true', () {
      expect(xnor([false]), isTrue);
    });
  });
}
