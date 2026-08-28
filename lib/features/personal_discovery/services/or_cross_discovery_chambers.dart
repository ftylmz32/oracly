/// Chamber ids + mention tokens for OR cross-discovery context.
library;

import '../../../core/l10n/l10n.dart';

abstract final class OrCrossDiscoveryChambers {
  OrCrossDiscoveryChambers._();

  static const ids = {
    'tarot',
    'coffee',
    'astrology',
    'starMap',
    'star',
    'star_map',
    'palm',
    'daily',
    'dailyMessage',
  };

  static String label(String source) => switch (source) {
        'tarot' => OraclyL10n.t('or.ctx.chamber.tarot'),
        'coffee' => OraclyL10n.t('or.ctx.chamber.coffee'),
        'astrology' => OraclyL10n.t('or.ctx.chamber.astrology'),
        'starMap' || 'star' || 'star_map' =>
          OraclyL10n.t('or.ctx.chamber.star_map'),
        'palm' => OraclyL10n.t('or.ctx.chamber.palm'),
        'daily' || 'dailyMessage' => OraclyL10n.t('or.ctx.chamber.daily'),
        'reflection' => OraclyL10n.t('or.ctx.chamber.reflection'),
        _ => '',
      };

  static bool mentioned(String source, String msg) {
    final keys = switch (source) {
      'tarot' => const ['tarot', 'açılım', 'acilim', 'kart'],
      'coffee' => const ['kahve', 'coffee', 'fincan'],
      'astrology' => const ['astroloji', 'burç', 'burc', 'horoscope'],
      'starMap' || 'star' || 'star_map' => const [
          'yıldızname',
          'yildizname',
          'doğum haritas',
          'dogum haritas',
          'natal',
        ],
      'palm' => const ['el fal', 'palm', 'avuç', 'avuc'],
      'daily' || 'dailyMessage' => const [
          'günlük mesaj',
          'gunluk mesaj',
          'daily message',
        ],
      _ => const <String>[],
    };
    return keys.any(msg.contains);
  }
}
