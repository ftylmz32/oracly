import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/personality/living_universe_copy.dart';
import 'package:oracly_new/core/personality/or_conversation_voice.dart';
import 'package:oracly_new/core/personality/or_personality.dart';
import 'package:oracly_new/core/personality/or_phrase_rotator.dart';
import 'package:oracly_new/core/universe/oracly_universe_state.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';

void main() {
  test('OrPersonality forbids certainty language', () {
    expect(OrPersonality.forbidsCertainty('Kesinlikle olacak'), isTrue);
    expect(OrPersonality.forbidsCertainty('Belki bir alan açılıyor.'), isFalse);
  });

  test('OrPhraseRotator avoids immediate repeat when pool allows', () {
    const pool = ['A', 'B', 'C'];
    final first = OrPhraseRotator.pick(pool: pool, seed: 'x');
    final second = OrPhraseRotator.pick(pool: pool, seed: 'x', avoid: first);
    expect(second, isNot(first));
  });

  test('LivingUniverseCopy morning line is calm', () {
    final universe = OraclyUniverseState.current(DateTime(2026, 8, 7, 8));
    final line = LivingUniverseCopy.atmosphericLine(
      universe: universe,
      asOf: universe.moment,
    );
    expect(line, isNotEmpty);
    expect(OrPersonality.forbidsCertainty(line), isFalse);
  });

  test('OrConversationVoice intro varies by personality', () {
    final moment = DateTime(2026, 8, 7, 10);
    final mystical = OrConversationVoice.intro(
      personality: AiPersonality.mystical,
      moment: moment,
    );
    final direct = OrConversationVoice.intro(
      personality: AiPersonality.direct,
      moment: moment,
    );
    expect(mystical, isNot(equals(direct)));
  });
}
