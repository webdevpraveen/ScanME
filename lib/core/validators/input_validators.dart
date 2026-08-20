import '../constants/app_constants.dart';

/// Input validation functions for forms
/// Returns null if valid, error message string if invalid
class InputValidators {
  InputValidators._();

  // ─── Email ─────────────────────────────────────────────────
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final trimmed = value.trim();
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // ─── Password ──────────────────────────────────────────────
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < AppConstants.passwordMinLength) {
      return 'Password must be at least ${AppConstants.passwordMinLength} characters';
    }
    if (value.length > AppConstants.passwordMaxLength) {
      return 'Password must be less than ${AppConstants.passwordMaxLength} characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain an uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain a lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ─── Full Name ─────────────────────────────────────────────
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (trimmed.length > AppConstants.nameMaxLength) {
      return 'Name must be less than ${AppConstants.nameMaxLength} characters';
    }
    if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(trimmed)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    return null;
  }

  // ─── Roll Number ───────────────────────────────────────────
  static final _rollNumberRegex = RegExp(r'^[0-9]{15}$');

  static String? rollNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Roll number is required';
    }
    final trimmed = value.trim();
    if (trimmed.length != AppConstants.rollNumberLength) {
      return 'Roll number must be exactly ${AppConstants.rollNumberLength} digits';
    }
    if (!_rollNumberRegex.hasMatch(trimmed)) {
      return 'Roll number must contain only numbers';
    }
    return null;
  }

  // ─── Department ────────────────────────────────────────────
  static String? department(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Department is required';
    }
    return null;
  }

  // ─── Bio ───────────────────────────────────────────────────
  static String? bio(String? value) {
    if (value != null && value.length > AppConstants.bioMaxLength) {
      return 'Bio must be less than ${AppConstants.bioMaxLength} characters';
    }
    return null;
  }

  // ─── URL ───────────────────────────────────────────────────
  static final _urlRegex = RegExp(
    r'^https?://[^\s/$.?#].[^\s]*$',
    caseSensitive: false,
  );

  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final trimmed = value.trim();
    if (!_urlRegex.hasMatch(trimmed)) {
      return 'Enter a valid URL (starting with http:// or https://)';
    }
    return null;
  }

  // ─── Phone Number ──────────────────────────────────────────
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final trimmed = value.trim().replaceAll(RegExp(r'[\s-()]'), '');
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(trimmed)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  // ─── Required ──────────────────────────────────────────────
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
