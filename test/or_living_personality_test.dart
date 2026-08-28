/// Living personality — one OR, varied days, realistic warmth.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/conversation_copy.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_core.dart';
import 'package:oracly_new/core/personality/or_living_voice.dart';
import 'package:oracly_new/core/personality/or_personality.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/ai/production/openai/oracle_prompt_locale.dart';
import 'package:oracly_new/features/astrology/copy/astrology_presentation_copy.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/companion/data/companion_conversation_copy.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/prompt_engine/templates/sections/shared_sections.dart';
import 'package:oracly_new/features/star_map/copy/star_map_polish_copy.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';

Set<String> _acrossDays(String Function(DateTime day) line) {
  return {
    for (var day = 1; day <= 16; day++) line(DateTime(2026, 4, day, 11)),
  };
}

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('core stays warm, intelligent, realistic, curious, not a people-pleaser', () {
    expect(OrCore.systemIdentity, contains('sıcak'));
    expect(OrCore.systemIdentity, contains('zeki'));
    expect(OrCore.systemIdentity, contains('gerçekçi'));
    expect(OrCore.systemIdentity, contains('meraklı'));
    expect(OrCore.systemIdentity, contains('ince esprili'));
    expect(OrCore.systemIdentity, contains(OrCore.interpretationStance));
    expect(OrCore.interpretationStance, contains('somut ayrıntı'));
    expect(OrCore.interpretationStance, contains('Her yanıta soru ekleme'));
    expect(OrCore.looksForcedPositivity('her şey çok güzel olacak'), isTrue);
    for (final style in AiPersonality.values) {
      final body = OrPersonality.conversationStyle(OrPersonality.chatKey(style));
      expect(body, contains('sıcak'));
      expect(body, contains('zeki'));
      expect(body, contains('gerçekçi'));
    }
  });

  test('shared persona and chat system carry interpretation stance', () {
    expect(SharedTemplateSections.basePersona, contains(OrCore.systemIdentity));
    expect(ChatPromptBuilder.system, contains(OrCore.interpretationStance));
    expect(ChatPromptBuilder.system, contains('Her yanıta soru ekleme'));
  });

  test('greetings, loading, and closings vary across days', () {
    final greetings = _acrossDays(
      (day) => OrLivingVoice.greeting(personality: 'gentle', moment: day),
    );
    final thinking = _acrossDays(
      (day) => OrLivingVoice.thinking(moment: day),
    );
    final closings = _acrossDays(
      (day) => OrLivingVoice.closing(moment: day),
    );
    expect(greetings.length, greaterThan(1));
    expect(thinking.length, greaterThan(1));
    expect(closings.length, greaterThan(1));
  });

  test('observation asides include living stance, not a template loop', () {
    final pool = OrLivingVoice.asidePool();
    expect(pool, contains('Burada ilginç bir şey var.'));
    expect(pool, contains('Bu kısmı biraz daha dikkatli okumak lazım.'));
    expect(pool, contains('Ben bunu doğrudan böyle yorumlamam.'));
    expect(pool, contains('Şu ayrıntı bence önemli.'));
    expect(_acrossDays((day) => OrLivingVoice.aside(moment: day)).length, greaterThan(1));
  });

  test('surfaces share one intelligence with contextual loading', () {
    expect(CoffeeCopy.analyzing.toLowerCase(), anyOf(contains('fincan'), contains('ilginç')));
    expect(PalmCopy.analyzing.toLowerCase(), anyOf(contains('çizgi'), contains('ayrıntı'), contains('avuç'), contains('iz')));
    expect(DreamCopy.reflecting.toLowerCase(), anyOf(contains('rüya'), contains('iz')));
    expect(TarotPolishCopy.interpreting.toLowerCase(), anyOf(contains('kart'), contains('duruş')));
    expect(AstrologyPresentationCopy.livingLine, isNotEmpty);
    expect(StarMapPolishCopy.livingLine, isNotEmpty);
    for (final surface in OrLivingSurface.values) {
      for (final line in OrLivingVoice.thinkingPool(surface)) {
        expect(OrCore.soundsAlive(line), isTrue, reason: line);
        expect(line.toLowerCase(), isNot(contains('her şey çok güzel')));
      }
    }
  });

  test('prompts forbid repetitive personality and keep realism', () {
    expect(OrLivingVoice.promptRule(), contains('aşırı olumlu'));
    expect(SharedTemplateSections.basePersona, contains(OrLivingVoice.promptRule()));
    expect(OraclePromptLocale.system, contains(OrLivingVoice.promptRule()));
    expect(
      ChatPromptBuilder.messages(userMessage: 'selam').first['content'],
      contains(OrLivingVoice.promptRule()),
    );
    final hi = CompanionConversationCopy.greeting(
      'gentle',
      moment: DateTime(2026, 4, 2),
    );
    expect(OrCore.looksCustomerService(hi), isFalse);
    expect(ConversationCopy.closingWhisper(moment: DateTime(2026, 4, 2)), isNotEmpty);
  });
}
