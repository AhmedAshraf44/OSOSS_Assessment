class FakeProductRecord {
  FakeProductRecord({
    required this.id,
    required this.name,
    required this.sku,
    required this.barcode,
    required this.systemQuantity,
    required this.version,
    required this.updatedAt,
    Map<int, int>? versionHistory,
  }) : versionHistory = versionHistory ?? {};

  final int id;
  final String name;
  final String sku;
  final String barcode;
  final int systemQuantity;
  final int version;
  final DateTime updatedAt;

  /// version -> systemQuantity at that version, recorded whenever a sale
  /// bumps the version, so a conflict response can still report the
  /// quantity the employee originally saw.
  final Map<int, int> versionHistory;

  int quantityAt(int knownVersion) =>
      versionHistory[knownVersion] ?? systemQuantity;

  /// A sale reducing stock by [quantityDelta] and bumping the version —
  /// the change that makes a submission conflict.
  FakeProductRecord afterSale(int quantityDelta) {
    versionHistory[version] = systemQuantity;
    return FakeProductRecord(
      id: id,
      name: name,
      sku: sku,
      barcode: barcode,
      systemQuantity: (systemQuantity + quantityDelta).clamp(0, 1 << 30),
      version: version + 1,
      updatedAt: DateTime.now(),
      versionHistory: versionHistory,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'barcode': barcode,
    'systemQuantity': systemQuantity,
    'version': version,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
