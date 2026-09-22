/// Narrative Tarot V2 Swords profile — seeded from Oracly deck meanings.
/// Phase 3B3: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeSwords08 = NarrativeCardProfile(
  canonicalCardId: 'swords_08',
  coreMeaning: L10nTriple(
    'Kendi düşüncesiyle sarılı zihni anlatır; hissedilen bir bağdır, iki seçenek kilidi değil.',
    'A mind wrapped in its own thought; a felt bind, not a two-option lock.',
    'Говорит об уме, обмотанном собственной мыслью; об ощущаемой связи, не о замке двух вариантов.',
  ),
  light: L10nTriple(
    'Bağı fark etmek, henüz kesmeden çıkışın varlığını yoklamaya alan açabilir.',
    'Noticing the bind can make room to test that a door may exist without cutting yet.',
    'Замечать связь может дать место проверить, что дверь может быть, ещё не разрезая.',
  ),
  shadow: L10nTriple(
    'Sıkışma kurban hikâyesine, hareketsizliğe veya korku ağına kayabilir.',
    'When unbalanced, Tightness becomes a victim story, immobility, or a web of fear.',
    'Теснота может стать историей жертвы, неподвижностью или сетью страха.',
  ),
  tension: L10nTriple(
    'Çıkışsızlık hissi ile gerçek dış kısıtı ayırma ihtiyacı birlikte durur.',
    'The felt sense of no-exit coexists with the need to separate it from a real outer limit.',
    'Ощущение безвыходности соседствует с нуждой отделить его от реального внешнего предела.',
  ),
  desire: L10nTriple(
    'Kişi, kendi kurduğu ağdan serbest bir nefes almak isteyebilir.',
    'There may be a wish to take a freer breath from a web one built oneself.',
    'Может хотеться более свободного дыхания от сети, которую сплели сами.',
  ),
  fear: L10nTriple(
    'Kapının gerçekten yok olması veya hareketin imkânsız kalması kaygı yaratabilir.',
    'There truly being no door, or motion staying impossible, may cause unease.',
    'Тревогу может вызывать то, что двери действительно нет, или движение остаётся невозможным.',
  ),
  relationshipDynamic: L10nTriple(
    'Bir bağın içinde çıkışsızlık hissi doğabilir; gerçek kısıtlama, sonunda yalnızca iki anahtarlı bir kilitten daha küçük çıksa bile.',
    'A sense of no-exit can be felt inside a bond, even when the real restriction turns out to be smaller than a lock with only two keys.',
    'Внутри связи может ощущаться безвыходность, даже если настоящее ограничение в итоге окажется меньше, чем замок всего с двумя ключами.',
  ),
  decisionDynamic: L10nTriple(
    'Burada gerçekten kısıtlanmış olan, gece kaygısının ona eklediklerinden ayrı olarak sınanmaya değer.',
    'What is actually constrained here is worth testing separately from whatever night worry has added to it.',
    'То, что здесь действительно ограничено, стоит проверить отдельно от того, что добавила к этому ночная тревога.',
  ),
  actionDirection: L10nTriple(
    'Neyin gerçekten kısıtlandığını fark edin; henüz kesmek zorunda değilsiniz.',
    'Notice what is actually constrained; you do not have to cut yet.',
    'Заметьте, что действительно ограничено; ещё не обязательно разрезать.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Fark edilen bağ, sıkışmayı dış hapis sanmadan tutar.',
      'A noticed bind holds tightness without mistaking it for outer prison.',
      'Замеченная связь держит тесноту, не принимая её за внешнюю тюрьму.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['tightness', 'boundMind', 'ownSword'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sıkışma kurban hikâyesine içe çekilebilir veya korku hareketsizliği örene dek ifadeyi engelleyebilir.',
      'Tightness may internalize into a victim story, or block movement until fear weaves immobility.',
      'Теснота может уйти внутрь в историю жертвы или заблокировать движение, пока страх не сплетёт неподвижность.',
    ),
    transforms: [
      ReversedTransformKind.internalization,
      ReversedTransformKind.blockedExpression,
    ],
    keywordIds: ['victimStory', 'immobility', 'fearWeb'],
  ),
  symbolTags: [
    NarrativeSymbolTags.bondage,
    NarrativeSymbolTags.restraint,
    NarrativeSymbolTags.perspective,
  ],
  profileRevision: 1,
);
