/// Ritual stage prompts.
library;

import 'tarot_ritual_stage.dart';

abstract final class TarotRitualCopy {
  TarotRitualCopy._();

  static String prompt(TarotRitualStage stage) => switch (stage) {
        TarotRitualStage.shuffle => 'Desteyi kaydırarak karıştır.',
        TarotRitualStage.cut => 'Üst paketi ayır, sonra birleştir.',
        TarotRitualStage.draw => 'Üst kartı yukarı çek.',
        TarotRitualStage.reveal => 'Kart açılıyor…',
        TarotRitualStage.place => '',
        TarotRitualStage.deckReady => 'Desten hazır.',
      };
}
