/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeWands07 = NarrativeCardProfile(
  canonicalCardId: 'wands_07',
  coreMeaning: L10nTriple(
    'Tek noktadan korunan kıvılcımı ve sınır tutan bir duruşu anlatır.',
    'A spark guarded from one point and a stance that holds a boundary.',
    'Говорит об искре, охраняемой с одной точки, и о стойке, держащей границу.',
  ),
  light: L10nTriple(
    'Net bir sınır, ateşi savurmadan yerini koruyan sakin bir omurga olabilir.',
    'A clear boundary can be a calm spine that holds ground without scattering fire.',
    'Ясная граница может быть спокойным хребтом, держащим место, не разбрасывая огонь.',
  ),
  shadow: L10nTriple(
    'Duruş, kuşatma hissi, sertlik veya herkese karşı savaş gibi okunabilir.',
    'Stance may be read as siege-feeling, harshness, or war against everyone.',
    'Стойка может читаться как ощущение осады, жёсткость или война со всеми.',
  ),
  tension: L10nTriple(
    'Yerini tutma ihtiyacı ile düşman üretmeme sorumluluğu birlikte durur.',
    'The need to hold ground coexists with the duty not to manufacture enemies.',
    'Нужда держать место соседствует с долгом не производить врагов.',
  ),
  desire: L10nTriple(
    'Kişi, baskı altında bile \'ben buradayım\' diyebilecek bir duruş isteyebilir.',
    'What is wanted is a stance that can still say \'I am here\' under pressure.',
    'Может хотеться стойки, способной даже под давлением сказать «я здесь».',
  ),
  fear: L10nTriple(
    'Yalnız kalmak, sınırın çökmesi veya her teması tehdit saymak kaygı yaratabilir.',
    'Being alone, a collapsing boundary, or treating every contact as threat may cause unease.',
    'Тревогу может вызывать одиночество, обвал границы или чтение каждого контакта как угрозы.',
  ),
  relationshipDynamic: L10nTriple(
    'İlişkide kendini anlatma ihtiyacı artabilir; sınırı düşmanlık olmadan kurmayı ister.',
    'A need to speak for oneself may rise in a bond; it asks for boundary without enmity.',
    'В связи может усилиться нужда говорить за себя; карта просит границу без вражды.',
  ),
  decisionDynamic: L10nTriple(
    'Karar, korunacak gerçek sınırı belirginleştirir; her itirazı saldırı saymaz.',
    'The decision clarifies which boundary truly needs guarding; not every push is an attack.',
    'Решение проясняет, какую границу действительно нужно охранять; не каждый толчок — атака.',
  ),
  actionDirection: L10nTriple(
    'Yerinizi tutun, sınırı netleştirin; düşman üretmeyin.',
    'Hold your ground, clarify the boundary; do not manufacture enemies.',
    'Держите место, проясните границу; не производите врагов.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Tek noktadan tutulan ateş, gereksiz kuşatma yaratmadan sınırı korur.',
      'Fire held from one point protects a boundary without inventing a siege.',
      'Огонь, удерживаемый с одной точки, охраняет границу, не изобретая осаду.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['stance', 'boundary', 'fireAlone'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Duruş kuşatma hissine, sertliğe veya izolasyona kayabilir.',
      'Stance may slide into siege-feeling, harshness, or isolation.',
      'Стойка может стать ощущением осады, жёсткостью или изоляцией.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.privateInternal,
    ],
    keywordIds: ['siegeFeeling', 'harshness', 'isolation'],
  ),
  symbolTags: [
    NarrativeSymbolTags.restraint,
    NarrativeSymbolTags.courage,
    NarrativeSymbolTags.solitude,
  ],
  profileRevision: 1,
);
