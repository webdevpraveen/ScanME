/// Typed exception hierarchy for SeeMe
/// All app exceptions extend [AppException] for centralized handling
sealed class AppException implements Exception {
  const AppException(this.message, [this.originalError]);

  final String message;
  final Object? originalError;

  @override
  String toString() => '$runtimeType: $message';
}

// ─── Auth Exceptions ─────────────────────────────────────────
class AuthException extends AppException {
  const AuthException(super.message, [super.originalError]);
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
      : super('Invalid email or password');
}

class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException()
      : super('An account with this email already exists');
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException()
      : super('Password is too weak. Use at least 8 characters');
}

class SessionExpiredException extends AuthException {
  const SessionExpiredException()
      : super('Your session has expired. Please log in again');
}

class AccountSoftDeletedException extends AuthException {
  const AccountSoftDeletedException()
      : super('Your account is scheduled for deletion');
}

// ─── Network Exceptions ──────────────────────────────────────
class NetworkException extends AppException {
  const NetworkException(super.message, [super.originalError]);
}

class NoInternetException extends NetworkException {
  const NoInternetException()
      : super('No internet connection. Please check your network');
}

class TimeoutException extends NetworkException {
  const TimeoutException()
      : super('Request timed out. Please try again');
}

class ServerException extends NetworkException {
  const ServerException([String? message])
      : super(message ?? 'Server error. Please try again later');
}

// ─── Database Exceptions ─────────────────────────────────────
class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.originalError]);
}

class RecordNotFoundException extends DatabaseException {
  const RecordNotFoundException([String? entity])
      : super('${entity ?? 'Record'} not found');
}

class DuplicateRecordException extends DatabaseException {
  const DuplicateRecordException([String? field])
      : super('${field ?? 'Record'} already exists');
}

class ForeignKeyViolationException extends DatabaseException {
  const ForeignKeyViolationException()
      : super('Related record not found');
}

// ─── Storage Exceptions ──────────────────────────────────────
class StorageException extends AppException {
  const StorageException(super.message, [super.originalError]);
}

class FileUploadException extends StorageException {
  const FileUploadException([String? message])
      : super(message ?? 'Failed to upload file');
}

class FileTooLargeException extends StorageException {
  const FileTooLargeException(int maxSizeMb)
      : super('File exceeds maximum size of ${maxSizeMb}MB');
}

class InvalidFileTypeException extends StorageException {
  const InvalidFileTypeException()
      : super('File type not supported. Use JPG, PNG, or WebP');
}

// ─── Validation Exceptions ───────────────────────────────────
class ValidationException extends AppException {
  const ValidationException(super.message, [super.originalError]);
}

// ─── Rate Limit Exceptions ───────────────────────────────────
class RateLimitException extends AppException {
  const RateLimitException([String? action])
      : super('Too many ${action ?? 'requests'}. Please wait before trying again');
}

// ─── Permission Exceptions ───────────────────────────────────
class PermissionDeniedException extends AppException {
  const PermissionDeniedException([String? permission])
      : super('${permission ?? 'Permission'} is required for this feature');
}

// ─── Verification Exceptions ─────────────────────────────────
class VerificationPendingException extends AppException {
  const VerificationPendingException()
      : super('Your verification is under review');
}

class VerificationRejectedException extends AppException {
  const VerificationRejectedException([String? reason])
      : super(reason ?? 'Your verification was not approved');
}

// ─── QR Exceptions ───────────────────────────────────────────
class QrResolutionException extends AppException {
  const QrResolutionException(super.message, [super.originalError]);
}

class InvalidQrCodeException extends QrResolutionException {
  const InvalidQrCodeException()
      : super('This QR code is not recognized');
}

class ProfileNotFoundException extends QrResolutionException {
  const ProfileNotFoundException()
      : super('No student profile found for this QR code');
}

// ─── Unknown ─────────────────────────────────────────────────
class UnknownException extends AppException {
  const UnknownException([Object? originalError])
      : super('Something went wrong. Please try again', originalError);
}
