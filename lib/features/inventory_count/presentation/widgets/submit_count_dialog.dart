import 'package:flutter/material.dart';

import 'package:inventory_count_app/core/extensions/navigation_x.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_progress.dart';

class SubmitCountDialog extends StatelessWidget {
  const SubmitCountDialog({super.key, required this.progress});

  final CountProgress progress;

  /// Returns true only when the employee confirms.
  static Future<bool> show(BuildContext context, CountProgress progress) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => SubmitCountDialog(progress: progress),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Submit count?'),
      content: Text(
        '${progress.counted} of ${progress.total} products counted. The '
        'session will be queued for synchronization once you submit.',
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => context.pop(true),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
