/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeCups06 = NarrativeCardProfile(
  canonicalCardId: 'cups_06',
  coreMeaning: L10nTriple(
    'Eski kadehin bugünkü sofrada durmasını anlatır; bellek ve yalınlık alanıdır, karşılıklılık değil.',
    'It speaks of an old cup on today\'s table; a field of memory and simplicity, not mutuality.',
    'Говорит о старой чаше на сегодняшнем столе; поле памяти и простоты, не взаимности.',
  ),
  light: L10nTriple(
    'Anı yumuşak tutulduğunda, geçmiş şimdiyi boğmadan ısıtabilir.',
    'When memory is held gently, the past can warm the present without drowning it.',
    'Когда память держат мягко, прошлое может согревать настоящее, не затопляя его.',
  ),
  shadow: L10nTriple(
    'Bellek geçmişe kilitlenmeye, çocuk rolüne veya şimdiyi kaçırmaya kayabilir.',
    'Memory may lock to the past, a child role, or missing the now.',
    'Память может зафиксироваться в прошлом, детской роли или упущенном настоящем.',
  ),
  tension: L10nTriple(
    'Hatırlama arzusu ile orada kalmama ihtiyacı aynı anda hissedilir.',
    'The wish to remember coexists with the need not to remain there.',
    'Желание помнить соседствует с нуждой там не оставаться.',
  ),
  desire: L10nTriple(
    'Kişi, tanıdık bir sıcaklığı yalınlıkla yeniden hissetmek isteyebilir.',
    'There may be a wish to feel a familiar warmth again in simplicity.',
    'Может хотеться снова почувствовать знакомое тепло в простоте.',
  ),
  fear: L10nTriple(
    'Geçmişi kaybetmek veya şimdiyi tamamen kaçırmak kaygı yaratabilir.',
    'Losing the past, or completely missing the present, may cause unease.',
    'Тревогу может вызывать утрата прошлого или полное упущение настоящего.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda tanıdık bir yumuşaklık belirebilir; anıyı bugünkü alışverişten ayırmayı ister.',
    'Familiar softness may appear in a bond; it asks to separate memory from today\'s exchange.',
    'В связи может возникнуть знакомая мягкость; карта просит отделить память от сегодняшнего обмена.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, nostaljiyi şimdiki gerçek seçeneklerle karşılaştırarak netleşir.',
    'The choice clarifies by comparing nostalgia with present real options.',
    'Выбор проясняется сравнением ностальгии с нынешними реальными вариантами.',
  ),
  actionDirection: L10nTriple(
    'Anıyı hatırlayın, yalınlığı koruyun; geçmişte kalmayın.',
    'Remember the memory, protect simplicity; do not remain in the past.',
    'Вспомните память, берегите простоту; не оставайтесь в прошлом.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Yumuşak bir bellek, eski kadehi bugünün sofrasında boğmadan tutar.',
      'Gentle memory keeps an old cup on today\'s table without drowning the now.',
      'Мягкая память держит старую чашу на сегодняшнем столе, не затопляя настоящее.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['oldCup', 'memory', 'simplicity'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bellek geçmiş rolünü içe çekebilir veya şimdiyle teması erteleyebilir.',
      'Memory may internalize into a private past-role, or delay contact with the present.',
      'Память может уйти внутрь в частную прошлую роль или отложить контакт с настоящим.',
    ),
    transforms: [
      ReversedTransformKind.internalization,
      ReversedTransformKind.delay,
    ],
    keywordIds: ['pastLock', 'childRole', 'missingNow'],
  ),
  symbolTags: [
    NarrativeSymbolTags.cycles,
    NarrativeSymbolTags.nurture,
    NarrativeSymbolTags.belonging,
  ],
  profileRevision: 1,
);
