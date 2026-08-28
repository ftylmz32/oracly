/// Contextual follow-up chips — small, relevant set per turn.
library;

import '../../../core/l10n/l10n.dart';
import '../data/companion_intent.dart';
import 'companion_thread_topics.dart';

abstract final class CompanionFollowUpChips {
  CompanionFollowUpChips._();

  static String _t(String key) => OraclyL10n.t(key);

  static List<String> forTurn({
    required String lastUserMessage,
    required bool hasReadingContext,
  }) {
    final topic = CompanionThreadTopics.of(lastUserMessage);
    final chips = <String>[_t('or.followup.deepen')];

    if (hasReadingContext) {
      chips.add(_t('or.followup.reading'));
    } else if (CompanionIntent.isUndecided(lastUserMessage) ||
        topic == 'kararsızlık' ||
        CompanionIntent.isAdvice(lastUserMessage)) {
      chips.add(_t('or.followup.decision'));
    } else if (topic == 'ilişki') {
      chips.add(_t('or.followup.relationship'));
    } else if (CompanionIntent.isLow(lastUserMessage) || topic == 'sıkıntı') {
      chips.add(_t('or.followup.emotion'));
    } else if (topic == 'iş') {
      chips.add(_t('or.followup.decision'));
    } else {
      chips.add(_t('or.followup.emotion'));
    }

    return chips.take(2).toList(growable: false);
  }
}
