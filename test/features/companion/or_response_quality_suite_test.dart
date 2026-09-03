/// OR response quality suite A — greeting, emotion, facts, complexity, disagreement.
/// Behavior regression only; never exact prose.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_emotional_intelligence.dart';
import 'package:oracly_new/core/personality/or_natural_humor.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/features/companion/data/companion_directness.dart';
import 'package:oracly_new/features/companion/services/or_adaptive_conversation.dart';
import 'package:oracly_new/features/companion/services/or_response_length_intelligence.dart';
import 'or_response_quality_harness.dart';

void main() {
  final h = OrQualityHarness();
  setUp(() => OraclyL10n.bind('tr'));

  test('casual greeting stays short and human', () {
    final body = h.say('Selam.').body;
    h.expectHumanChamber(body, maxLen: 80);
    expect(
      body.split(RegExp(r'[.!?]+')).where((p) => p.trim().isNotEmpty).length,
      lessThanOrEqualTo(2),
    );
  });

  test('emotional conversation stays calm, not clinical', () {
    const msg = 'Bugün biraz üzgünüm, içim dar.';
    final sensed = OrEmotionalIntelligence.sense(msg);
    expect(sensed.signals, contains(OrEmotionalSignal.sadness));
    expect(OrNaturalHumor.stanceFor(msg), OrHumorStance.serious);
    final body = h.say(msg).body;
    h.expectHumanChamber(body);
    h.expectAvoids(body, ['depresyon', 'teşhis', 'diagnos', 'hahaha']);
  });

  test('factual question prefers evidence-oriented register', () {
    const msg = 'Bu gerçek mi, kanıt var mı?';
    final read = OrAdaptiveConversation.sense(msg);
    expect(read.registers, contains(OrConversationRegister.factual));
    final body = h.say(msg).body;
    h.expectHumanChamber(body);
    h.expectAvoids(body, ['kesin gelecek', 'kaderinde yazıyor']);
  });

  test('complex question invites deeper register', () {
    final msg =
        'İşimi bırakmayı düşünüyorum çünkü evdeki denge bozuldu, '
        'ama maddi güvenlik de önemli ve iki yıldır aynı döngüdeyim; '
        'aile, zaman ve kimlik aynı anda baskı yapıyor — '
        'nasıl bakmalıyım buna sakin bir şekilde?';
    expect(msg.length, greaterThan(160));
    final read = OrAdaptiveConversation.sense(msg);
    expect(read.registers, contains(OrConversationRegister.deep));
    final depth = OrResponseLengthIntelligence.select(
      userMessage: msg,
      preference: OrResponseDepth.deep,
    );
    expect(depth.rank, greaterThanOrEqualTo(OrResponseDepth.balanced.rank));
    final greetingDepth = OrResponseLengthIntelligence.select(
      userMessage: 'Selam.',
      preference: OrResponseDepth.deep,
    );
    expect(depth.rank, greaterThan(greetingDepth.rank));
  });

  test('disagreement stays kind and clear', () {
    const claim = 'Herkes iş değiştirmeli.';
    expect(
      CompanionDirectness.detect(claim),
      CompanionDirectnessKind.disagree,
    );
    final body = h.say(claim).body;
    h.expectHumanChamber(body);
    expect(body.toLowerCase(), contains('katılmıyorum'));
    h.expectAvoids(body, ['aslında basit', 'sakin ol', 'sen anlamıyorsun']);
  });
}

