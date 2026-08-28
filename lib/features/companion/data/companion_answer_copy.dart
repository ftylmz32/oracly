/// Data catalog — answer-first ORACLY chat replies (locale-bound).
library;

import '../../../core/l10n/l10n.dart';

abstract final class CompanionAnswerCopy {
  CompanionAnswerCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get tarot => _t('or.answer.tarot');
  static String get dream => _t('or.answer.dream');
  static String get astrology => _t('or.answer.astrology');
  static String get coffee => _t('or.answer.coffee');
  static String get love => _t('or.answer.love');
  static String get energy => _t('or.answer.energy');
  static String get general => _t('or.answer.general');
  static String get unrelated => _t('or.answer.unrelated');

  static String memory(String note) =>
      _t('or.answer.memory').replaceAll('{note}', note);
}
