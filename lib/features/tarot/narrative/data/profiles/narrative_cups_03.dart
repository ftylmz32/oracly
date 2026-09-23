/// Narrative Tarot V2 Cups profile — seeded from Oracly deck meanings.
/// Phase 3B2: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeCups03 = NarrativeCardProfile(
  canonicalCardId: 'cups_03',
  coreMeaning: L10nTriple(
    'Üç kadehin sofrasını anlatır; yalnızlığın karşıtıdır, evlilik kehaneti değildir.',
    'A table of three cups; the opposite of solitude, not a marriage prophecy.',
    'Говорит о столе трёх чаш; противоположность одиночества, не пророчество брака.',
  ),
  light: L10nTriple(
    'Paylaşım, dostluk ve ortak neşe, sofra etrafında yumuşak bir bağ kurabilir.',
    'Sharing, friendship, and shared joy can weave a soft bond around the table.',
    'Обмен, дружба и общая радость могут сплести мягкую связь вокруг стола.',
  ),
  shadow: L10nTriple(
    'Sofrada yüzeysellik, dışlanma hissi veya gürültülü boşluk belirebilir.',
    'Surface cheer, a sense of exclusion, or noisy emptiness may appear at the table.',
    'За столом могут возникнуть поверхностность, чувство исключённости или шумная пустота.',
  ),
  tension: L10nTriple(
    'Birlikte olma arzusu ile her kadehi boşaltmama ihtiyacı çekişir.',
    'The wish to be together contends with the need not to empty every cup.',
    'Желание быть вместе спорит с нуждой не опустошать каждую чашу.',
  ),
  desire: L10nTriple(
    'Kişi, samimi bir paylaşım sofrasında yer almak isteyebilir.',
    'Quietly, one may seek to take a seat at a table of sincere sharing.',
    'Может хотеться занять место за столом искреннего обмена.',
  ),
  fear: L10nTriple(
    'Dışarıda kalmak, yüzeyde kalmak veya neşenin sahte görünmesi kaygı yaratabilir.',
    'Being left out, staying on the surface, or joy feeling staged may cause unease.',
    'Тревогу может вызывать исключённость, жизнь на поверхности или ощущение показной радости.',
  ),
  relationshipDynamic: L10nTriple(
    'Bu sofrada insanlar arasında bir paylaşım alanı açılabilir; odadaki her duyguyu tüketmeden bu alanın içinde oturmaya değer.',
    'A field of sharing can open between people at this table, worth sitting inside without needing to consume every feeling in the room.',
    'За этим столом между людьми может открыться поле обмена, в котором стоит просто находиться, не потребляя каждое чувство в комнате.',
  ),
  decisionDynamic: L10nTriple(
    'Önemli olan, bu sofradaki herkesin ana gerçekten ortak katılıp katılmadığıdır, kutlamayı tek kişinin kendi zaferi gibi sahiplenmesi değil.',
    'What matters is whether everyone at this table is actually sharing in the moment, rather than one person claiming the celebration as a solo win.',
    'Важно, действительно ли все за этим столом разделяют момент, а не то, что один человек присваивает праздник себе как личную победу.',
  ),
  actionDirection: L10nTriple(
    'Sofraya oturun ve çevrenizdeki paylaşımı fark edin; her kadehi boşaltmak yerine bazılarını dolu bırakın.',
    'Sit at the table and notice the sharing around you, leaving some cups still full rather than emptying every one.',
    'Сядьте за стол и заметьте обмен вокруг себя, оставляя часть чаш полными, а не опустошая каждую.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Samimi bir paylaşım, üç kadehi gürültüsüz bir sofrada buluşturur.',
      'Sincere sharing gathers three cups at a table without noise.',
      'Искренний обмен собирает три чаши за столом без шума.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [NarrativeKeywordIds.belonging, NarrativeKeywordIds.ending],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Paylaşım yüzeysel neşe ve dışlanmaya incelenebilir veya toplanmayı gürültülü boşluğa çarpıtabilir.',
      'Sharing may thin into deficient surface cheer and exclusion, or distort gathering into noisy emptiness.',
      'Обмен может истончиться до недостаточной поверхностной веселости и исключённости или исказить собрание в шумную пустоту.',
    ),
    transforms: [
      ReversedTransformKind.deficiency,
      ReversedTransformKind.distortion,
    ],
    keywordIds: [
      NarrativeKeywordIds.illusion,
      NarrativeKeywordIds.isolation,
      NarrativeKeywordIds.confusion,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.belonging,
    NarrativeSymbolTags.joy,
    NarrativeSymbolTags.nurture,
  ],
  profileRevision: 1,
);
