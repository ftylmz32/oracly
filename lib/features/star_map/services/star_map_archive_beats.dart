/// Quiet archive turns. Symbolic, not theatrical, never natal.
library;

import '../../../core/l10n/l10n.dart';
import '../../personal_discovery/copy/personal_theme_copy.dart';

abstract final class StarMapArchiveBeats {
  StarMapArchiveBeats._();

  static String today({
    required String mark,
    required String sign,
    int seed = 0,
  }) {
    final slot = seed.abs() % 3;
    if (sign.trim().isEmpty) {
      return _fill('star.arc.today.bare.$slot', {'mark': _matter(mark)});
    }
    return _fill('star.arc.today.sun.$slot', {
      'mark': _matter(mark),
      'sign': _clip(sign),
    });
  }

  static String sky({
    required String mark,
    required String sign,
    int seed = 0,
  }) {
    final slot = seed.abs() % 3;
    if (sign.trim().isEmpty) {
      return _fill('star.arc.sky.bare.$slot', {'mark': _matter(mark)});
    }
    return _fill('star.arc.sky.sun.$slot', {
      'mark': _matter(mark),
      'sign': _clip(sign),
    });
  }

  static String knot(String inner, {int seed = 0}) {
    final slot = seed.abs() % 3;
    final text = inner.trim();
    if (text.isEmpty || text == PersonalThemeCopy.insufficient) {
      return OraclyL10n.t('star.arc.knot.soft.$slot');
    }
    return _fill('star.arc.knot.full.$slot', {'knot': _matter(text)});
  }

  static String recent(String story, {int seed = 0}) {
    final slot = seed.abs() % 3;
    final text = story.trim();
    if (text.isEmpty || text == PersonalThemeCopy.insufficient) {
      return OraclyL10n.t('star.arc.recent.soft.$slot');
    }
    return _fill('star.arc.recent.full.$slot', {'story': _matter(text)});
  }

  static String gate(String life, [int seed = 0]) {
    final text = life.trim();
    if (text.isEmpty || text == PersonalThemeCopy.insufficient) {
      return OraclyL10n.t('star.arc.gate.thin.${seed.abs() % 3}');
    }
    final lower = text.toLowerCase();
    final slot = seed.abs() % 2;
    if (_bind.any(lower.contains)) {
      return OraclyL10n.t('star.arc.gate.bind.$slot');
    }
    if (_work.any(lower.contains)) {
      return OraclyL10n.t('star.arc.gate.work.$slot');
    }
    return OraclyL10n.t('star.arc.gate.open.${seed.abs() % 3}');
  }

  static String ask(String life, [int seed = 0]) {
    final text = life.trim();
    if (text.isEmpty || text == PersonalThemeCopy.insufficient) {
      return OraclyL10n.t('star.arc.ask.thin.${seed.abs() % 3}');
    }
    return _fill('star.arc.ask.full.${seed.abs() % 3}', {
      'knot': _matter(text),
    });
  }

  static const _bind = ['ilişki', 'sınır', 'aşk', 'yakın', 'love', 'closeness'];
  static const _work = ['kariyer', 'yön', 'career', 'work', 'karar', 'değiş'];

  static String _fill(String key, Map<String, String> values) {
    var out = OraclyL10n.t(key);
    values.forEach((k, v) => out = out.replaceAll('{$k}', v));
    return out.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  static String _matter(String raw) {
    var text = _clip(raw);
    const wraps = [
      r'^Bugün [^ ]+ tarafında duran (damar|iz):?\s*',
      r'^Bugün duran (damar|iz):?\s*',
      r'^Bugünün izi şöyle duruyor:\s*',
      r'^Bugün bakılacak yer\s*',
      r'^.+ olarak bugün sende duran şey\s*',
      r'^Bugünün izi .+ damarında seçilir:\s*',
      r'^.+ Güneşin için: ',
      r'^For your .+ Sun: ',
      r'^Для твоего Солнца в знаке .+: ',
      r'^Bu arşiv yaprağında .+ fasıl:\s*',
      r'^Arşivde .+ ipliği seçilir:\s*',
    ];
    for (final wrap in wraps) {
      text = text.replaceFirst(RegExp(wrap), '');
    }
    for (final g in ['bugün ', 'today ', 'сегодня ']) {
      if (text.toLowerCase().startsWith(g)) {
        text = text.substring(g.length).trim();
        break;
      }
    }
    return _clip(text);
  }

  static String _clip(String raw) {
    var text = raw.trim();
    final dot = text.indexOf('.');
    if (dot > 0 && dot < text.length - 1) {
      text = text.substring(0, dot);
    }
    while (text.endsWith('.') || text.endsWith(',')) {
      text = text.substring(0, text.length - 1).trim();
    }
    return text;
  }
}
