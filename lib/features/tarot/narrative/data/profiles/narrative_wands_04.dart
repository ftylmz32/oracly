/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeWands04 = NarrativeCardProfile(
  canonicalCardId: 'wands_04',
  coreMeaning: L10nTriple(
    'Ateşin ev eşiğinde durduğu ara nefesi ve köklenen bir molayı anlatır.',
    'It speaks of fire pausing at a household threshold; a rooted interval of breath.',
    'Говорит об огне у порога дома; об укоренённом промежутке дыхания.',
  ),
  light: L10nTriple(
    'Paylaşılan bir eşik, sakin bir aidiyet ve görünür bir rahatlama yaratabilir.',
    'A shared threshold can create calm belonging and visible ease.',
    'Общий порог может создать спокойную принадлежность и видимое облегчение.',
  ),
  shadow: L10nTriple(
    'Mola, erken kutlama, dağılma veya yerleşememe haline kayabilir.',
    'The pause may slide into an early feast, scatter, or unsettled drift.',
    'Пауза может стать ранним праздником, рассевом или неустроенностью.',
  ),
  tension: L10nTriple(
    'Anı işaretleme isteği ile yolun bitmediğini bilme ihtiyacı birlikte durur.',
    'The wish to mark the moment sits beside knowing the road is not finished.',
    'Желание отметить миг соседствует со знанием, что путь ещё не кончен.',
  ),
  desire: L10nTriple(
    'Kişi, burada güvenle durabileceği sıcak bir eşik arayabilir.',
    'There may be a wish for a warm threshold where one can stand with trust.',
    'Может хотеться тёплого порога, где можно стоять с доверием.',
  ),
  fear: L10nTriple(
    'Köklenememek, kutlamanın boş kalması veya molanın durağanlığa dönmesi kaygı yaratabilir.',
    'Failing to take root, an empty feast, or pause becoming stagnation may cause unease.',
    'Тревогу может вызывать страх не укорениться, пустого праздника или превращения паузы в застой.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda sakin paylaşım belirebilir; eşiği kutlarken yolu bitmiş saymamayı hatırlatır.',
    'Calm sharing may appear in a bond; it reminds that marking a threshold is not ending the road.',
    'В связи может явиться спокойное разделение; карта напоминает: отметить порог — не значит закончить путь.',
  ),
  decisionDynamic: L10nTriple(
    'Karar, bir aşamayı tanımak ile harekete devam etmek arasında denge arar.',
    'The decision seeks balance between recognizing a stage and continuing motion.',
    'Решение ищет баланс между признанием этапа и продолжением движения.',
  ),
  actionDirection: L10nTriple(
    'Anı işaretleyin, köklenmeye izin verin; henüz yol bitti demeyin.',
    'Mark the moment, allow rooting; do not say the road is finished.',
    'Отметьте миг, позвольте укоренению; не говорите, что путь кончен.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Köklenen bir ara nefes, ateşi ev eşiğinde güvenli ve paylaşılır tutar.',
      'A rooted interval of breath keeps fire safe and shareable at the household threshold.',
      'Укоренённый промежуток дыхания держит огонь у порога дома безопасным и делимым.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['thresholdFeast', 'root', 'pause'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Eşik kutlaması erken gelebilir, dağılabilir ya da yerleşme hissi oluşmayabilir.',
      'Threshold celebration may come early, scatter, or fail to settle into place.',
      'Праздник порога может прийти рано, рассеяться или не дать чувства устроенности.',
    ),
    transforms: [
      ReversedTransformKind.delay,
      ReversedTransformKind.internalization,
    ],
    keywordIds: ['earlyFeast', 'scatter', 'unsettled'],
  ),
  symbolTags: [
    NarrativeSymbolTags.pause,
    NarrativeSymbolTags.belonging,
    NarrativeSymbolTags.threshold,
  ],
  profileRevision: 1,
);
