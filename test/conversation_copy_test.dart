import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/copy/conversation_copy.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/features/ai/services/conversation_response_guard.dart';
import 'package:oracly_new/features/insights/services/reflective_intelligence.dart';

void main() {
  group('ConversationCopy', () {
    test('welcome uses name when provided', () {
      final text = ConversationCopy.welcome(name: 'Ayşe');
      expect(text, contains('Ayşe'));
      expect(text.toLowerCase(), isNot(contains('nasıl yardımcı')));
    });

    test('welcome avoids chatbot tone without name', () {
      final text = ConversationCopy.welcome(
        personality: AiPersonality.gentle,
        moment: DateTime(2026, 1, 1, 9),
      );
      expect(text.toLowerCase(), isNot(contains('nasıl yardımcı')));
      expect(text.toLowerCase(), isNot(contains('yanındayım')));
      expect(text.trim(), isNotEmpty);
      expect(text.length, lessThan(90));
      expect(text, isNot(contains('👋')));
    });

    test('oracle suggestions invite reflection not commands', () {
      for (final chip in [
        ...ConversationCopy.oracleSuggestions,
        ...ConversationCopy.dreamOracleSuggestions,
        ...ConversationCopy.coffeeOracleSuggestions,
        ...ConversationCopy.astrologyOracleSuggestions,
        ...ConversationCopy.birthChartOracleSuggestions,
      ]) {
        expect(chip.toLowerCase(), isNot(contains('ne yapmalı')));
        expect(chip.toLowerCase(), isNot(contains('uyarısı')));
      }
    });

    test('closing whisper avoids continue pressure', () {
      final whisper = ConversationCopy.closingWhisper(
        moment: DateTime(2026, 1, 1, 9),
      ).toLowerCase();
      expect(whisper, isNot(contains('geri gel')));
      expect(whisper, isNot(contains('kaçırma')));
    });
  });

  group('ConversationResponseGuard', () {
    test('polish softens certainty language', () {
      const raw = 'Kesinlikle bu doğru yoldasın.';
      final polished = ConversationResponseGuard.polish(raw);
      expect(
        ReflectiveIntelligence.containsForbiddenTone(polished),
        isFalse,
      );
    });

    test('strips stock openers and customer-service filler', () {
      final polished = ConversationResponseGuard.polish(
        'Elbette, burada başka bir şey var. Mesafe konusu yeniden görünüyor.',
      );
      final lower = polished.toLowerCase();
      expect(lower.startsWith('elbette'), isFalse);
      expect(lower, isNot(contains('burada başka bir şey var')));
      expect(lower, isNot(contains('nasıl yardımcı')));
    });

    test('strips presence filler, forced empathy, and meta-AI openers', () {
      final presence = ConversationResponseGuard.polish(
        'Buradayım. Mesafe yeniden görünüyor.',
        userMessage: 'Biraz uzaklaştım.',
      );
      expect(presence.toLowerCase(), isNot(contains('buradayım')));
      expect(presence.toLowerCase(), contains('mesafe'));

      final empathy = ConversationResponseGuard.polish(
        'I understand how you feel. The job thread is still open.',
        userMessage: 'İş zor geliyor.',
      );
      expect(empathy.toLowerCase(), isNot(contains('i understand how you feel')));

      final meta = ConversationResponseGuard.polish(
        'As an AI, tempo tutmak daha sağlam durur.',
        userMessage: 'Ne olacak?',
      );
      expect(meta.toLowerCase(), isNot(contains('as an ai')));
      expect(meta.toLowerCase(), isNot(contains('yapay zeka')));
      expect(meta.trim(), isNotEmpty);
    });

    test('drops trailing question when policy forbids it', () {
      final polished = ConversationResponseGuard.polish(
        'Karar tarafında sıkışmışlık var. İstersen biraz daha anlatır mısın?',
        allowTrailingQuestion: false,
      );
      expect(polished.trim().endsWith('?'), isFalse);
      expect(polished.toLowerCase(), isNot(contains('anlatır mısın')));
    });

    test('may keep a substantive trailing question when allowed', () {
      final polished = ConversationResponseGuard.polish(
        'İş tarafında bir eşik var. Ne zamandır bunu düşünüyorsun?',
        allowTrailingQuestion: true,
      );
      expect(polished.trim().endsWith('?'), isTrue);
    });
  });
}
