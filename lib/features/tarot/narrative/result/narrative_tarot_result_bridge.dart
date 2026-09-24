/// Phase 6D — structured result → InterpretationResult bridge (dormant).
library;

import '../../interpretation/models/interpretation_result.dart';
import '../evidence/narrative_request.dart';
import 'narrative_tarot_structured_result.dart';

/// Compatibility bridge only — does not call DateTime.now().
/// Card block uses displayName + title-cased positionKey (6F UI review).
abstract final class NarrativeTarotResultBridge {
  NarrativeTarotResultBridge._();

  static InterpretationResult toInterpretationResult({
    required TarotNarrativeRequest request,
    required NarrativeTarotStructuredResult result,
    required String requestId,
    required String sessionId,
    required DateTime generatedAt,
    InterpretationSource source = InterpretationSource.ai,
  }) {
    final byId = {
      for (final c in request.cards) c.canonicalCardId: c,
    };
    final cardBlock = StringBuffer();
    for (final reading in result.cardReadings) {
      final card = byId[reading.cardId];
      final name = card?.displayName ?? reading.cardId;
      final pos = _titleCaseKey(reading.positionKey);
      if (cardBlock.isNotEmpty) cardBlock.writeln();
      cardBlock.writeln('$pos · $name');
      cardBlock.write(reading.text);
    }

    String area(String kind) {
      for (final a in result.lifeAreas) {
        if (a.kind == kind) return a.text;
      }
      return '';
    }

    return InterpretationResult(
      requestId: requestId,
      sessionId: sessionId,
      summary: result.summary,
      love: area('love'),
      career: area('career'),
      money: area('money'),
      health: cardBlock.toString(),
      spiritualGuidance: area('spiritual'),
      advice: result.advice,
      warnings: result.reflectionPrompt ?? '',
      luckyEnergy: result.synthesis,
      dailyFocus: result.dailyFocus ?? '',
      closingMessage: result.closingMessage,
      generatedAt: generatedAt,
      source: source,
      rawText: null,
    );
  }

  static String _titleCaseKey(String key) {
    if (key.isEmpty) return key;
    return key[0].toUpperCase() + key.substring(1);
  }
}
