/// Narrative Tarot V2 Swords profile — seeded from Oracly deck meanings.
/// Phase 3B3: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeSwords03 = NarrativeCardProfile(
  canonicalCardId: 'swords_03',
  coreMeaning: L10nTriple(
    'Keskin bir üzüntüyü anlatır; tiyatro değildir, acılı bir netlik alanıdır.',
    'Sharp sorrow is not theatre; it is a field of painful clarity.',
    'Говорит об острой печали; не о театре, а о поле больной ясности.',
  ),
  light: L10nTriple(
    'Acıyı adlandırmak, sahne kurmadan gerçeği taşımaya alan açabilir.',
    'Naming pain can make room to carry truth without staging it.',
    'Называть боль может дать место нести правду, не ставя её на сцену.',
  ),
  shadow: L10nTriple(
    'Üzüntü dramatik acıya, suçlamaya veya kapanmamaya kayabilir.',
    'Sorrow turns brittle when it becomes dramatic pain, blame, or staying unclosed.',
    'Печаль может стать драматической болью, обвинением или незакрытостью.',
  ),
  tension: L10nTriple(
    'Gerçeği görmek ile onu sahne yapmama ihtiyacı birlikte durur.',
    'Seeing the truth coexists with the need not to stage it.',
    'Видение правды соседствует с нуждой не ставить её на сцену.',
  ),
  desire: L10nTriple(
    'Kişi, kırık ama duru bir yeri sessizce tanımak isteyebilir.',
    'Quietly recognizing a place both broken and still clear may be needed.',
    'Может хотеться тихо узнать место и сломанное, и всё ещё ясное.',
  ),
  fear: L10nTriple(
    'Acının kimlik olması veya inciten gerçeğin büyümesi kaygı yaratabilir.',
    'Pain becoming identity, or a hurting truth growing, may cause unease.',
    'Тревогу может вызывать превращение боли в личность или рост ранящей правды.',
  ),
  relationshipDynamic: L10nTriple(
    'İki kişi arasında inciten bir gerçek söylenebilir; olanı adlandırmak, suçlamakla aynı şey değildir.',
    'A hurting truth can be spoken between two people, and naming what happened is not the same as assigning blame.',
    'Между двумя людьми может прозвучать ранящая правда, и назвать случившееся — не то же самое, что обвинить.',
  ),
  decisionDynamic: L10nTriple(
    'Burada gerçekten kırılmış olan, acının herhangi bir gösterişli versiyonundan daha fazla ilgiyi hak eder.',
    'What is actually broken here deserves more attention than any theatrical version of the pain.',
    'То, что здесь действительно сломано, заслуживает больше внимания, чем любая театральная версия боли.',
  ),
  actionDirection: L10nTriple(
    'Acıyı sade biçimde adlandırın ve bu adlandırmanın yetmesine izin verin; onu bir gösteriye dönüştürmeden.',
    'Name the pain plainly and let that naming be enough, without turning it into a performance.',
    'Назовите боль просто и позвольте этому названию быть достаточным, не превращая его в представление.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Adlandırılan üzüntü, tiyatrosuz bir netlik taşır.',
      'Named sorrow carries clarity without theatre.',
      'Названная печаль несёт ясность без театра.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.truth,
      NarrativeKeywordIds.clarity,
      NarrativeKeywordIds.boundary,
    ],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Üzüntü dramatik acı ve suçlamada taşabilir veya kapanmayı sonsuz açık bırakmaya çarpıtabilir.',
      'Sorrow may tip into excess drama and blame, or distort closure into staying forever unclosed.',
      'Печаль может перейти в избыточную драму и обвинение или исказить закрытие в вечную незакрытость.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.distortion,
    ],
    keywordIds: [
      NarrativeKeywordIds.grief,
      NarrativeKeywordIds.projection,
      NarrativeKeywordIds.closing,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.grief,
    NarrativeSymbolTags.truth,
    NarrativeSymbolTags.clarity,
  ],
  profileRevision: 1,
);
