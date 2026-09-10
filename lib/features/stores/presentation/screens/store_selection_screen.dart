import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:inventory_count_app/core/utils/widgets/empty_state_view.dart';
import 'package:inventory_count_app/core/utils/widgets/error_state_view.dart';
import 'package:inventory_count_app/features/stores/presentation/cubit/store_cubit.dart';
import 'package:inventory_count_app/features/stores/presentation/cubit/store_state.dart';
import 'package:inventory_count_app/features/stores/presentation/widgets/store_list_view.dart';

class StoreSelectionScreen extends StatelessWidget {
  const StoreSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Store')),
      body: BlocBuilder<StoreCubit, StoreState>(
        builder: (context, state) {
          return switch (state) {
            StoreInitial() ||
            StoreLoading() => const Center(child: CircularProgressIndicator()),
            StoreError(:final failure) => ErrorStateView(
              message: failure.message,
              onRetry: () => context.read<StoreCubit>().loadStores(),
            ),
            StoreLoaded(:final stores) when stores.isEmpty =>
              const EmptyStateView(
                icon: Icons.storefront_outlined,
                message: 'No stores are available for your account.',
              ),
            StoreLoaded(:final stores) => StoreListView(stores: stores),
          };
        },
      ),
    );
  }
}
