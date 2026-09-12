import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inventory_count_app/core/di/injector.dart';
import 'package:inventory_count_app/core/fake_backend/fake_backend.dart';
import 'package:inventory_count_app/features/stores/presentation/cubit/store_cubit.dart';
import 'package:inventory_count_app/features/stores/presentation/screens/store_selection_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
    // No artificial network delay — this test only cares about the
    // interaction, not the simulated backend's latency.
    sl<FakeBackend>().latency = Duration.zero;
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget buildScreen() {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) => MaterialApp(
        home: BlocProvider(
          create: (_) => sl<StoreCubit>()..loadStores(),
          child: const StoreSelectionScreen(),
        ),
      ),
    );
  }

  group('Store selection — key user workflow', () {
    testWidgets(
      'lists the available stores and starts with none selected',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        expect(find.text('Cairo Store'), findsOneWidget);
        expect(find.text('Alexandria Store'), findsOneWidget);
        expect(find.text('Giza Store'), findsOneWidget);

        final continueButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Continue'),
        );
        expect(continueButton.onPressed, isNull);
      },
    );

    testWidgets(
      'tapping a store selects it and enables Continue',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Alexandria Store'));
        await tester.tap(find.text('Alexandria Store'));
        await tester.pumpAndSettle();

        // Selection is persisted through the cubit — reflected as a
        // checkmark on the tapped tile.
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

        final continueButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Continue'),
        );
        expect(continueButton.onPressed, isNotNull);
      },
    );

    testWidgets(
      'switching the selection moves the checkmark instead of adding a second one',
      (tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Cairo Store'));
        await tester.tap(find.text('Cairo Store'));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

        await tester.ensureVisible(find.text('Giza Store'));
        await tester.tap(find.text('Giza Store'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      },
    );
  });
}
