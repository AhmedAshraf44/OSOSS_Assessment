import 'package:flutter/material.dart';

import 'package:inventory_count_app/core/di/injector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const InventoryCountApp());
}

class InventoryCountApp extends StatelessWidget {
  const InventoryCountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Count',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const _BootstrapPlaceholder(),
    );
  }
}

// Temporary placeholder home screen. Replaced by the store-selection screen
// once the stores feature is built.
class _BootstrapPlaceholder extends StatelessWidget {
  const _BootstrapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Inventory Count App')),
    );
  }
}
