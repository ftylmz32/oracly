/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeWands10 = NarrativeCardProfile(
  canonicalCardId: 'wands_10',
  coreMeaning: L10nTriple(
    'Çok fazla değneğin omuzlarda konuştuğu yük dilini anlatır.',
    'Too many wands; the language of shoulders under load.',
    'Говорит о слишком многих жезлах; о языке плеч под ношей.',
  ),
  light: L10nTriple(
    'Sorumluluğu tanımak, bir değneği bırakarak taşımayı sürdürülebilir kılabilir.',
    'Recognizing duty can make carrying sustainable by setting one wand down.',
    'Признание долга может сделать ношу устойчивой, если опустить один жезл.',
  ),
  shadow: L10nTriple(
    'Yük, kahramanlık oyunu, çöküş korkusu veya delege edememeye dönüşebilir.',
    'The load may become hero-play, collapse-fear, or an inability to delegate.',
    'Ноша может стать игрой героя, страхом обвала или неумением поручить.',
  ),
  tension: L10nTriple(
    'Hepsini taşıma isteği ile omuzların dediği sınır aynı anda hissedilir.',
    'The wish to carry it all coexists with the limit the shoulders are naming.',
    'Желание нести всё соседствует с пределом, о котором говорят плечи.',
  ),
  desire: L10nTriple(
    'Kişi, sorumluluğu bırakmadan yükü paylaşılabilir hale getirmek isteyebilir.',
    'Making the load shareable without abandoning responsibility may be sought.',
    'Может хотеться сделать ношу делимой, не бросая ответственность.',
  ),
  fear: L10nTriple(
    'Bir şeyi bırakınca her şeyin düşmesi veya yetersiz görünmek kaygı yaratabilir.',
    'Fear that setting one thing down will drop everything, or looking insufficient, may arise.',
    'Может явиться страх, что опустив одно, уронишь всё, или выглядеть недостаточным.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda tek kişinin taşıması yorucu olabilir; yükü kimliğe çevirmemeyi hatırlatır.',
    'One person carrying a bond may tire; it reminds not to turn load into identity.',
    'Когда связь несёт один, это утомляет; карта напоминает не превращать ношу в личность.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, hangi değneğin gerçekten zorunlu olduğunu azaltarak netleştirir.',
    'The choice clarifies which wand is truly required by reducing what is carried.',
    'Выбор проясняет, какой жезл действительно обязателен, сокращая носимое.',
  ),
  actionDirection: L10nTriple(
    'Bir değneği bırakın, yükü azaltın; hepsini birden düşürmeyin.',
    'Set one wand down, reduce the load; do not drop them all at once.',
    'Опустите один жезл, уменьшите ношу; не бросайте все сразу.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Hesap verebilir bir taşıma, fazla ateşi omuzların dilini dinleyerek dengeler.',
      'Accountable carrying balances excess fire by listening to the language of shoulders.',
      'Ответственное ношение уравновешивает избыточный огонь, слушая язык плеч.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['load', 'tooMuchFire', 'duty'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Yük kahramanlık oyunu ve çöküş korkusunda şişebilir veya ağırlık devredilemeyene dek paylaşımı bloke edebilir.',
      'Load may swell into excess hero-play and collapse-fear, or block sharing until the weight cannot be delegated.',
      'Ноша может раздуться в избыточную игру героя и страх обвала или блокировать делегирование, пока тяжесть нельзя поручить.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.blockedExpression,
    ],
    keywordIds: ['heroPlay', 'collapseFear', 'cannotDelegate'],
  ),
  symbolTags: [
    NarrativeSymbolTags.burden,
    NarrativeSymbolTags.accountability,
    NarrativeSymbolTags.release,
  ],
  profileRevision: 1,
);
