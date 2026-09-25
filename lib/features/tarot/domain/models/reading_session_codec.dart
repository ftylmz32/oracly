/// Soft/strict ReadingSession JSON codec (Phase 5D).
library;

import 'reading_session.dart';
import 'tarot_spread.dart';

abstract final class ReadingSessionCodec {
  ReadingSessionCodec._();

  /// Soft decode — unknown spread returns null (never fabricates single).
  static ReadingSession? tryFromJson(Map<String, dynamic> json) {
    final spread = TarotSpreadType.fromPersisted(json['spread'] as String?);
    if (spread == null) return null;
    final id = json['id'] as String?;
    if (id == null || id.trim().isEmpty) return null;
    try {
      return ReadingSession(
        id: id,
        deckId: json['deckId'] as String? ?? 'rider-waite',
        userId: json['userId'] as String?,
        spread: spread,
        intention: TarotIntention(
          text: json['intention'] as String? ?? '',
          topic: json['intentionTopic'] as String?,
        ),
        shuffleSeed: json['shuffleSeed'] as int? ?? 0,
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
            DateTime.now(),
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
        durationMs: json['durationMs'] as int?,
        drawnCards: (json['drawnCards'] as List<dynamic>? ?? [])
            .map((e) => TarotDrawnCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        interpretation: json['interpretation'] as String?,
        interpretationResultMode:
            json['interpretationResultMode'] as String?,
        interpretationSource: json['interpretationSource'] as String?,
        interpretationDeliveryKind:
            json['interpretationDeliveryKind'] as String?,
        interpretationLocale: json['interpretationLocale'] as String?,
        status: ReadingSessionStatus.values.byName(
          json['status'] as String? ?? 'inProgress',
        ),
        flowStep: ReadingFlowStep.values.byName(
          json['flowStep'] as String? ?? 'deckSelection',
        ),
        currentPositionIndex: json['currentPositionIndex'] as int? ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}
