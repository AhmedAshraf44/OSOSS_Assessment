import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inventory_count_app/core/di/injector.dart';
import 'package:inventory_count_app/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('App bootstraps and shows the store selection screen', (
    tester,
  ) async {
    await tester.pumpWidget(const InventoryCountApp());
    await tester.pumpAndSettle();

    expect(find.text('Select Store'), findsOneWidget);
  });
}
