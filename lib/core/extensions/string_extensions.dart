/// String utility extensions for sanitization and formatting
extension StringExtensions on String {
  /// Sanitize input — trim whitespace, remove control characters
  String get sanitized => trim().replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

  /// Capitalize first letter
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Title case (each word capitalized)
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  /// Extract initials from a name (max 2 characters)
  String get initials {
    final words = trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }

  /// Check if string is a valid URL
  bool get isValidUrl {
    return RegExp(
      r'^https?://[^\s/$.?#].[^\s]*$',
      caseSensitive: false,
    ).hasMatch(this);
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
    ).hasMatch(this);
  }

  /// Truncate with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - 3)}...';
  }

  /// Convert to URL-safe slug
  String get toSlug {
    return toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  /// Mask sensitive data (e.g., email)
  String get masked {
    if (contains('@')) {
      final parts = split('@');
      final name = parts[0];
      final domain = parts[1];
      final maskedName = name.length > 2
          ? '${name.substring(0, 2)}${'*' * (name.length - 2)}'
          : name;
      return '$maskedName@$domain';
    }
    if (length <= 4) return '****';
    return '${substring(0, 2)}${'*' * (length - 4)}${substring(length - 2)}';
  }
}

/// Nullable string extensions
extension NullableStringExtensions on String? {
  /// Returns true if null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns true if not null and not empty
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;
}
