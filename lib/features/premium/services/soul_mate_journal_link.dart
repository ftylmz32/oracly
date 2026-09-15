/// Soulmate journal identity. One logical result, one row. No second store.
library;

import '../models/soul_mate_saved_result.dart';

abstract final class SoulMateJournalLink {
  SoulMateJournalLink._();

  /// Complete means a real portrait plus authoritative AI text. Not a template.
  static bool isComplete(SoulMateSavedResult? saved) {
    if (saved == null) return false;
    if (saved.id.trim().isEmpty) return false;
    if (saved.portraitPath.trim().isEmpty) return false;
    if (!saved.hasAuthoritativeInterpretation) return false;
    return saved.parts.joined.trim().isNotEmpty;
  }

  static String entryId(String logicalId) => logicalId.trim();

  /// Internal retries keep the logical id. A new user generation already
  /// arrives with a different id from the generation session.
  static bool sameEntry(String existingId, String logicalId) =>
      existingId == entryId(logicalId);

  static bool canReopen({
    required String? savedId,
    required String entryId,
    required bool authoritative,
    required bool hasPortraitBytes,
  }) {
    if (!hasPortraitBytes || !authoritative) return false;
    return savedId != null && savedId == entryId && savedId.isNotEmpty;
  }

  static bool isUserInitiatedNewGeneration({
    required String? previousId,
    required String logicalId,
    required bool internalRetry,
  }) {
    if (internalRetry) return false;
    final next = entryId(logicalId);
    if (next.isEmpty) return false;
    return previousId == null || previousId != next;
  }
}
