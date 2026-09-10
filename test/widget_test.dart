import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_count_app/main.dart';

void main() {
  testWidgets('App bootstraps without throwing', (tester) async {
    await tester.pumpWidget(const InventoryCountApp());
    await tester.pumpAndSettle();

    expect(find.byType(InventoryCountApp), findsOneWidget);
  });
}
