import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/registration_repository.dart';

/// Family provider for live roll number availability check
final rollNumberAvailableProvider = FutureProvider.family<bool, String>((ref, rollNumber) async {
  if (rollNumber.trim().length != 15) {
    return false;
  }
  final repository = ref.read(registrationRepositoryProvider);
  return repository.isRollNumberAvailable(rollNumber.trim());
});
