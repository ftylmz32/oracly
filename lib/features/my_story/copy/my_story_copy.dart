/// BENİM HİKÂYEM — journal tone, observational only.
library;

import '../../../core/l10n/l10n.dart';

abstract final class MyStoryCopy {
  MyStoryCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get title => _t('my_story.title');
  static String get subtitle => _t('my_story.subtitle');
  static String get openCta => _t('my_story.open');
  static String get periodHeading => _t('my_story.period_heading');
  static String get footnote => _t('journal.philosophy');
  static String get sourcesPrefix => _t('my_story.sources_prefix');

  static String sourcesLine(String sources) =>
      _t('my_story.sources_prefix').replaceAll('{sources}', sources);
}
