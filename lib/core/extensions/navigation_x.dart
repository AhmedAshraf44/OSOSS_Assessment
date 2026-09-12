import 'package:flutter/material.dart';

/// Navigation shorthands, so screens read `context.pushScreen(page)` instead
/// of spelling out `Navigator.of(context).push(MaterialPageRoute(...))`
/// every time.
extension NavigationX on BuildContext {
  /// Capture this *before* an `await` when you intend to pop afterwards —
  /// the context itself may be gone by then. Pair it with
  /// [NavigatorStateX.popIfMounted].
  NavigatorState get navigator => Navigator.of(this);

  /// Pushes [page] and returns whatever it pops with.
  Future<T?> pushScreen<T>(Widget page) {
    return Navigator.of(this).push<T>(
      MaterialPageRoute<T>(builder: (_) => page),
    );
  }

  void pop<T>([T? result]) => Navigator.of(this).pop<T>(result);
}

extension NavigatorStateX on NavigatorState {
  /// Pops only if this navigator is still mounted — the safe form after an
  /// `await`, where the screen may already have been closed.
  void popIfMounted<T>([T? result]) {
    if (mounted) pop<T>(result);
  }
}
