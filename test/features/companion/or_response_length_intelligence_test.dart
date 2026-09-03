/// OR response-length intelligence — varies length; never pads.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/companion/services/or_response_length_intelligence.dart';

void main() {
  test('greetings stay very short and are not padded to deep', () {
    final depth = OrResponseLengthIntelligence.select(
      userMessage: 'Selam',
      preference: OrResponseDepth.deep,
    );
    expect(depth, OrResponseDepth.veryShort);
  });

  test('short preference is a hard ceiling', () {
    final depth = OrResponseLengthIntelligence.select(
      userMessage:
          'İş değiştirmek istiyorum çünkü patronumla ilişkim bozuldu '
          've kararsızım, ne yapmalıyım?',
      preference: OrResponseDepth.short,
    );
    expect(depth.rank, lessThanOrEqualTo(OrResponseDepth.short.rank));
  });

  test('explicit detail request can reach deep under deep preference', () {
    final depth = OrResponseLengthIntelligence.select(
      userMessage: 'Bunu bana detaylı anlat.',
      preference: OrResponseDepth.deep,
    );
    expect(depth, OrResponseDepth.deep);
  });

  test('explicit short request stays short', () {
    final depth = OrResponseLengthIntelligence.select(
      userMessage: 'Kısaca özetle ne düşünüyorsun.',
      preference: OrResponseDepth.deep,
    );
    expect(
      depth,
      anyOf(OrResponseDepth.short, OrResponseDepth.veryShort),
    );
  });

  test('medium preference maps to balanced and blocks deep drift', () {
    expect(OrResponseDepth.medium, OrResponseDepth.balanced);
    final depth = OrResponseLengthIntelligence.select(
      userMessage: 'Bugün biraz yorgunum.',
      preference: OrResponseDepth.balanced,
    );
    expect(depth, isNot(OrResponseDepth.deep));
    expect(depth.rank, lessThanOrEqualTo(OrResponseDepth.balanced.rank));
  });

  test('continuing important thread can deepen within preference', () {
    const turns = [
      ConversationTurn(role: ConversationTurn.userRole, text: 'İş değiştirmeyi düşünüyorum.'),
      ConversationTurn(role: ConversationTurn.assistantRole, text: 'Ne zamandır?'),
      ConversationTurn(role: ConversationTurn.userRole, text: 'Üç aydır.'),
      ConversationTurn(role: ConversationTurn.assistantRole, text: 'Asıl sıkışma ne?'),
    ];
    final brief = OrResponseLengthIntelligence.select(
      userMessage: 'Selam',
      preference: OrResponseDepth.deep,
      turns: turns,
    );
    final heavy = OrResponseLengthIntelligence.select(
      userMessage:
          'Korkuyorum çünkü karar vermem lazım ve ailem de karışıyor, '
          'ilişkim de etkileniyor. Ne yapmalıyım?',
      preference: OrResponseDepth.deep,
      turns: turns,
    );
    expect(brief.rank, lessThan(heavy.rank));
  });

  test('veryShort caps at two sentences', () {
    final wall = [for (var i = 1; i <= 6; i++) 'Cümle $i.'].join(' ');
    final out = OrResponseDepth.veryShort.cap(wall, spoken: false);
    expect(
      out.split(RegExp(r'(?<=[.!?])\s+')).where((p) => p.trim().isNotEmpty).length,
      2,
    );
  });

  test('preference chips exclude veryShort', () {
    expect(OrResponseDepth.preferenceValues, isNot(contains(OrResponseDepth.veryShort)));
    expect(OrResponseDepth.preferenceValues, contains(OrResponseDepth.balanced));
  });
}

