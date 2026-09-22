/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeWands02 = NarrativeCardProfile(
  canonicalCardId: 'wands_02',
  coreMeaning: L10nTriple(
    'İki ufuk arasında duran ateşi; henüz atılmamış bir adımı anlatır.',
    'It speaks of fire standing between two horizons; a step not yet taken.',
    'Говорит об огне между двумя горизонтами; о шаге, который ещё не сделан.',
  ),
  light: L10nTriple(
    'Bekleyiş, manzarayı netleştirerek daha bilinçli bir yön seçimine alan açabilir.',
    'Waiting can clarify the view and make room for a more conscious heading.',
    'Ожидание может прояснить вид и дать место более осознанному курсу.',
  ),
  shadow: L10nTriple(
    'Durma hali, kaçış, kayıtsızlık veya acele seçim olarak giyinebilir.',
    'Stillness may dress as escape, apathy, or a hasty pick.',
    'Покой может одеться бегством, апатией или поспешным выбором.',
  ),
  tension: L10nTriple(
    'İki yolun çekimi ile henüz atlamama ihtiyacı aynı anda hissedilir.',
    'The pull of two paths coexists with the need not to leap yet.',
    'Притяжение двух путей соседствует с нуждой ещё не прыгать.',
  ),
  desire: L10nTriple(
    'Kişi, doğru ufku seçmeden önce manzarayı sakinçe kavramak isteyebilir.',
    'There may be a wish to grasp the view calmly before choosing a horizon.',
    'Может хотеться спокойно охватить вид, прежде чем выбрать горизонт.',
  ),
  fear: L10nTriple(
    'Yanlış yolu seçmek veya sonsuza dek beklemede kalmak kaygı yaratabilir.',
    'Choosing the wrong path or remaining forever in waiting may cause unease.',
    'Тревогу может вызывать страх выбрать неверный путь или навечно остаться в ожидании.',
  ),
  relationshipDynamic: L10nTriple(
    'İlişkide iki tempo çatışabilir; birini ezmeden ufku birlikte okumayı önerir.',
    'Two tempos may clash in a bond; it favors reading the horizon together without crushing either.',
    'В связи могут столкнуться два темпа; карта предлагает читать горизонт вместе, не давя ни один.',
  ),
  decisionDynamic: L10nTriple(
    'Karar henüz zorunlu olmayabilir; seçenekleri karşılaştırmak acele yargıdan değerlidir.',
    'A decision may not yet be required; comparing options matters more than a rushed verdict.',
    'Решение ещё может быть необязательным; сравнение вариантов важнее поспешного приговора.',
  ),
  actionDirection: L10nTriple(
    'Ufka bakın, iki yolu karşılaştırın; henüz atlamayın.',
    'Look at the horizon, compare the two paths; do not leap yet.',
    'Смотрите на горизонт, сравните два пути; ещё не прыгайте.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sakin bir duruş, iki ufku aynı anda tutarak bilinçli bekleyişi güçlendirir.',
      'A calm stance strengthens conscious waiting by holding both horizons in view.',
      'Спокойная поза усиливает осознанное ожидание, удерживая оба горизонта в поле зрения.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['twoPaths', 'waiting', 'horizon'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bekleyiş kararsızlığa, acele seçime veya umursamazlığa kayabilir.',
      'Waiting may slide into indecision, a hasty pick, or indifference.',
      'Ожидание может стать нерешительностью, поспешным выбором или безразличием.',
    ),
    transforms: [ReversedTransformKind.avoidance, ReversedTransformKind.delay],
    keywordIds: ['indecision', 'hastyPick', 'apathy'],
  ),
  symbolTags: [
    NarrativeSymbolTags.choice,
    NarrativeSymbolTags.pause,
    NarrativeSymbolTags.perspective,
  ],
  profileRevision: 1,
);
