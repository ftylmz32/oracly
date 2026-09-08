import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/services/oracle_ai_message_source.dart';
import 'package:oracly_new/features/ai/oracle_conversation/services/oracle_conversation_responder.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';

void main() {
  test('local OR fallback receives the prior assistant reply', () async {
    final local = _SpyLocalResponder();
    final source = OracleAiMessageSource(
      ai: const UnconfiguredOraclyAiService(allowsLocalFallback: true),
      local: local,
    );
    const context = OracleReadingContext(
      sessionId: 's1',
      spreadLabel: 'Tek kart',
      deckId: 'rider-waite',
      deckName: 'Rider-Waite',
      readingTitle: 'The Moon',
      cardsSummary: 'The Moon',
      interpretationSummary: 'Sis ve sezgi.',
    );

    final reply = await source.reply(
      context: context,
      userMessage: 'Peki bunu nasıl okuyayım?',
      priorUser: const ['İçime oturmadı.'],
      priorAssistant: 'Bunu bugün yapmak sana gerçekçi geliyor mu?',
    );

    expect(reply, 'Yerel cevap.');
    expect(
      local.seenPriorAssistant,
      'Bunu bugün yapmak sana gerçekçi geliyor mu?',
    );
  });
}

class _SpyLocalResponder extends OracleConversationResponder {
  String? seenPriorAssistant;

  @override
  Future<String> respond({
    required OracleReadingContext context,
    required String userMessage,
    List<String> priorUser = const [],
    String? priorAssistant,
  }) async {
    seenPriorAssistant = priorAssistant;
    return 'Yerel cevap.';
  }
}
