/// Ritual stage prompts.
library;

import '../../../core/l10n/l10n.dart';
import 'tarot_ritual_stage.dart';

abstract final class TarotRitualCopy {
  TarotRitualCopy._();

  static String prompt(TarotRitualStage stage) => switch (stage) {
        TarotRitualStage.shuffle =>
          OraclyL10n.t('tarot.ritual.stage.shuffle'),
        TarotRitualStage.cut => OraclyL10n.t('tarot.ritual.stage.cut'),
        TarotRitualStage.draw => OraclyL10n.t('tarot.ritual.stage.draw'),
        TarotRitualStage.reveal => OraclyL10n.t('tarot.ritual.stage.reveal'),
        TarotRitualStage.place => '',
        TarotRitualStage.deckReady => OraclyL10n.t('tarot.ritual.deck_ready'),
      };
}
