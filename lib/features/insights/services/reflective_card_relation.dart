/// How two tarot cards speak together — from real keywords/meanings only.
library;

import '../../tarot/copy/tarot_l10n.dart';
import '../../tarot/interpretation/models/reading_context.dart';
import 'reflective_card_copy.dart';

abstract final class ReflectiveCardRelation {
  ReflectiveCardRelation._();

  static String pair(ReadingCardContext a, ReadingCardContext b) {
    final vars = {
      'left': ReflectiveCardCopy.named(a),
      'right': ReflectiveCardCopy.named(b),
    };
    final mass = '${a.keywords.join(' ')} ${b.keywords.join(' ')} '
        '${a.effectiveMeaning} ${b.effectiveMeaning}'
        .toLowerCase();
    if (_has(mass, ['belirsiz', 'uncertain', 'sis', 'moon', 'туман']) &&
        _has(mass, ['hareket', 'yol', 'başlangıç', 'ilerleme', 'değişim', 'move'])) {
      return TarotL10n.fill('tarot.rel.pair.fog', vars);
    }
    if (_has(mass, [
          'imparator',
          'emperor',
          'kontrol',
          'authority',
          'güç',
          'control',
          'император',
        ]) &&
        _has(mass, ['belirsiz', 'uncertain', 'sis', 'moon', 'туман', 'luna'])) {
      return TarotL10n.fill('tarot.rel.pair.control', vars);
    }
    if (_has(mass, ['aşk', 'kalp', 'cup', 'bağ', 'love', 'люб']) &&
        _has(mass, ['söz', 'adalet', 'seçim', 'iletişim', 'word', 'justice'])) {
      return TarotL10n.fill('tarot.rel.pair.love', vars);
    }
    if (_has(mass, ['iş', 'emek', 'pentacle', 'para', 'düzen', 'work']) &&
        _has(mass, ['engel', 'kule', 'yük', 'ters', 'tower', 'load'])) {
      return TarotL10n.fill('tarot.rel.pair.work', vars);
    }
    return TarotL10n.fill('tarot.rel.pair.fallback', vars);
  }

  static bool _has(String haystack, List<String> needles) =>
      needles.any(haystack.contains);
}
