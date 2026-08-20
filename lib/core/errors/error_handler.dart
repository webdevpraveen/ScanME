import 'package:flutter/material.dart';
import 'app_exception.dart';

/// Centralized error handler — maps exceptions to user-friendly messages
/// and provides appropriate UI actions.
class ErrorHandler {
  ErrorHandler._();

  /// Convert any error to an [AppException]
  static AppException handle(Object error, [StackTrace? stackTrace]) {
    // Log technical details
    debugPrint('┌─── ERROR ───────────────────────────────────');
    debugPrint('│ Type: ${error.runtimeType}');
    debugPrint('│ Message: $error');
    if (stackTrace != null) {
      debugPrint('│ Stack: ${stackTrace.toString().split('\n').take(5).join('\n│        ')}');
    }
    debugPrint('└─────────────────────────────────────────────');

    if (error is AppException) return error;

    // Map Supabase/PostgrestException errors
    final errorStr = error.toString().toLowerCase();

    // Auth errors
    if (errorStr.contains('invalid login credentials') ||
        errorStr.contains('invalid_credentials')) {
      return const InvalidCredentialsException();
    }
    if (errorStr.contains('user already registered') ||
        errorStr.contains('email_exists')) {
      return const EmailAlreadyInUseException();
    }
    if (errorStr.contains('weak_password') ||
        errorStr.contains('password should be')) {
      return const WeakPasswordException();
    }
    if (errorStr.contains('refresh_token_not_found') ||
        errorStr.contains('session_expired') ||
        errorStr.contains('jwt expired')) {
      return const SessionExpiredException();
    }

    // Database errors
    if (errorStr.contains('pgrst116') || errorStr.contains('not found')) {
      return const RecordNotFoundException();
    }
    if (errorStr.contains('23505') || errorStr.contains('duplicate key') ||
        errorStr.contains('already exists')) {
      return const DuplicateRecordException();
    }
    if (errorStr.contains('23503') || errorStr.contains('foreign key')) {
      return const ForeignKeyViolationException();
    }

    // Network errors
    if (errorStr.contains('socketexception') ||
        errorStr.contains('no internet') ||
        errorStr.contains('network_error') ||
        errorStr.contains('failed host lookup')) {
      return const NoInternetException();
    }
    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return const TimeoutException();
    }

    // Rate limiting
    if (errorStr.contains('rate_limit') || errorStr.contains('429') ||
        errorStr.contains('too many requests')) {
      return const RateLimitException();
    }

    return UnknownException(error);
  }

  /// Get user-friendly message from exception
  static String getUserMessage(AppException exception) => exception.message;

  /// Get icon for error type
  static IconData getErrorIcon(AppException exception) {
    return switch (exception) {
      AuthException() => Icons.lock_outline_rounded,
      NetworkException() => Icons.wifi_off_rounded,
      DatabaseException() => Icons.storage_rounded,
      StorageException() => Icons.cloud_off_rounded,
      ValidationException() => Icons.warning_amber_rounded,
      RateLimitException() => Icons.speed_rounded,
      PermissionDeniedException() => Icons.block_rounded,
      VerificationPendingException() => Icons.hourglass_empty_rounded,
      VerificationRejectedException() => Icons.cancel_outlined,
      QrResolutionException() => Icons.qr_code_scanner_rounded,
      UnknownException() => Icons.error_outline_rounded,
    };
  }

  /// Whether this error should offer a retry action
  static bool isRetryable(AppException exception) {
    return switch (exception) {
      NetworkException() => true,
      RateLimitException() => true,
      _ => false,
    };
  }

  /// Show error as a snackbar
  static void showSnackBar(BuildContext context, Object error) {
    final exception = error is AppException ? error : handle(error);
    final message = getUserMessage(exception);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                getErrorIcon(exception),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: exception is NetworkException
              ? Colors.orange.shade700
              : Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
  }
}
