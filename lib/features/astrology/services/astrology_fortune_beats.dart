/// Seeded sun-sign turns. Catalog facts only; never invented sky.
library;

import '../../../core/l10n/l10n.dart';

abstract final class AstrologyFortuneBeats {
  AstrologyFortuneBeats._();

  static String start(int seed, String sign, String matter) {
    var clip = _clip(matter);
    for (final g in ['bugün ', 'today ', 'сегодня ']) {
      if (clip.toLowerCase().startsWith(g)) {
        clip = clip.substring(g.length).trim();
        break;
      }
    }
    return _fill('sky.read.start.${seed.abs() % 5}', {
      'sign': _clip(sign),
      'matter': clip,
    });
  }

  static String whySun(String sign) =>
      _fill('sky.read.why.sun', {'sign': _clip(sign)});

  static String whyLife(String sign, String life) => _fill(
        'sky.read.why.life',
        {'sign': _clip(sign), 'life': _clip(life)},
      );

  static String whyDomain(String domain) =>
      _fill('sky.read.why.domain', {'domain': _clip(domain)});

  static String feel(String feel) =>
      _fill('sky.read.feel', {'feel': _clip(feel)});

  static String watch(String watch) =>
      _fill('sky.read.watch', {'watch': _clip(watch)});

  static String lane(int seed, String life, String body) => _fill(
        'sky.read.lane.${seed.abs() % 3}',
        {'life': _clip(life), 'body': body.trim()},
      );

  static String inner(int seed, String observed) =>
      _fill('sky.read.inner.${seed.abs() % 3}', {
        'observed': _clip(observed),
      });

  static String ask(String life, [int seed = 0]) {
    final lower = life.toLowerCase();
    if (_bind.any(lower.contains)) return OraclyL10n.t('sky.read.ask.bind');
    if (_work.any(lower.contains)) return OraclyL10n.t('sky.read.ask.work');
    final slot = seed.abs() % 3;
    if (slot == 0) return OraclyL10n.t('sky.read.ask.sun');
    return OraclyL10n.t('sky.read.ask.sun.$slot');
  }

  static const _bind = ['ilişki', 'aşk', 'yakın', 'love', 'closeness', 'связ'];
  static const _work = ['kariyer', 'iş', 'career', 'work', 'дело', 'karar'];

  static String _fill(String key, Map<String, String> values) {
    var out = OraclyL10n.t(key);
    values.forEach((k, v) => out = out.replaceAll('{$k}', v));
    return out.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  static String _clip(String raw) {
    var text = raw.trim();
    while (text.endsWith('.') || text.endsWith(',')) {
      text = text.substring(0, text.length - 1).trim();
    }
    return text;
  }
}
