import 'package:equatable/equatable.dart';

import 'package:inventory_count_app/features/inventory_count/domain/entities/count_progress.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';

/// A session paired with its counted-product progress — everything the
/// sessions screen needs to show one row without re-querying per card.
class CountSessionSummary extends Equatable {
  const CountSessionSummary({required this.session, required this.progress});

  final CountSession session;
  final CountProgress progress;

  @override
  List<Object?> get props => [session, progress];
}
