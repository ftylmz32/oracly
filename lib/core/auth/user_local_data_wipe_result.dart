/// Honest outcome of [UserLocalDataWipe.run] — lets a caller positively
/// distinguish a complete wipe from one that left account-scoped residue,
/// instead of an opaque `Future<void>` that hides individual failures.
library;

class UserLocalDataWipeResult {
  const UserLocalDataWipeResult({required this.failedOperations});

  /// Safe operation/key identifiers only — never the stored values
  /// themselves. Each entry names WHAT failed to clear (a storage key, or
  /// a short label for a composite operation), never sensitive content.
  final List<String> failedOperations;

  /// True iff every mandatory account-scoped cleanup step succeeded. Only
  /// then may a caller treat local ownership as having fully transferred.
  bool get isComplete => failedOperations.isEmpty;

  @override
  String toString() =>
      'UserLocalDataWipeResult(isComplete: $isComplete, failedOperations: '
      '$failedOperations)';
}
