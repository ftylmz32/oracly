/// OR response grounding — invent nothing as fact.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/honesty/or_response_grounding.dart';
import 'package:oracly_new/core/reading/ai_output_quality_category.dart';
import 'package:oracly_new/core/reading/ai_output_quality_context.dart';
import 'package:oracly_new/core/reading/ai_output_quality_gate.dart';
import 'package:oracly_new/core/reading/ai_output_quality_kind.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';

void main() {
  test('context evidence requires tagged buckets only', () {
    expect(OrResponseGrounding.hasContextEvidence(null), isFalse);
    expect(OrResponseGrounding.hasContextEvidence('thread tip'), isFalse);
    expect(
      OrResponseGrounding.hasContextEvidence('FACT: Adı Ayşe'),
      isTrue,
    );
    expect(
      OrResponseGrounding.hasContextEvidence('OBSERVATION: tekrar eden iz'),
      isTrue,
    );
  });

  test('biography and capability invention always fail the gate', () {
    final bio = AiOutputQualityGate.validate(
      'Geçen hafta annen hakkında konuşmuştuk.',
      kind: AiOutputQualityKind.companion,
      context: const AiOutputQualityContext(hasMemoryEvidence: true),
    );
    expect(bio.isAcceptable, isFalse);
    expect(bio.category, AiOutputQualityCategory.fakeMemory);

    final cap = AiOutputQualityGate.validate(
      'Takvimine baktım, yarın boşsun.',
      kind: AiOutputQualityKind.companion,
      context: const AiOutputQualityContext(hasMemoryEvidence: true),
    );
    expect(cap.isAcceptable, isFalse);
    expect(cap.category, AiOutputQualityCategory.fakeMemory);
  });

  test('ungrounded memory and discovery fail without evidence', () {
    final mem = AiOutputQualityGate.validate(
      'Hatırlıyorum ki sen bundan bahsetmiştin.',
      kind: AiOutputQualityKind.companion,
      context: const AiOutputQualityContext(hasMemoryEvidence: false),
    );
    expect(mem.category, AiOutputQualityCategory.fakeMemory);

    final disc = AiOutputQualityGate.validate(
      'Kartında söylemiştik, bu tema devam ediyor.',
      kind: AiOutputQualityKind.companion,
      context: const AiOutputQualityContext(hasMemoryEvidence: false),
    );
    expect(disc.category, AiOutputQualityCategory.fakeMemory);
  });

  test('reflective metaphor without invention still passes', () {
    final result = AiOutputQualityGate.validate(
      'Bu eşik bir kapı gibi duruyor; istersen oradan bakabiliriz.',
      kind: AiOutputQualityKind.companion,
    );
    expect(result.isAcceptable, isTrue);
  });

  test('live chat system prompt includes grounding rule', () {
    expect(ChatPromptBuilder.system, contains(OrResponseGrounding.promptTr));
  });
}


