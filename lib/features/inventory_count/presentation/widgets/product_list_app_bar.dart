import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_state.dart';

class ProductListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProductListAppBar({
    super.key,
    required this.title,
    required this.onSubmit,
    this.onOpenSessions,
  });

  final String title;
  final ValueChanged<ProductListReady> onSubmit;

  /// Null while viewing a historical session — the sessions list is where
  /// this screen was opened from.
  final VoidCallback? onOpenSessions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        if (onOpenSessions != null)
          IconButton(
            tooltip: 'Count sessions',
            onPressed: onOpenSessions,
            icon: const Icon(Icons.history_rounded),
          ),
        BlocSelector<ProductListCubit, ProductListState, ProductListReady?>(
          selector: (state) => state is ProductListReady ? state : null,
          builder: (context, readyState) {
            if (readyState == null) return const SizedBox.shrink();
            final canSubmit =
                readyState.sessionStatus == CountSessionStatus.draft &&
                readyState.progress.counted > 0;
            return IconButton(
              tooltip: 'Submit count',
              onPressed: canSubmit ? () => onSubmit(readyState) : null,
              icon: const Icon(Icons.cloud_upload_outlined),
            );
          },
        ),
      ],
    );
  }
}
