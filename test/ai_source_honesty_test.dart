import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/copy/conversation_copy.dart';
import 'package:oracly_new/core/copy/transparency_copy.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/insights/services/reflective_intelligence.dart';

bool _claimsAi(String text) {
  final lower = text.toLowerCase();
  return lower.contains('yapay zek') ||
      lower.contains('ai ') ||
      lower.contains(' ai') ||
      lower == 'ai' ||
      lower.contains('chatgpt') ||
      lower.contains('gpt') ||
      lower.contains('canlı yapay');
}

void main() {
  group('AI source honesty — live local surfaces', () {
    test('Companion local guidance is not labeled as AI', () {
      expect(CompanionCopy.localGuidanceDisclaimer, contains('yerel'));
      expect(CompanionCopy.localGuidanceDisclaimer, contains('canlı model yanıtı değildir'));
      expect(_claimsAi(CompanionCopy.localGuidanceDisclaimer), isFalse);
      expect(_claimsAi(CompanionCopy.screenTitle), isFalse);
      expect(_claimsAi(ConversationCopy.companionSubtitle), isFalse);
      expect(ConversationCopy.companionSubtitle, contains('Cihazında'));
    });

    test('OR\'a Sor conversation caption states local non-live guidance', () {
      expect(TransparencyCopy.conversationCaption, contains('yerel'));
      expect(TransparencyCopy.conversationCaption, contains('canlı model yanıtı değildir'));
      expect(_claimsAi(TransparencyCopy.conversationCaption), isFalse);
      expect(
        ReflectiveIntelligence.containsForbiddenTone(
          TransparencyCopy.conversationCaption,
        ),
        isFalse,
      );
    });

    test('Local Tarot interpretation footnote does not claim AI generation', () {
      expect(
        TransparencyCopy.interpretationFootnote.toLowerCase(),
        isNot(contains('yapay zek')),
      );
      expect(
        TransparencyCopy.interpretationFootnote,
        isNot(contains('yapay zekâ ile oluşturulur')),
      );
      expect(TransparencyCopy.interpretationFootnote, contains('yerel'));
      expect(TransparencyCopy.interpretationFootnote, contains('kart'));
      expect(TransparencyCopy.interpretationFootnote, contains('kehanet değil'));
      expect(
        ReflectiveIntelligence.containsForbiddenTone(
          TransparencyCopy.interpretationFootnote,
        ),
        isFalse,
      );
    });

    test('no fake live-model marketing in honesty copy', () {
      for (final text in [
        CompanionCopy.localGuidanceDisclaimer,
        TransparencyCopy.conversationCaption,
        TransparencyCopy.interpretationFootnote,
        ConversationCopy.companionSubtitle,
      ]) {
        expect(text.toLowerCase(), isNot(contains('chatgpt')));
        expect(text.toLowerCase(), isNot(contains('openai')));
        expect(_claimsAi(text), isFalse);
      }
    });
  });
}
