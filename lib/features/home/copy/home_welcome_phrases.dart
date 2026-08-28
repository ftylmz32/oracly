/// EPIC-018 — Rotating mystical welcome lines for the home greeting.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/personality/or_phrase_rotator.dart';

abstract final class HomeWelcomePhrases {
  HomeWelcomePhrases._();

  static List<String> get phrases => [
        for (var i = 0; i < 16; i++) OraclyL10n.t('home.phrase.$i'),
      ];

  static String forDay({
    required DateTime day,
    String salt = '',
  }) {
    return OrPhraseRotator.daily(
      pool: phrases,
      day: day,
      salt: salt,
    );
  }
}
