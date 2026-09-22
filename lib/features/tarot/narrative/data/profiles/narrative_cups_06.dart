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
    'An old cup on today\'s table; a field of memory and simplicity, not mutuality.',
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
    'Familiar warmth in simple form may be what someone reaches for.',
    'Может хотеться снова почувствовать знакомое тепло в простоте.',
  ),
  fear: L10nTriple(
    'Geçmişi kaybetmek veya şimdiyi tamamen kaçırmak kaygı yaratabilir.',
    'Losing the past, or completely missing the present, may cause unease.',
    'Тревогу может вызывать утрата прошлого или полное упущение настоящего.',
  ),
  relationshipDynamic: L10nTriple(
    'Eski bir anı iki kişi arasındaki bir anı renklendirdiğinde, o sıcaklığın ne kadarının geçmişe değil bugüne ait olduğunu fark etmek yardımcı olur.',
    'When old memory colors a moment between two people, it helps to notice how much of the warmth belongs to today rather than to the past.',
    'Когда старая память окрашивает момент между двумя людьми, полезно заметить, сколько из этого тепла принадлежит сегодняшнему дню, а не прошлому.',
  ),
  decisionDynamic: L10nTriple(
    'Nostaljiyi şu an mevcut gerçek seçeneklerle karşılaştırmak en net cevabı verir.',
    'Comparing nostalgia against the real options available now brings the clearest answer.',
    'Сравнение ностальгии с реально доступными сейчас вариантами даёт самый ясный ответ.',
  ),
  actionDirection: L10nTriple(
    'Anının hatırlanmasına ve yalın kalmasına izin verin, sonra dikkatinizi geçmişte kalmak yerine bugüne döndürün.',
    'Let the memory be remembered and kept simple, then return your attention to today rather than staying in the past.',
    'Позвольте памяти быть вспомненной и остаться простой, а затем верните внимание к сегодняшнему дню, а не оставайтесь в прошлом.',
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
