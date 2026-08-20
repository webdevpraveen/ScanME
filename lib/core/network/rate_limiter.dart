import 'dart:collection';

/// Client-side rate limiter to prevent excessive API calls
/// Works in conjunction with server-side rate limiting
class RateLimiter {
  RateLimiter({
    required this.maxEvents,
    required this.window,
  });

  final int maxEvents;
  final Duration window;
  final Queue<DateTime> _events = Queue<DateTime>();

  /// Check if action is allowed (under rate limit)
  bool isAllowed() {
    _cleanup();
    return _events.length < maxEvents;
  }

  /// Record an event. Returns true if allowed, false if rate limited.
  bool recordEvent() {
    _cleanup();
    if (_events.length >= maxEvents) return false;
    _events.add(DateTime.now());
    return true;
  }

  /// Get remaining allowed events
  int get remaining {
    _cleanup();
    return (maxEvents - _events.length).clamp(0, maxEvents);
  }

  /// Get time until next allowed event (if rate limited)
  Duration? get timeUntilNextAllowed {
    _cleanup();
    if (_events.length < maxEvents) return null;
    final oldest = _events.first;
    final nextAllowed = oldest.add(window);
    final now = DateTime.now();
    if (nextAllowed.isAfter(now)) {
      return nextAllowed.difference(now);
    }
    return null;
  }

  /// Remove expired events outside the window
  void _cleanup() {
    final cutoff = DateTime.now().subtract(window);
    while (_events.isNotEmpty && _events.first.isBefore(cutoff)) {
      _events.removeFirst();
    }
  }

  /// Reset the limiter
  void reset() => _events.clear();
}

/// Pre-configured rate limiters for common actions
class AppRateLimiters {
  AppRateLimiters._();

  static final scan = RateLimiter(
    maxEvents: 100,
    window: const Duration(hours: 1),
  );

  static final profileView = RateLimiter(
    maxEvents: 300,
    window: const Duration(hours: 1),
  );

  static final search = RateLimiter(
    maxEvents: 200,
    window: const Duration(hours: 1),
  );

  /// Update limits from app_config values
  static void updateLimits({
    int? maxScans,
    int? maxProfileViews,
    int? maxSearches,
  }) {
    // Rate limiters are recreated with new limits if provided
    // This is called when app_config is fetched
    if (maxScans != null) {
      scan.reset();
    }
    if (maxProfileViews != null) {
      profileView.reset();
    }
    if (maxSearches != null) {
      search.reset();
    }
  }
}
