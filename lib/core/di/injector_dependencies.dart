/// Everything [configureDependencies] needs to construct, re-exported from
/// one place so `injector.dart` stays a readable list of registrations
/// instead of opening with fifty import lines.
library;

export 'package:connectivity_plus/connectivity_plus.dart';
export 'package:get_it/get_it.dart';
export 'package:shared_preferences/shared_preferences.dart';

export 'package:inventory_count_app/core/db/app_database.dart';
export 'package:inventory_count_app/core/fake_backend/fake_backend.dart';
export 'package:inventory_count_app/core/network/connectivity_monitor.dart';
export 'package:inventory_count_app/core/utils/id_generator.dart';

export 'package:inventory_count_app/features/inventory_count/data/datasources/count_session_local_data_source.dart';
export 'package:inventory_count_app/features/inventory_count/data/datasources/fake_product_remote_data_source.dart';
export 'package:inventory_count_app/features/inventory_count/data/datasources/fake_session_remote_data_source.dart';
export 'package:inventory_count_app/features/inventory_count/data/datasources/product_local_data_source.dart';
export 'package:inventory_count_app/features/inventory_count/data/datasources/product_remote_data_source.dart';
export 'package:inventory_count_app/features/inventory_count/data/datasources/session_remote_data_source.dart';
export 'package:inventory_count_app/features/inventory_count/data/datasources/sqflite_count_session_local_data_source.dart';
export 'package:inventory_count_app/features/inventory_count/data/datasources/sqflite_product_local_data_source.dart';
export 'package:inventory_count_app/features/inventory_count/data/repositories/count_session_repository_impl.dart';
export 'package:inventory_count_app/features/inventory_count/data/repositories/product_repository_impl.dart';
export 'package:inventory_count_app/features/inventory_count/data/repositories/submission_repository_impl.dart';
export 'package:inventory_count_app/features/inventory_count/domain/repositories/count_session_repository.dart';
export 'package:inventory_count_app/features/inventory_count/domain/repositories/product_repository.dart';
export 'package:inventory_count_app/features/inventory_count/domain/repositories/submission_repository.dart';
export 'package:inventory_count_app/features/inventory_count/domain/services/sync_engine.dart';
export 'package:inventory_count_app/features/inventory_count/domain/usecases/cancel_conflict_resolution.dart';
export 'package:inventory_count_app/features/inventory_count/domain/usecases/get_conflict_review_items.dart';
export 'package:inventory_count_app/features/inventory_count/domain/usecases/get_local_product_page.dart';
export 'package:inventory_count_app/features/inventory_count/domain/usecases/get_or_create_active_session.dart';
export 'package:inventory_count_app/features/inventory_count/domain/usecases/get_session_progress.dart';
export 'package:inventory_count_app/features/inventory_count/domain/usecases/get_store_sessions.dart';
export 'package:inventory_count_app/features/inventory_count/domain/usecases/has_unsubmitted_count.dart';
export 'package:inventory_count_app/features/inventory_count/domain/usecases/recover_interrupted_syncs.dart';
export 'package:inventory_count_app/features/inventory_count/domain/usecases/resolve_conflicts.dart';
export 'package:inventory_count_app/features/inventory_count/domain/usecases/save_counted_quantity.dart';
export 'package:inventory_count_app/features/inventory_count/domain/usecases/submit_session.dart';
export 'package:inventory_count_app/features/inventory_count/domain/usecases/sync_pending_sessions.dart';
export 'package:inventory_count_app/features/inventory_count/domain/usecases/sync_products_from_server.dart';
export 'package:inventory_count_app/features/inventory_count/domain/usecases/watch_session_updates.dart';
export 'package:inventory_count_app/features/inventory_count/presentation/cubit/conflict_review/conflict_review_cubit.dart';
export 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_cubit.dart';
export 'package:inventory_count_app/features/inventory_count/presentation/cubit/sessions/sessions_cubit.dart';

export 'package:inventory_count_app/features/stores/data/datasources/fake_store_remote_data_source.dart';
export 'package:inventory_count_app/features/stores/data/datasources/store_local_data_source.dart';
export 'package:inventory_count_app/features/stores/data/datasources/store_remote_data_source.dart';
export 'package:inventory_count_app/features/stores/data/repositories/store_repository_impl.dart';
export 'package:inventory_count_app/features/stores/domain/repositories/store_repository.dart';
export 'package:inventory_count_app/features/stores/domain/usecases/get_selected_store_id.dart';
export 'package:inventory_count_app/features/stores/domain/usecases/get_stores.dart';
export 'package:inventory_count_app/features/stores/domain/usecases/select_store.dart';
export 'package:inventory_count_app/features/stores/presentation/cubit/store_cubit.dart';
