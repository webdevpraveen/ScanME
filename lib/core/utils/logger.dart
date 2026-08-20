import 'package:flutter/foundation.dart';

/// Structured logger for SeeMe
/// Logs technical details separately from user-facing messages
class AppLogger {
  AppLogger._();

  static const String _tag = 'SeeMe';

  static void debug(String message, [String? module]) {
    if (kDebugMode) {
      debugPrint('[$_tag${module != null ? ':$module' : ''}] $message');
    }
  }

  static void info(String message, [String? module]) {
    debugPrint('ℹ️ [$_tag${module != null ? ':$module' : ''}] $message');
  }

  static void warning(String message, [String? module]) {
    debugPrint('⚠️ [$_tag${module != null ? ':$module' : ''}] $message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace, String? module]) {
    debugPrint('❌ [$_tag${module != null ? ':$module' : ''}] $message');
    if (error != null) {
      debugPrint('   Error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('   Stack: ${stackTrace.toString().split('\n').take(5).join('\n          ')}');
    }
  }

  static void network(String method, String path, [int? statusCode]) {
    if (kDebugMode) {
      final status = statusCode != null ? ' → $statusCode' : '';
      debugPrint('🌐 [$_tag:Network] $method $path$status');
    }
  }

  static void auth(String event) {
    debugPrint('🔐 [$_tag:Auth] $event');
  }

  static void navigation(String route) {
    if (kDebugMode) {
      debugPrint('🧭 [$_tag:Nav] $route');
    }
  }
}
