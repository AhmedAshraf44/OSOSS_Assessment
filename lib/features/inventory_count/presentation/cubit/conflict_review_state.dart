import 'package:equatable/equatable.dart';

import 'package:inventory_count_app/core/error/failures.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/conflict_resolution.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/conflict_review_item.dart';

sealed class ConflictReviewState extends Equatable {
  const ConflictReviewState();

  @override
  List<Object?> get props => [];
}

final class ConflictReviewLoading extends ConflictReviewState {
  const ConflictReviewLoading();
}

final class ConflictReviewError extends ConflictReviewState {
  const ConflictReviewError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class ConflictReviewLoaded extends ConflictReviewState {
  const ConflictReviewLoaded({
    required this.items,
    required this.resolutions,
    this.isSubmitting = false,
  });

  final List<ConflictReviewItem> items;

  /// productId -> the employee's choice for that conflict. Defaults to
  /// [ConflictResolution.keepMine] for every item when first loaded.
  final Map<int, ConflictResolution> resolutions;

  final bool isSubmitting;

  ConflictReviewLoaded copyWith({
    Map<int, ConflictResolution>? resolutions,
    bool? isSubmitting,
  }) {
    return ConflictReviewLoaded(
      items: items,
      resolutions: resolutions ?? this.resolutions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [items, resolutions, isSubmitting];
}
