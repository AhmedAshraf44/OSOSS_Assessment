import 'package:flutter/material.dart';

import 'package:inventory_count_app/core/extensions/navigation_x.dart';

/// Warns before switching to another store while the current one still has
/// a count that has not reached the server.
class SwitchStoreDialog extends StatelessWidget {
  const SwitchStoreDialog({super.key, required this.targetStoreName});

  final String targetStoreName;

  /// Returns true only when the employee confirms the switch.
  static Future<bool> show(BuildContext context, String targetStoreName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => SwitchStoreDialog(targetStoreName: targetStoreName),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Switch store?'),
      content: Text(
        'The current store still has a count that has not been synchronized '
        'yet. Nothing will be lost — it stays saved on this device and you '
        'can come back to finish or submit it. Switch to $targetStoreName?',
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: const Text('Stay'),
        ),
        ElevatedButton(
          onPressed: () => context.pop(true),
          child: const Text('Switch'),
        ),
      ],
    );
  }
}
