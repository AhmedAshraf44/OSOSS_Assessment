import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/di/injector.dart';
import 'package:inventory_count_app/core/network/connectivity_monitor.dart';
import 'package:inventory_count_app/core/theme/app_theme.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/recover_interrupted_syncs.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/sync_pending_sessions.dart';
import 'package:inventory_count_app/features/stores/presentation/cubit/store_cubit.dart';
import 'package:inventory_count_app/features/stores/presentation/screens/store_selection_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  await sl<RecoverInterruptedSyncs>()();

  sl<ConnectivityMonitor>().onStatusChange.listen((isOnline) {
    if (isOnline) sl<SyncPendingSessions>()();
  });

  runApp(const InventoryCountApp());
}

class InventoryCountApp extends StatelessWidget {
  const InventoryCountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Inventory Count',
          theme: AppTheme.light,
          home: BlocProvider(
            create: (_) => sl<StoreCubit>()..loadStores(),
            child: const StoreSelectionScreen(),
          ),
        );
      },
    );
  }
}
