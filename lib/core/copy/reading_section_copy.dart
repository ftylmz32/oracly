/// TASK-001 — Reading screen section labels aligned to emotional flow.
library;

import '../../features/tarot/presentation/widgets/ai_reading/reading_section_theme.dart';
import '../l10n/l10n.dart';

abstract final class ReadingSectionCopy {
  ReadingSectionCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get headingHint => _t('read.heading_hint');
  static String get meaning => _t('read.meaning');
  static String get summary => _t('read.summary');
  static String get cards => _t('read.cards');
  static String get love => _t('read.love');
  static String get career => _t('read.career');
  static String get money => _t('read.money');
  static String get spiritual => _t('read.spiritual');
  static String get hidden => _t('read.hidden');
  static String get suggestion => _t('read.suggestion');
  static String get lucky => _t('read.lucky');
  static String get energy => _t('read.energy');

  static String loveTitle(String? theme) => theme == 'love'
      ? _t('read.love_rel')
      : theme == 'career'
          ? _t('read.career_now')
          : love;

  static String careerTitle(String? theme) => theme == 'love'
      ? _t('read.love_other')
      : theme == 'career'
          ? _t('tarot.near_term')
          : career;

  static String moneyTitle(String? theme) => theme == 'love'
      ? _t('read.possible')
      : theme == 'career'
          ? _t('read.obstacle')
          : money;

  static String get questionPrompt => _t('read.question');
  static String get closing => _t('read.closing');
  static String get bridgeToMeaning => _t('tarot.interpreting');
  static String get bridgeToReflection => _t('first.prep_d');
  static String get bridgeToClosing => _t('first.breath');

  static String titleFor(ReadingSectionKind kind) {
    return switch (kind) {
      ReadingSectionKind.general => meaning,
      ReadingSectionKind.love => love,
      ReadingSectionKind.career => career,
      ReadingSectionKind.money => money,
      ReadingSectionKind.spiritual => spiritual,
      ReadingSectionKind.hidden => hidden,
      ReadingSectionKind.warning => suggestion,
      ReadingSectionKind.lucky => lucky,
    };
  }
}
