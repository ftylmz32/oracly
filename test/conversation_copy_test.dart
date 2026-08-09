import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/copy/conversation_copy.dart';
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
      final text = ConversationCopy.welcome();
      expect(text.toLowerCase(), contains('düşünmek'));
      expect(text, isNot(contains('👋')));
    });

    test('oracle suggestions invite reflection not commands', () {
      for (final chip in ConversationCopy.oracleSuggestions) {
        expect(chip.toLowerCase(), isNot(contains('ne yapmalı')));
        expect(chip.toLowerCase(), isNot(contains('uyarısı')));
      }
    });

    test('closing whisper avoids continue pressure', () {
      expect(
        ConversationCopy.closingWhisper.toLowerCase(),
        contains('zorunda değilsin'),
      );
      expect(ConversationCopy.closingWhisper.toLowerCase(), contains('huzur'));
    });

    test('companion subtitle frames local device reflection', () {
      expect(ConversationCopy.companionSubtitle, contains('Cihazında'));
      expect(
        ConversationCopy.companionSubtitle.toLowerCase(),
        isNot(contains('yapay')),
      );
      expect(
        ConversationCopy.companionSubtitle.toLowerCase(),
        isNot(contains('ai')),
      );
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
  });
}
