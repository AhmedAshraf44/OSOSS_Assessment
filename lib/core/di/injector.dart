import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import 'package:inventory_count_app/core/db/app_database.dart';
import 'package:inventory_count_app/core/network/connectivity_monitor.dart';
import 'package:inventory_count_app/core/utils/id_generator.dart';

final GetIt sl = GetIt.instance;

/// Registers every injectable dependency. Called once from `main()` before
/// `runApp`. Feature modules register through this same file — Cubits, use
/// cases, and repositories are always resolved via [sl], never instantiated
/// manually in widgets (CLAUDE.md: single core/di/ setup file).
Future<void> configureDependencies() async {
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<ConnectivityMonitor>(() => ConnectivityMonitor(sl()));

  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  sl.registerLazySingleton<IdGenerator>(() => const IdGenerator());
}
