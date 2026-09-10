import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/screens/product_list_screen.dart';
import 'package:inventory_count_app/features/stores/domain/entities/store.dart';
import 'package:inventory_count_app/features/stores/presentation/cubit/store_cubit.dart';
import 'package:inventory_count_app/features/stores/presentation/cubit/store_state.dart';
import 'package:inventory_count_app/features/stores/presentation/widgets/store_tile.dart';
import 'package:inventory_count_app/core/di/injector.dart';

class StoreListView extends StatelessWidget {
  const StoreListView({super.key, required this.stores});

  final List<Store> stores;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            itemCount: stores.length,
            itemBuilder: (context, index) => StoreTile(store: stores[index]),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
            child: BlocSelector<StoreCubit, StoreState, int?>(
              selector: (state) =>
                  state is StoreLoaded ? state.selectedStoreId : null,
              builder: (context, selectedStoreId) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedStoreId == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => BlocProvider(
                                create: (_) => sl<ProductListCubit>(),
                                child: ProductListScreen(
                                  store: stores.firstWhere(
                                    (s) => s.id == selectedStoreId,
                                  ),
                                ),
                              ),
                            ),
                          ),
                    child: const Text('Continue'),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
