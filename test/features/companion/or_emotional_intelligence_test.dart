/// OR emotional intelligence — sense signals, never diagnose.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_emotional_intelligence.dart';
import 'package:oracly_new/core/reading/ai_output_quality_category.dart';
import 'package:oracly_new/core/reading/ai_output_quality_gate.dart';
import 'package:oracly_new/core/reading/ai_output_quality_kind.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/companion/services/or_context_selection_engine.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('senses the requested conversational signals', () {
    expect(
      OrEmotionalIntelligence.sense('Bıktım, yine aynı yerdeyim.').signals,
      contains(OrEmotionalSignal.frustration),
    );
    expect(
      OrEmotionalIntelligence.sense('Çok heyecanlıyım, harika haber!').signals,
      contains(OrEmotionalSignal.excitement),
    );
    expect(
      OrEmotionalIntelligence.sense('Emin değilim.').signals,
      contains(OrEmotionalSignal.uncertainty),
    );
    expect(
      OrEmotionalIntelligence.sense('Şaka yaptım lol').signals,
      contains(OrEmotionalSignal.humor),
    );
    expect(
      OrEmotionalIntelligence.sense('Bugün biraz üzgünüm.').signals,
      contains(OrEmotionalSignal.sadness),
    );
    expect(
      OrEmotionalIntelligence.sense('Çok kızgınım.').signals,
      contains(OrEmotionalSignal.anger),
    );
    expect(
      OrEmotionalIntelligence.sense('Merak ettim, acaba neden?').signals,
      contains(OrEmotionalSignal.curiosity),
    );
    expect(
      OrEmotionalIntelligence.sense('Kararsızım, iki arada kaldım.').signals,
      contains(OrEmotionalSignal.indecision),
    );
  });

  test('neutral chat has no emotional styleHint', () {
    expect(OrEmotionalIntelligence.styleHintFor('Saat kaç?'), isNull);
    expect(
      OrEmotionalIntelligence.sense('Sadece duruyorum biraz.').isEmpty,
      isTrue,
    );
  });

  test('live prompt forbids diagnosis and overreaction', () {
    expect(ChatPromptBuilder.system, contains(OrEmotionalIntelligence.promptTr));
    expect(ChatPromptBuilder.system.toLowerCase(), contains('teşhis'));
    expect(ChatPromptBuilder.system.toLowerCase(), contains('orantılı'));
  });

  test('styleHint carries proportional guidance when sensed', () {
    final hint = OrContextSelectionEngine.styleHint(
      currentMessage: 'Bıktım artık.',
      recentMessages: const [],
    );
    expect(hint.toLowerCase(), contains('frustration'));
    expect(hint.toLowerCase(), contains('aşırı tepki yok'));
  });

  test('diagnostic replies fail the quality gate', () {
    final result = AiOutputQualityGate.validate(
      'Depresyondasın, tedaviye başla.',
      kind: AiOutputQualityKind.companion,
    );
    expect(result.isAcceptable, isFalse);
    expect(result.category, AiOutputQualityCategory.fakeMemory);
  });
}
