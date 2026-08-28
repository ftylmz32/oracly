/// Human warmth without therapist boilerplate.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/personality/or_core.dart';
import 'package:oracly_new/core/personality/or_persona_contract.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/ai/services/conversation_empathy_guard.dart';
import 'package:oracly_new/features/ai/services/conversation_response_guard.dart';

void main() {
  test('empathy guard strips stock scripts and keeps noticing', () {
    final kept = ConversationEmpathyGuard.shape(
      'Seni anlıyorum. Mesafe yeniden görünüyor.',
    );
    expect(kept.toLowerCase(), isNot(contains('seni anlıyorum')));
    expect(kept.toLowerCase(), contains('mesafe'));

    final hard = ConversationEmpathyGuard.shape(
      'Bunun senin için zor olduğunu biliyorum. İş eşiği net.',
    );
    expect(hard.toLowerCase(), isNot(contains('zor olduğunu')));
    expect(hard.toLowerCase(), contains('eşiğ'));

    final valid = ConversationEmpathyGuard.shape(
      'Hislerinin geçerli olduğunu söylemek isterim. Tempo yavaş.',
    );
    expect(valid.toLowerCase(), isNot(contains('geçerli')));
    expect(valid.toLowerCase(), contains('tempo'));

    final presence = ConversationEmpathyGuard.shape(
      'Buradayım. Kapıda bir duraksama var.',
    );
    expect(presence.toLowerCase(), isNot(contains('buradayım')));
    expect(presence.toLowerCase(), contains('kapı'));
  });

  test('polish removes therapist boilerplate without nuking content', () {
    final polished = ConversationResponseGuard.polish(
      'Seni anlıyorum. Mesafe yeniden görünüyor.',
      userMessage: 'Biraz uzaklaştım.',
    );
    expect(polished.toLowerCase(), isNot(contains('seni anlıyorum')));
    expect(polished.toLowerCase(), contains('mesafe'));

    final en = ConversationResponseGuard.polish(
      "I understand how you feel. The job thread is still open.",
      userMessage: 'İş zor geliyor.',
    );
    expect(en.toLowerCase(), isNot(contains('i understand how you feel')));
    expect(en.toLowerCase(), contains('job'));
  });

  test('persona and prompts reject stock empathy', () {
    final id = OrPersonaContract.identityTr.toLowerCase();
    expect(id, contains('seni anlıyorum'));
    expect(id, contains('fark ettiğin'));
    expect(OrCore.looksTherapistScript('Seni anlıyorum.'), isTrue);
    expect(
      OrCore.looksTherapistScript(
        'Hislerinin geçerli olduğunu söylemek isterim.',
      ),
      isTrue,
    );
    expect(ChatPromptBuilder.system.toLowerCase(), contains('hazır empati'));
  });
}
