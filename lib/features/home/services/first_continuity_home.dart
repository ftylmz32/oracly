/// First-journey Home recall — evidence-only, time-bounded.
library;

import '../../../core/data/datasources/local_storage.dart';
import '../../../core/domain/models/reading.dart';
import '../../companion/services/first_reading_or_deepen.dart';

/// Safe Home hero evidence for the completed first Tarot + OR deepen.
class FirstContinuityHomeState {
  const FirstContinuityHomeState({
    required this.sessionId,
    required this.cardName,
    required this.createdAt,
  });

  final String sessionId;
  final String cardName;
  final DateTime createdAt;
}

/// Derives continuity from existing deepen keys + persisted Tarot history.
abstract final class FirstContinuityHome {
  FirstContinuityHome._();

  /// First-experience acknowledgment window (~48 hours).
  static const recallWindow = Duration(hours: 48);

  /// Null when evidence is missing, unmatched, stale, or deepen unused.
  static FirstContinuityHomeState? resolve({
    required LocalStorage storage,
    required List<ReadingModel> history,
    DateTime? now,
  }) {
    if (!FirstReadingOrDeepen.isConsumed(storage)) return null;
    final sessionId = FirstReadingOrDeepen.eligibleSessionId(storage);
    if (sessionId == null) return null;

    final reading = _match(history, sessionId);
    if (reading == null) return null;

    final clock = now ?? DateTime.now();
    final age = clock.difference(reading.createdAt);
    if (age.isNegative || age > recallWindow) return null;

    final cardName = safeCardName(reading);
    if (cardName.isEmpty) return null;

    return FirstContinuityHomeState(
      sessionId: sessionId,
      cardName: cardName,
      createdAt: reading.createdAt,
    );
  }

  /// Card title only — never intention, AI body, or OR chat text.
  static String safeCardName(ReadingModel reading) {
    if (reading.cards.isNotEmpty) {
      final fromCard = reading.cards.first.cardName.trim();
      if (fromCard.isNotEmpty) return fromCard;
    }
    final raw = reading.cardName.trim();
    if (raw.isEmpty) return '';
    final sep = raw.indexOf(' · ');
    if (sep >= 0 && sep + 3 < raw.length) {
      return raw.substring(sep + 3).trim();
    }
    return raw;
  }

  static ReadingModel? _match(List<ReadingModel> history, String sessionId) {
    for (final reading in history) {
      if (reading.id == sessionId) return reading;
      final sid = reading.sessionId?.trim() ?? '';
      if (sid == sessionId) return reading;
    }
    return null;
  }
}
