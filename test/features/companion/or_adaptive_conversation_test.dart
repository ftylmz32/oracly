/// Adaptive conversation depth — follow the user; keep OR identity.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_persona_contract.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/companion/services/or_adaptive_conversation.dart';
import 'package:oracly_new/features/companion/services/or_response_length_intelligence.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('senses concise, deep, technical, casual, emotional, factual', () {
    expect(
      OrAdaptiveConversation.sense('Kısaca söyle.').registers,
      contains(OrConversationRegister.concise),
    );
    expect(
      OrAdaptiveConversation.sense('Bunu derinlemesine anlat.').registers,
      contains(OrConversationRegister.deep),
    );
    expect(
      OrAdaptiveConversation.sense("Python'da async nasıl çalışır?").registers,
      contains(OrConversationRegister.technical),
    );
    expect(
      OrAdaptiveConversation.sense('Bugün biraz üzgünüm.').registers,
      contains(OrConversationRegister.emotional),
    );
    expect(
      OrAdaptiveConversation.sense('Bu gerçek mi, kanıt var mı?').registers,
      contains(OrConversationRegister.factual),
    );
    expect(
      OrAdaptiveConversation.sense('Şaka yaptım lol').registers,
      contains(OrConversationRegister.casual),
    );
  });

  test('depth bias respects settings ceiling', () {
    final deep = OrResponseLengthIntelligence.select(
      userMessage: 'Bunu derinlemesine anlat lütfen.',
      preference: OrResponseDepth.short,
    );
    expect(deep, OrResponseDepth.short);

    final short = OrResponseLengthIntelligence.select(
      userMessage: 'Kısaca.',
      preference: OrResponseDepth.deep,
    );
    expect(short.rank, lessThanOrEqualTo(OrResponseDepth.short.rank));
  });

  test('learns deeper rhythm from sustained long turns', () {
    final turns = [
      for (var i = 0; i < 2; i++)
        ConversationTurn(
          role: ConversationTurn.userRole,
          text: 'A' * 120,
        ),
    ];
    final read = OrAdaptiveConversation.sense(
      '${'B' * 90} ve devamı.',
      turns: turns,
    );
    expect(read.registers, contains(OrConversationRegister.deep));
  });

  test('live prompt adapts depth without replacing identity', () {
    expect(ChatPromptBuilder.system, contains(OrAdaptiveConversation.promptTr));
    expect(ChatPromptBuilder.system, contains(OrPersonaContract.identityTr));
    expect(ChatPromptBuilder.system.toLowerCase(), contains('kimliğini'));
    expect(
      OrAdaptiveConversation.styleHintFor('Kısaca.'),
      contains('identity stays fixed'),
    );
  });
}
