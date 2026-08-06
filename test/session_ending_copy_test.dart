import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/copy/session_ending_copy.dart';
import 'package:oracly_new/features/insights/services/reflective_intelligence.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';

void main() {
  group('SessionEndingCopy', () {
    test('lastingReflection prefers closing message', () {
      const content = AiReadingContent(
        cardName: 'The Star',
        tagline: 'Umut',
        generalMeaning: 'Özet.',
        love: 'Aşk.',
        career: 'Kariyer.',
        money: 'Para.',
        spiritualGuidance: '• Soru?',
        luckyEnergy: 'Tema',
        dailyAdvice: 'Öneri.',
        imageAsset: 'assets/test.png',
        rarityColor: Color(0xFFFFFFFF),
        closingMessage: 'Bu cümle seninle kalsın.',
      );

      expect(
        SessionEndingCopy.lastingReflection(content),
        'Bu cümle seninle kalsın.',
      );
    });

    test('affirmationBeat avoids duplicating dailyAdvice', () {
      const content = AiReadingContent(
        cardName: 'The Star',
        tagline: 'Umut',
        generalMeaning: 'Özet cümlesi burada.',
        love: 'Aşk.',
        career: 'Kariyer.',
        money: 'Para.',
        spiritualGuidance: '• Bugün ne hissediyorsun?',
        luckyEnergy: 'Tema',
        dailyAdvice: 'Pratik öneri burada.',
        imageAsset: 'assets/test.png',
        rarityColor: Color(0xFFFFFFFF),
        closingMessage: 'Son yansıma cümlesi. İkinci cümle.',
      );

      final beat = SessionEndingCopy.affirmationBeat(content);
      expect(beat, isNot(contains('Pratik öneri')));
      expect(beat, 'Son yansıma cümlesi.');
    });

    test('closing fallback avoids forbidden tone', () {
      expect(
        ReflectiveIntelligence.containsForbiddenTone(
          SessionEndingCopy.closingFallback,
        ),
        isFalse,
      );
    });

    test('footer whisper avoids return pressure', () {
      final lower = SessionEndingCopy.footerWhisper.toLowerCase();
      expect(lower, isNot(contains('hemen geri')));
      expect(lower, isNot(contains('mutlaka')));
    });
  });
}
