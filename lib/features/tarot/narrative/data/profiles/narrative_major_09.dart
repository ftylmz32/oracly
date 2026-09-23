/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeMajor09 = NarrativeCardProfile(
  canonicalCardId: 'major_09',
  coreMeaning: L10nTriple(
    'Dış gürültüden çekilip deneyimi içeriden inceleyerek kişisel bir ışık bulmayı anlatır.',
    'Withdrawing from noise to examine experience and find a personal light.',
    'Карта говорит об уходе от шума ради осмысления опыта и поиска собственного света.',
  ),
  light: L10nTriple(
    'Bilinçli yalnızlık, ayrıntıları duymak ve sahici bir yön bulmak için alan açabilir.',
    'Intentional solitude can make room to hear nuance and find an authentic direction.',
    'Осознанное уединение дает пространство услышать тонкости и найти подлинное направление.',
  ),
  shadow: L10nTriple(
    'İçe dönüş, temas kurmaktan kaçınmaya veya yalnızlığı değişmez kimlik saymaya dönüşebilir.',
    'Reflection can become avoidance of contact or an identity built around isolation.',
    'Самоуглубление может стать избеганием контакта или устойчивой личностью, построенной на изоляции.',
  ),
  tension: L10nTriple(
    'Kendi cevabını aramak ile güvenilir desteği kabul etmek arasında bir eşik vardır.',
    'A threshold lies between seeking one\'s own answer and accepting trustworthy support.',
    'Существует порог между поиском собственного ответа и принятием надежной поддержки.',
  ),
  desire: L10nTriple(
    'Kişi, acele yanıtlar olmadan neyin gerçekten önemli olduğunu anlamak isteyebilir.',
    'Someone may long to understand what truly matters without rushed answers.',
    'Может появиться желание понять действительно важное без поспешных ответов.',
  ),
  fear: L10nTriple(
    'Kalabalıkta kendini kaybetmek veya geri çekildiğinde unutulmak endişesi belirebilir.',
    'There may be concern about losing oneself in company or being forgotten when apart.',
    'Может тревожить потеря себя среди других или страх быть забытым в уединении.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağ içinde düşünme alanı ister; mesafenin reddediş gibi yorumlanmamasını önemser.',
    'It asks for reflective space in connection and care that distance is not read as rejection.',
    'Карта просит пространства для размышления в отношениях и не принимать дистанцию за отвержение.',
  ),
  decisionDynamic: L10nTriple(
    'Kişisel ölçütlerin dış onaydan önce sessizce gözden geçirilmesi, burada gerçekten işe yarayan şeydir.',
    'Quietly reviewing personal criteria before seeking outside approval is what actually helps here.',
    'Тихая проверка личных критериев до поиска внешнего одобрения — вот что здесь действительно помогает.',
  ),
  actionDirection: L10nTriple(
    'Kısa bir yalnızlık alanı kurun, temel soruyu yazın ve cevabı zorlamayın.',
    'Create a brief period of solitude, write the essential question, and do not force an answer.',
    'Выделите время для уединения, запишите главный вопрос и не принуждайте ответ.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sade bir geri çekiliş, deneyimi olgunlaştıran içgörü ve yön duygusu getirir.',
      'A simple retreat brings insight and direction that allow experience to mature.',
      'Спокойное уединение приносит понимание и направление, позволяя опыту созреть.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.solitude,
      NarrativeKeywordIds.wisdom,
      NarrativeKeywordIds.inquiry,
    ],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Yalnızlık uzayabilir, içgörü paylaşılmayabilir veya geri çekilme kaçışa dönüşebilir.',
      'Solitude may linger, insight may remain private, or retreat may become escape.',
      'Уединение может затянуться, понимание остаться личным, а отступление превратиться в бегство.',
    ),
    transforms: [
      ReversedTransformKind.privateInternal,
      ReversedTransformKind.avoidance,
    ],
    keywordIds: [
      NarrativeKeywordIds.isolation,
      NarrativeKeywordIds.withdrawal,
      NarrativeKeywordIds.silence,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.solitude,
    NarrativeSymbolTags.wisdom,
    NarrativeSymbolTags.inquiry,
  ],
  profileRevision: 1,
);
