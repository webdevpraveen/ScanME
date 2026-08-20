import 'dart:async';

/// Debounce utility for search, username checks, etc.
class Debouncer {
  Debouncer({required this.duration});

  final Duration duration;
  Timer? _timer;

  /// Run [action] after the debounce duration.
  /// Cancels any previously scheduled action.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancel any pending debounced action
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Whether a debounced action is pending
  bool get isPending => _timer?.isActive ?? false;

  /// Dispose the debouncer
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
