/// Seeded reader turns — observational, never cookie phrasing.
library;

import '../l10n/l10n.dart';
import 'human_reader_notice.dart';

abstract final class HumanReaderPhrases {
  HumanReaderPhrases._();

  static String t(String key) => OraclyL10n.t(key);

  static int slot(HumanReaderNotice notice) => notice.seed.abs() % 5;

  static String fill(String template, HumanReaderNotice notice) {
    final who = notice.hasName ? '${notice.name.trim()}, ' : '';
    var out = template
        .replaceAll('{who}', who)
        .replaceAll('{seen}', _clip(notice.seen))
        .replaceAll('{companion}', _clip(notice.companion))
        .replaceAll('{life}', _clip(notice.lifeThread))
        .replaceAll('{vessel}', notice.hasVessel ? '${notice.vessel.trim()} ' : '');
    return out.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  static String _clip(String raw) {
    var text = raw.trim();
    while (text.endsWith('.') || text.endsWith(',')) {
      text = text.substring(0, text.length - 1).trim();
    }
    return text;
  }

  static String see(HumanReaderNotice n) =>
      fill(t('reader.see.${slot(n)}'), n);

  static String link(HumanReaderNotice n) =>
      fill(t('reader.link.${slot(n)}'), n);

  static String you(HumanReaderNotice n) {
    if (!n.hasLife) return '';
    return fill(t('reader.you.${slot(n)}'), n);
  }

  static String hedge(HumanReaderNotice n) =>
      fill(t('reader.hedge.${slot(n)}'), n);
}
