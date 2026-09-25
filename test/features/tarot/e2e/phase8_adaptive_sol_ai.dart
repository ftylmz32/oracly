/// Phase 8 — adaptive Narrative AI for flagship widget E2E (test-only).
library;

import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/oracly_narrative_tarot_ai_service.dart';

import '../narrative_live/phase6f_live_support.dart';

/// Sol V2 clone remapped to whatever cards the live request carries.
class Phase8AdaptiveSolThreeAi implements OraclyNarrativeTarotAiService {
  int callCount = 0;

  @override
  Future<AiOutcome<Map<String, dynamic>>> generateNarrativeTarotReading({
    required Map<String, dynamic> payload,
    required String fingerprint,
    int attempt = 1,
  }) async {
    callCount++;
    final clone = cloneSolThreeForEmptySession();
    final narrative = payload['narrative'];
    final cards = narrative is Map
        ? (narrative['cards'] as List? ?? const [])
        : const [];
    final templates = (clone['cardReadings'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final readings = <Map<String, dynamic>>[];
    for (var i = 0; i < cards.length; i++) {
      final c = Map<String, dynamic>.from(cards[i] as Map);
      final t = Map<String, dynamic>.from(templates[i % templates.length]);
      t['cardId'] = c['canonicalCardId'];
      t['positionKey'] = c['positionKey'];
      t['text'] =
          'This position invites calm attention to what is present now.';
      readings.add(t);
    }
    clone['cardReadings'] = readings;
    return AiOutcome.success(clone);
  }
}
