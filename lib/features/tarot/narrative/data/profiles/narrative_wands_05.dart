/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeWands05 = NarrativeCardProfile(
  canonicalCardId: 'wands_05',
  coreMeaning: L10nTriple(
    'Kıvılcımın sınandığı yeri gösterir; ateş kaybolmuş değildir.',
    'It shows where the spark is tested; the fire is not gone.',
    'Показывает место испытания искры; огонь не исчез.',
  ),
  light: L10nTriple(
    'Onurlu sürtünme, iradeyi yakmadan güçlendiren bir sınav olabilir.',
    'Honorable friction can be a trial that strengthens will without burning it.',
    'Честное трение может быть испытанием, укрепляющим волю, не сжигая её.',
  ),
  shadow: L10nTriple(
    'Sınav, düşman hikâyesine, öfkeye veya yenilgi anlatısına kayabilir.',
    'The trial turns brittle when it becomes an enemy story, anger, or a defeat narrative.',
    'Испытание может стать историей врага, гневом или повестью о поражении.',
  ),
  tension: L10nTriple(
    'Ayakta kalma ateşi ile kimseyi yakmama sorumluluğu aynı anda durur.',
    'The fire of standing firm coexists with the duty not to burn anyone.',
    'Огонь стойкости соседствует с долгом никого не сжигать.',
  ),
  desire: L10nTriple(
    'Kişi, sürtünmede bile onurunu koruyarak ayakta kalmak isteyebilir.',
    'Staying standing with honor even inside friction may matter.',
    'Может хотеться устоять с честью даже внутри трения.',
  ),
  fear: L10nTriple(
    'Ezilmek, öfkeye kapılmak veya her çatışmayı kişisel savaş saymak kaygı yaratabilir.',
    'Being crushed, seized by anger, or reading every clash as personal war may cause unease.',
    'Тревогу может вызывать страх быть раздавленным, вспыхнуть гневом или читать каждый спор как личную войну.',
  ),
  relationshipDynamic: L10nTriple(
    'İnsanlar arasındaki gerilim bir onur meselesine dönüşebilir; bir yarışmanın düşmanlığa dönüşmesi şart değildir.',
    'Tension between people can turn into a matter of honor, and a contest need not curdle into enmity.',
    'Напряжение между людьми может стать делом чести; состязание не обязано превращаться во вражду.',
  ),
  decisionDynamic: L10nTriple(
    'Bu sınavda onur ve gerçek konu, yalnızca kazanmaktan daha önemlidir.',
    'Honor and the real subject of this trial matter more here than simply winning.',
    'Честь и подлинный предмет этого испытания значат здесь больше, чем просто победа.',
  ),
  actionDirection: L10nTriple(
    'Onurunuzu koruyun ve gerçek sürtüşmeyi, kimseyi yakmadan adlandırın.',
    'Protect your honor and name the real friction without letting it burn anyone.',
    'Берегите свою честь и назовите подлинное трение, никого им не обжигая.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Onurlu bir sınav, kıvılcımı yok etmeden iradeyi sınar ve netleştirir.',
      'An honorable trial tests and clarifies will without extinguishing the spark.',
      'Честное испытание проверяет и проясняет волю, не гася искру.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.strain,
      NarrativeKeywordIds.discord,
      NarrativeKeywordIds.values,
    ],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sürtünme yenilgi hikâyesine, öfkeye veya erken vazgeçişe dönüşebilir.',
      'Friction may become a defeat-story, anger, or early giving up.',
      'Трение может стать историей поражения, гневом или ранней сдачей.',
    ),
    transforms: [
      ReversedTransformKind.distortion,
      ReversedTransformKind.excess,
    ],
    keywordIds: [NarrativeKeywordIds.despair, NarrativeKeywordIds.anger],
  ),
  symbolTags: [
    NarrativeSymbolTags.courage,
    NarrativeSymbolTags.friction,
    NarrativeSymbolTags.will,
  ],
  profileRevision: 1,
);
