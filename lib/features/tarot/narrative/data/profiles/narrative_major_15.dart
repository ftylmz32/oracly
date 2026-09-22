/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeMajor15 = NarrativeCardProfile(
  canonicalCardId: 'major_15',
  coreMeaning: L10nTriple(
    'Haz, korku veya alışkanlıkla güçlenen bağları ve kişinin onlardaki payını görünür kılar.',
    'It makes visible bonds strengthened by pleasure, fear, or habit and one\'s part in them.',
    'Карта проявляет связи, усиленные удовольствием, страхом или привычкой, и участие человека в них.',
  ),
  light: L10nTriple(
    'Bağımlı örüntüyü dürüstçe görmek, seçim gücünün hâlâ bulunduğunu hatırlatabilir.',
    'Seeing an attached pattern honestly can reveal that some power of choice remains.',
    'Честный взгляд на зависимый узор напоминает, что способность выбирать еще сохраняется.',
  ),
  shadow: L10nTriple(
    'Yoğun arzu, kısa rahatlık uğruna sınırları ve uzun vadeli bedeli görünmez kılabilir.',
    'Intense desire can obscure boundaries and long-term cost for immediate relief.',
    'Сильное желание может скрыть границы и долгосрочную цену ради мгновенного облегчения.',
  ),
  tension: L10nTriple(
    'İstenen haz ile onun yarattığı kısıt arasındaki çelişki belirginleşir.',
    'The contradiction between desired pleasure and the restriction it creates becomes clear.',
    'Проявляется противоречие между желанным удовольствием и создаваемым им ограничением.',
  ),
  desire: L10nTriple(
    'Kişi, yoğunluk, güvence veya boşluğu hızla susturan bir yakınlık arayabilir.',
    'There may be a wish for intensity, reassurance, or closeness that quickly quiets emptiness.',
    'Может хотеться интенсивности, уверенности или близости, быстро заглушающей пустоту.',
  ),
  fear: L10nTriple(
    'Kontrol edilen şeyi bırakınca yoksun kalmak veya gerçekle yüzleşmek korkutabilir.',
    'Letting go of a controlled comfort and facing what remains may feel frightening.',
    'Может пугать отказ от управляемого утешения и встреча с тем, что останется.',
  ),
  relationshipDynamic: L10nTriple(
    'Çekim ile sahiplenmeyi ayırır; rıza, sınır ve karşılıklı özgürlüğü öne çıkarır.',
    'It separates attraction from possession and centers consent, boundaries, and mutual freedom.',
    'Карта отделяет притяжение от обладания и ставит в центр согласие, границы и взаимную свободу.',
  ),
  decisionDynamic: L10nTriple(
    'Karar, anlık ödülün yanında tekrar eden bedeli de açıkça hesaba katmalıdır.',
    'The decision must account for recurring cost alongside immediate reward.',
    'Решение должно учитывать повторяющуюся цену наряду с мгновенной выгодой.',
  ),
  actionDirection: L10nTriple(
    'Bağın nasıl sürdüğünü gözleyin, tetikleyiciyi adlandırın ve erişilebilir bir sınır koyun.',
    'Observe how the bond is maintained, name the trigger, and set one reachable boundary.',
    'Проследите, как поддерживается привязка, назовите пусковой фактор и установите доступную границу.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bağlılığın açıkça görülmesi, arzuyla daha özgür ve sorumlu ilişki kurma fırsatı verir.',
      'Clear recognition of attachment offers a chance to relate to desire more freely and responsibly.',
      'Ясное признание привязанности дает шанс свободнее и ответственнее обращаться с желанием.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['attachment', 'desire', 'bondage'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bağ gevşeyebilir, arzu içe çekilebilir veya eski örüntü başka biçimde sürebilir.',
      'The bond may loosen, desire turn inward, or the old pattern continue in another form.',
      'Связь может ослабнуть, желание уйти внутрь, а прежний узор — продолжиться в иной форме.',
    ),
    transforms: [
      ReversedTransformKind.release,
      ReversedTransformKind.internalization,
    ],
    keywordIds: ['release', 'denial', 'compulsion'],
  ),
  symbolTags: [
    NarrativeSymbolTags.attachment,
    NarrativeSymbolTags.desire,
    NarrativeSymbolTags.bondage,
  ],
  profileRevision: 1,
);
