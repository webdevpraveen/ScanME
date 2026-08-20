import '../../../core/utils/logger.dart';

/// Resolved identity from a QR code
class ResolvedIdentity {
  const ResolvedIdentity({
    required this.type,
    required this.identifier,
  });

  /// Type of identifier resolved
  final ResolvedIdentityType type;

  /// The resolved identifier value (UUID, roll number, etc.)
  final String identifier;
}

enum ResolvedIdentityType {
  seemeQrId,     // Internal SeeMe QR UUID
  rollNumber,    // Roll number from URL or raw QR
  userId,        // Direct user UUID
}

/// Base class for QR resolvers — each handles one QR format
abstract class QrResolverBase {
  /// Whether this resolver can handle the given QR content
  bool canResolve(String qrContent);

  /// Resolve QR content to a student identifier
  Future<ResolvedIdentity?> resolve(String qrContent);

  /// Priority (lower = tried first)
  int get priority => 100;
}

/// SeeMe internal QR resolver (seeme://uuid)
class SeemeIdResolver extends QrResolverBase {
  @override
  bool canResolve(String qrContent) {
    return qrContent.startsWith('seeme://');
  }

  @override
  Future<ResolvedIdentity?> resolve(String qrContent) async {
    final id = qrContent.replaceFirst('seeme://', '').trim();
    if (id.isEmpty) return null;

    AppLogger.debug('Resolved SeeMe QR ID: $id', 'QrResolver');
    return ResolvedIdentity(
      type: ResolvedIdentityType.seemeQrId,
      identifier: id,
    );
  }

  @override
  int get priority => 1;
}

/// URL resolver (https://seeme.app/u/rollNumber)
class UrlResolver extends QrResolverBase {
  @override
  bool canResolve(String qrContent) {
    return qrContent.startsWith('https://seeme.app/u/') ||
        qrContent.startsWith('http://seeme.app/u/');
  }

  @override
  Future<ResolvedIdentity?> resolve(String qrContent) async {
    final uri = Uri.tryParse(qrContent);
    if (uri == null || uri.pathSegments.length < 2) return null;

    final rollNumber = uri.pathSegments[1].trim();
    if (rollNumber.isEmpty) return null;

    AppLogger.debug('Resolved URL roll number: $rollNumber', 'QrResolver');
    return ResolvedIdentity(
      type: ResolvedIdentityType.rollNumber,
      identifier: rollNumber,
    );
  }

  @override
  int get priority => 2;
}

/// Roll number resolver (raw 15-digit numeric QR)
class RollNumberResolver extends QrResolverBase {
  @override
  bool canResolve(String qrContent) {
    // Matches 15-digit SRMU roll numbers
    return RegExp(r'^[0-9]{15}$').hasMatch(qrContent.trim());
  }

  @override
  Future<ResolvedIdentity?> resolve(String qrContent) async {
    final rollNumber = qrContent.trim();

    AppLogger.debug('Resolved roll number: $rollNumber', 'QrResolver');
    return ResolvedIdentity(
      type: ResolvedIdentityType.rollNumber,
      identifier: rollNumber,
    );
  }

  @override
  int get priority => 50; // Lower priority — tried after more specific resolvers
}

/// Encoded QR resolver (base64 payloads)
class EncodedResolver extends QrResolverBase {
  @override
  bool canResolve(String qrContent) {
    // Check if it looks like base64
    return RegExp(r'^[A-Za-z0-9+/=]{16,}$').hasMatch(qrContent.trim());
  }

  @override
  Future<ResolvedIdentity?> resolve(String qrContent) async {
    try {
      // Attempt base64 decode and re-resolve
      // For now, return null — can be extended later
      AppLogger.debug('Encoded QR detected, skipping for now', 'QrResolver');
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  int get priority => 90;
}

/// QR Resolver Registry — manages and dispatches to resolvers
class QrResolverRegistry {
  QrResolverRegistry() {
    // Register default resolvers in priority order
    register(SeemeIdResolver());
    register(UrlResolver());
    register(RollNumberResolver());
    register(EncodedResolver());
  }

  final List<QrResolverBase> _resolvers = [];

  /// Register a new resolver
  void register(QrResolverBase resolver) {
    _resolvers.add(resolver);
    _resolvers.sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// Resolve QR content using the first matching resolver
  Future<ResolvedIdentity?> resolve(String qrContent) async {
    AppLogger.info('Resolving QR: ${qrContent.substring(0, qrContent.length.clamp(0, 50))}...', 'QrResolver');

    for (final resolver in _resolvers) {
      if (resolver.canResolve(qrContent)) {
        final result = await resolver.resolve(qrContent);
        if (result != null) {
          AppLogger.info(
            'Resolved by ${resolver.runtimeType}: ${result.type.name} → ${result.identifier}',
            'QrResolver',
          );
          return result;
        }
      }
    }

    AppLogger.warning('No resolver matched QR content', 'QrResolver');
    return null;
  }
}
