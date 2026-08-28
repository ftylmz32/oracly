/// Content quality report copy — observational, never private text.
library;

import '../l10n_triple.dart';

const kL10nQualityLoop = <String, L10nTriple>{
  'quality.section': L10nTriple(
    'Kalite özeti',
    'Quality summary',
    'Сводка качества',
  ),
  'quality.empty': L10nTriple(
    'Henüz kalite sinyali yok',
    'No quality signal yet',
    'Пока нет сигнала качества',
  ),
  'quality.problem': L10nTriple(
    'En çok zorlanan',
    'Most strained',
    'Самое трудное',
  ),
  'quality.issue': L10nTriple(
    'En sık neden',
    'Most common issue',
    'Частая причина',
  ),
  'quality.success': L10nTriple(
    'En sakin akan',
    'Most at ease',
    'Самое спокойное',
  ),
  'quality.feature.coffee': L10nTriple('Kahve', 'Coffee', 'Кофе'),
  'quality.feature.palm': L10nTriple('Avuç', 'Palm', 'Ладонь'),
  'quality.feature.tarot': L10nTriple('Tarot', 'Tarot', 'Таро'),
  'quality.feature.dream': L10nTriple('Rüya', 'Dream', 'Сон'),
  'quality.feature.astrology': L10nTriple(
    'Astroloji',
    'Astrology',
    'Астрология',
  ),
  'quality.feature.starMap': L10nTriple(
    'Yıldızname',
    'Star reading',
    'Звёздная карта',
  ),
  'quality.feature.companion': L10nTriple('OR', 'OR', 'OR'),
};
