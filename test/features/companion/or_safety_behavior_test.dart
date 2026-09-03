/// OR safety behavior — warm allowed; harmful / dependent / invented blocked.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/reading/ai_output_quality_category.dart';
import 'package:oracly_new/core/reading/ai_output_quality_gate.dart';
import 'package:oracly_new/core/reading/ai_output_quality_kind.dart';
import 'package:oracly_new/core/safety/or_safety_behavior.dart';
import 'package:oracly_new/core/safety/sensitive_topic_detector.dart';
import 'package:oracly_new/core/safety/sensitive_topic_gate.dart';
import 'package:oracly_new/core/safety/sensitive_topic_kind.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/ai/services/conversation_response_guard.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('live prompt carries OR safety rules', () {
    final sys = ChatPromptBuilder.system.toLowerCase();
    expect(sys, contains('bağımlılık'));
    expect(sys, contains('insan olduğunu iddia'));
    expect(sys, contains('geleceği kesin'));
    expect(sys, contains('tıbbi talimat'));
  });

  test('warm observation is allowed', () {
    const warm =
        'Bu üzüntü ağır duruyor. Neyin sıkıştırdığını somut bir yerden söyleyebilirsin.';
    expect(OrSafetyBehavior.violates(warm), isFalse);
    final gate = AiOutputQualityGate.validate(
      warm,
      kind: AiOutputQualityKind.companion,
    );
    expect(gate.isAcceptable, isTrue);
  });

  test('blocks future certainty and fabrication markers', () {
    expect(OrSafetyBehavior.claimsFutureCertainty('Kesin olacak yarın.'), isTrue);
    expect(
      OrSafetyBehavior.fabricatesFacts('Daha önce söylemiştin işini bırakacağını.'),
      isTrue,
    );
    final future = AiOutputQualityGate.validate(
      'Kesinlikle olacak bu hafta.',
      kind: AiOutputQualityKind.companion,
    );
    expect(future.isAcceptable, isFalse);
  });

  test('blocks diagnosis and unsafe medical directives', () {
    expect(OrSafetyBehavior.claimsDiagnosis('Depresyondasın kesin.'), isTrue);
    expect(
      OrSafetyBehavior.unsafeMedicalDirective('İlacını bırak, gerek yok.'),
      isTrue,
    );
    expect(
      SensitiveTopicDetector.detect('İlacımı bırakmalı mıyım fal söyler mi?'),
      SensitiveTopicKind.health,
    );
    final med = AiOutputQualityGate.validate(
      'İlacını bırak bugünden itibaren.',
      kind: AiOutputQualityKind.companion,
    );
    expect(med.category, AiOutputQualityCategory.medicalDiagnosis);
  });

  test('blocks dependency and harm; keeps warmth without cling', () {
    expect(
      OrSafetyBehavior.manipulatesDependency('Her zaman buradayım, sadece bana güven.'),
      isTrue,
    );
    expect(
      OrSafetyBehavior.encouragesHarm('Kendine zarar ver, çözüm bu.'),
      isTrue,
    );
    final cling = ConversationResponseGuard.polish(
      'Her zaman buradayım, sadece bana güven.',
      userMessage: 'Yalnızım.',
    );
    expect(cling, 'Ne oldu?');
  });

  test('blocks pretending to be human', () {
    expect(
      OrSafetyBehavior.pretendsToBeHuman('Ben gerçek bir insanım, inan bana.'),
      isTrue,
    );
    final claim = AiOutputQualityGate.validate(
      'Ben bir insanım ve seni anlıyorum.',
      kind: AiOutputQualityKind.companion,
    );
    expect(claim.isAcceptable, isFalse);
  });

  test('local prediction and crisis stay fail-closed', () {
    final or = const CompanionResponder();
    final predict = or.respond(
      request: const InsightRequest(text: 'Yarın kesin olacak mı?'),
      context: const ReflectionContext(),
    );
    expect(predict.body.toLowerCase(), isNot(contains('kesin olacak')));
    final crisis = SensitiveTopicGate.maybeRespond('Kendimi öldürmek istiyorum');
    expect(crisis, isNotNull);
    expect(crisis!.toLowerCase(), contains('182'));
  });
}

