/// Pure quantity calculations shared by the product list and conflict
/// review screens. No Flutter, no IO — fully unit-testable in isolation.
class QuantityMath {
  const QuantityMath._();

  /// Difference between the physically counted quantity and the system
  /// quantity. Returns null when the product hasn't been counted yet, since
  /// "not counted" must never be treated the same as "counted 0".
  static int? difference({
    required int systemQuantity,
    required int? countedQuantity,
  }) {
    if (countedQuantity == null) return null;
    return countedQuantity - systemQuantity;
  }

  static bool isCounted(int? countedQuantity) => countedQuantity != null;

  static bool hasDiscrepancy({
    required int systemQuantity,
    required int? countedQuantity,
  }) {
    final diff = difference(
      systemQuantity: systemQuantity,
      countedQuantity: countedQuantity,
    );
    return diff != null && diff != 0;
  }
}
