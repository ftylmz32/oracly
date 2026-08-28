/// Reading version labels — original, revisions, compare.
library;

import '../l10n_triple.dart';

const kL10nReadingVersion = <String, L10nTriple>{
  'version.new_reading': L10nTriple(
    'Yeni yorum',
    'New reading',
    'Новое толкование',
  ),
  'version.original': L10nTriple(
    'Orijinal',
    'Original',
    'Оригинал',
  ),
  'version.revision': L10nTriple(
    'Revizyon {n}',
    'Revision {n}',
    'Редакция {n}',
  ),
  'version.compare': L10nTriple(
    'Karşılaştır',
    'Compare',
    'Сравнить',
  ),
  'version.compare.title': L10nTriple(
    'Yorumları karşılaştır',
    'Compare readings',
    'Сравнить толкования',
  ),
  'version.unchanged': L10nTriple(
    'Yeni yorum öncekinden farklı değildi.',
    'The new reading was not meaningfully different.',
    'Новое толкование существенно не отличалось.',
  ),
};
