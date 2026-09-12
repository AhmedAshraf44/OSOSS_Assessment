import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_count_app/core/utils/quantity_math.dart';

void main() {
  group('QuantityMath.difference', () {
    test('returns null when the product has not been counted yet', () {
      expect(
        QuantityMath.difference(systemQuantity: 20, countedQuantity: null),
        isNull,
      );
    });

    test('returns 0 when the counted quantity matches the system quantity', () {
      expect(
        QuantityMath.difference(systemQuantity: 20, countedQuantity: 20),
        0,
      );
    });

    test('is negative when the physical count is lower than the system qty', () {
      expect(
        QuantityMath.difference(systemQuantity: 20, countedQuantity: 18),
        -2,
      );
    });

    test('is positive when the physical count is higher than the system qty', () {
      expect(
        QuantityMath.difference(systemQuantity: 20, countedQuantity: 25),
        5,
      );
    });

    test('treats a physical count of zero as a real, non-null difference', () {
      // A count of 0 is a real observation ("shelf is empty"), distinct
      // from "not counted yet" (null) — this is the whole point of the
      // nullable countedQuantity design.
      expect(
        QuantityMath.difference(systemQuantity: 5, countedQuantity: 0),
        -5,
      );
    });
  });

  group('QuantityMath.isCounted', () {
    test('false for null (not counted)', () {
      expect(QuantityMath.isCounted(null), isFalse);
    });

    test('true for a physical count of zero', () {
      expect(QuantityMath.isCounted(0), isTrue);
    });

    test('true for any positive count', () {
      expect(QuantityMath.isCounted(12), isTrue);
    });
  });

  group('QuantityMath.hasDiscrepancy', () {
    test('false when not counted yet', () {
      expect(
        QuantityMath.hasDiscrepancy(systemQuantity: 20, countedQuantity: null),
        isFalse,
      );
    });

    test('false when the count matches the system quantity exactly', () {
      expect(
        QuantityMath.hasDiscrepancy(systemQuantity: 20, countedQuantity: 20),
        isFalse,
      );
    });

    test('true when the count differs from the system quantity', () {
      expect(
        QuantityMath.hasDiscrepancy(systemQuantity: 20, countedQuantity: 18),
        isTrue,
      );
    });
  });
}
