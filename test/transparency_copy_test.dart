import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/transparency_copy.dart';
import 'package:oracly_new/core/personality/or_core.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/ai/production/openai/oracle_prompt_builder.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/insights/services/reflective_intelligence.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/prompt_engine/templates/sections/shared_sections.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';

void main() {
  group('TransparencyCopy', () {
    test('interpretation footnote is a quiet symbolic line', () {
      expect(
        ReflectiveIntelligence.containsForbiddenTone(
          TransparencyCopy.interpretationFootnote,
        ),
        isFalse,
      );
      expect(
        TransparencyCopy.interpretationBrief,
        'Bu, sembolik bir yorumdur.',
      );
      expect(
        TransparencyCopy.interpretationFootnote,
        TransparencyCopy.interpretationBrief,
      );
      expect(
        TransparencyCopy.interpretationFootnote.toLowerCase(),
        isNot(contains('garanti')),
      );
    });

    test('privacy is plain: discoveries personalize, no infra lecture', () {
      expect(
        TransparencyCopy.privacyIntro,
        contains('Keşiflerin kişiselleştirme için kullanılır.'),
      );
      expect(
        TransparencyCopy.privacyIntro.toLowerCase(),
        isNot(contains('shared')),
      );
      expect(TransparencyCopy.privacyIntro.toLowerCase(), isNot(contains('api')));
      expect(
        TransparencyCopy.privacyIntro.toLowerCase(),
        isNot(contains('yapay zek')),
      );
    });

    test('journal privacy reinforces user ownership', () {
      expect(
        TransparencyCopy.journalPrivacy.toLowerCase(),
        contains('sana aittir'),
      );
    });

    test('readings share one symbolic whisper, not a legal wall', () {
      const line = 'Bu, sembolik bir yorumdur.';
      expect(CoffeeCopy.disclaimer, line);
      expect(DreamCopy.disclaimer, line);
      expect(TarotPolishCopy.disclaimer, line);
      // Palm touches health lines, so it names the medical limit once.
      expect(PalmCopy.disclaimer.toLowerCase(), contains('sembolik'));
      expect(PalmCopy.disclaimer.toLowerCase(), contains('teşhis değildir'));
      expect(PalmCopy.disclaimer.split(' '), hasLength(lessThan(12)));
    });
  });

  test('OR separates know, observe, infer, and not-know', () {
    expect(OrCore.epistemic, contains('Bildiğini'));
    expect(OrCore.epistemic, contains('gözlemlediğini'));
    expect(OrCore.epistemic, contains('çıkarsadığını'));
    expect(OrCore.epistemic, contains('bilemediğini'));
    expect(OrCore.epistemic, contains('sembolik olarak'));
    expect(OrCore.epistemic, contains('geleneksel yorumda'));
    expect(OrCore.epistemic, contains('böyle okunabilir'));
    expect(OrCore.systemIdentity, contains(OrCore.epistemic));
    expect(SharedTemplateSections.basePersona, contains(OrCore.epistemic));
    expect(ChatPromptBuilder.system, contains(OrCore.epistemic));
    expect(
      OraclePromptBuilder.messages(
        context: const TarotAiContext(
          sessionId: 's',
          spreadLabel: 'Tek',
          readingTitle: 'Tek',
          cardsSummary: 'Deli',
          interpretationSummary: 'Başlangıç.',
        ),
        userMessage: 'ne dersin',
      ).first['content'],
      contains(OrCore.epistemic),
    );
  });
}
