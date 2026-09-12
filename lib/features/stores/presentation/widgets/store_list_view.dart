import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/di/injector.dart';
import 'package:inventory_count_app/core/extensions/navigation_x.dart';
import 'package:inventory_count_app/core/theme/app_colors.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/screens/product_list_screen.dart';
import 'package:inventory_count_app/features/stores/domain/entities/store.dart';
import 'package:inventory_count_app/features/stores/presentation/cubit/store_cubit.dart';
import 'package:inventory_count_app/features/stores/presentation/cubit/store_state.dart';
import 'package:inventory_count_app/features/stores/presentation/widgets/store_list_header.dart';
import 'package:inventory_count_app/features/stores/presentation/widgets/store_tile.dart';

class StoreListView extends StatelessWidget {
  const StoreListView({super.key, required this.stores});

  final List<Store> stores;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StoreListHeader(storeCount: stores.length),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(top: 8.h, bottom: 12.h),
            itemCount: stores.length,
            itemBuilder: (context, index) => StoreTile(store: stores[index]),
          ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
              child: BlocSelector<StoreCubit, StoreState, int?>(
                selector: (state) =>
                    state is StoreLoaded ? state.selectedStoreId : null,
                builder: (context, selectedStoreId) {
                  return SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton.icon(
                      onPressed: selectedStoreId == null
                          ? null
                          : () => context.pushScreen<void>(
                              BlocProvider(
                                create: (_) => sl<ProductListCubit>(),
                                child: ProductListScreen(
                                  store: stores.firstWhere(
                                    (s) => s.id == selectedStoreId,
                                  ),
                                ),
                              ),
                            ),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Continue'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
