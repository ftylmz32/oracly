/// OR natural humor — smile when welcome; never a comedian.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_natural_humor.dart';
import 'package:oracly_new/core/reading/ai_output_quality_category.dart';
import 'package:oracly_new/core/reading/ai_output_quality_gate.dart';
import 'package:oracly_new/core/reading/ai_output_quality_kind.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/companion/services/or_context_selection_engine.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('welcomes humor when the user is playful', () {
    expect(
      OrNaturalHumor.stanceFor('Åaka yaptım lol'),
      OrHumorStance.welcome,
    );
    expect(
      OrNaturalHumor.stanceFor('Bu biraz saçma değil mi?'),
      OrHumorStance.welcome,
    );
  });

  test('stays serious on heavy or sad turns', () {
    expect(
      OrNaturalHumor.stanceFor('Bugün biraz üzgünüm.'),
      OrHumorStance.serious,
    );
    expect(
      OrNaturalHumor.stanceFor('Korkuyorum, hastalığım var.'),
      OrHumorStance.serious,
    );
  });

  test('neutral ordinary chat has no humor styleHint', () {
    expect(OrNaturalHumor.stanceFor('Saat kaç?'), OrHumorStance.neutral);
    expect(OrNaturalHumor.styleHintFor('Saat kaç?'), isNull);
  });

  test('live prompt invites restrained humor and rhythm', () {
    expect(ChatPromptBuilder.system, contains(OrNaturalHumor.promptTr));
    expect(ChatPromptBuilder.system.toLowerCase(), contains('komedyen'));
    expect(ChatPromptBuilder.system.toLowerCase(), contains('ritmi'));
  });

  test('styleHint suppresses jokes in serious moments', () {
    final hint = OrContextSelectionEngine.styleHint(
      currentMessage: 'Çok kızgınım.',
      recentMessages: const [],
    );
    expect(hint.toLowerCase(), contains('ciddi'));
    expect(hint.toLowerCase(), contains('espri yok'));
  });

  test('comedian joke storms fail the quality gate', () {
    final result = AiOutputQualityGate.validate(
      'Here is a joke. Why did the chicken. Punchline hahaha!!!',
      kind: AiOutputQualityKind.companion,
    );
    expect(result.isAcceptable, isFalse);
    expect(result.category, AiOutputQualityCategory.repetitiveFiller);
  });
}

