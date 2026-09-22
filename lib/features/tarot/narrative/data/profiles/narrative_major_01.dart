/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeMajor01 = NarrativeCardProfile(
  canonicalCardId: 'major_01',
  coreMeaning: L10nTriple(
    'Niyet, beceri ve mevcut araçları bilinçli bir üretime yöneltme kapasitesini gösterir.',
    'It reflects the capacity to direct intention, skill, and available tools into conscious work.',
    'Карта отражает способность направлять намерение, навык и доступные средства в осознанный труд.',
  ),
  light: L10nTriple(
    'Odaklanan yetenek, soyut bir fikri elle tutulur bir başlangıca çevirebilir.',
    'Focused ability can turn an abstract idea into a tangible beginning.',
    'Сосредоточенное умение может превратить отвлеченную идею в осязаемое начало.',
  ),
  shadow: L10nTriple(
    'Etkileme gücü, açıklık yerine kontrol veya gösteriş için kullanılabilir.',
    'The power to influence can be used for control or display rather than clarity.',
    'Способность влиять может служить контролю или показности вместо ясности.',
  ),
  tension: L10nTriple(
    'Potansiyeli kanıtlama isteği ile sabırlı ustalık arasında bir çekişme vardır.',
    'There is tension between proving potential and practicing patient mastery.',
    'Возникает напряжение между желанием доказать потенциал и терпеливым мастерством.',
  ),
  desire: L10nTriple(
    'Kişi, kendi emeğinin sonuç üzerinde gerçek bir iz bıraktığını görmek isteyebilir.',
    'There may be a wish to see one\'s own effort leave a real mark on the outcome.',
    'Может хотеться увидеть, что собственный труд действительно повлиял на результат.',
  ),
  fear: L10nTriple(
    'Yetersiz araçlara sahip olma veya yeteneğini doğru kullanamama endişesi belirebilir.',
    'A concern may arise about lacking tools or failing to use ability well.',
    'Может проявиться страх нехватки средств или неумения верно применить способности.',
  ),
  relationshipDynamic: L10nTriple(
    'İletişimde inisiyatif ve çekim yaratır; karşılıklı etkiyi dürüst tutmayı ister.',
    'It creates initiative and attraction in connection while asking influence to remain honest.',
    'В отношениях карта усиливает инициативу и притяжение, призывая сохранять честность влияния.',
  ),
  decisionDynamic: L10nTriple(
    'Karar, elde olan kaynakları net bir amaç çevresinde toplamaktan güç kazanır.',
    'A decision gains strength when existing resources gather around a clear purpose.',
    'Решение крепнет, когда имеющиеся ресурсы объединены вокруг ясной цели.',
  ),
  actionDirection: L10nTriple(
    'Niyetinizi sadeleştirin, bir araç seçin ve dikkatinizi tamamlanabilir işe verin.',
    'Simplify your intention, choose one tool, and focus on work you can complete.',
    'Упростите намерение, выберите один инструмент и сосредоточьтесь на выполнимой работе.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Beceri ile niyet uyumlandığında, yaratıcı güç somut ve sorumlu biçimde akar.',
      'When skill aligns with intention, creative power moves in a concrete and responsible way.',
      'Когда навык согласуется с намерением, творческая сила проявляется предметно и ответственно.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['craft', 'focus', 'agency'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Yetenek dağılabilir, içe kapanabilir ya da amacı belirsiz bir etkiye dönüşebilir.',
      'Ability may scatter, turn inward, or become influence without a clear purpose.',
      'Способность может рассеяться, уйти внутрь или стать влиянием без ясной цели.',
    ),
    transforms: [
      ReversedTransformKind.blockedExpression,
      ReversedTransformKind.distortion,
    ],
    keywordIds: ['scatter', 'control', 'doubt'],
  ),
  symbolTags: [
    NarrativeSymbolTags.craft,
    NarrativeSymbolTags.focus,
    NarrativeSymbolTags.agency,
  ],
  profileRevision: 1,
);
