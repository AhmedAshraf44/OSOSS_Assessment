import 'dart:async';

/// Delays invoking [run]'s action until no new call has arrived for [delay],
/// collapsing rapid input (e.g. search-as-you-type over 20k products) into a
/// single action instead of one per keystroke.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 300)});

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
