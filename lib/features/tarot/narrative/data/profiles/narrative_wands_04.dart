/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeWands04 = NarrativeCardProfile(
  canonicalCardId: 'wands_04',
  coreMeaning: L10nTriple(
    'Ateşin ev eşiğinde durduğu ara nefesi ve köklenen bir molayı anlatır.',
    'Fire pausing at a household threshold; a rooted interval of breath.',
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
    'A warm threshold where one can stand with trust may be sought.',
    'Может хотеться тёплого порога, где можно стоять с доверием.',
  ),
  fear: L10nTriple(
    'Köklenememek, kutlamanın boş kalması veya molanın durağanlığa dönmesi kaygı yaratabilir.',
    'Failing to take root, an empty feast, or pause becoming stagnation may cause unease.',
    'Тревогу может вызывать страх не укорениться, пустого праздника или превращения паузы в застой.',
  ),
  relationshipDynamic: L10nTriple(
    'İnsanlar arasındaki sakin bir paylaşım fark edilmeyi hak eder; bu eşikte durmak yolun bittiği anlamına gelmez.',
    'Calm sharing between people is worth marking, even though pausing at this threshold does not mean the road is finished.',
    'Спокойное совместное переживание между людьми стоит отметить; остановка на этом пороге не значит, что путь окончен.',
  ),
  decisionDynamic: L10nTriple(
    'Bu anın gerektirdiği şey, aşamayı kabul etmek ile harekete devam etmek arasındaki dengedir.',
    'Balance between recognizing this stage and continuing to move is what the moment calls for.',
    'Момент требует равновесия между признанием этого этапа и продолжением движения.',
  ),
  actionDirection: L10nTriple(
    'Bu anı işaretleyin ve köklenmesine izin verin; bir molayı yolun sonuyla karıştırmadan.',
    'Mark this moment and let it take root, without mistaking a pause for the end of the road.',
    'Отметьте этот миг и дайте ему укорениться, не путая паузу с концом пути.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Köklenen bir ara nefes, ateşi ev eşiğinde güvenli ve paylaşılır tutar.',
      'A rooted interval of breath keeps fire safe and shareable at the household threshold.',
      'Укоренённый промежуток дыхания держит огонь у порога дома безопасным и делимым.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.holding,
      NarrativeKeywordIds.roots,
      NarrativeKeywordIds.pause,
    ],
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
    keywordIds: [
      NarrativeKeywordIds.haste,
      NarrativeKeywordIds.scatter,
      NarrativeKeywordIds.instability,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.pause,
    NarrativeSymbolTags.belonging,
    NarrativeSymbolTags.threshold,
  ],
  profileRevision: 1,
);
