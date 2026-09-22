/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativePentacles05 = NarrativeCardProfile(
  canonicalCardId: 'pentacles_05',
  coreMeaning: L10nTriple(
    'Eşik dışında kalan maddeyi anlatır; yokluk hissi vardır, değer silinmiş değildir.',
    'Matter left outside the threshold; scarcity may be felt, but worth is not erased.',
    'Говорит о веществе за порогом; может чувствоваться нехватка, но достоинство не стёрто.',
  ),
  light: L10nTriple(
    'Dışarıda olmak, desteğin nerede kırıldığını görmeye alan açabilir.',
    'Being outside can make room to see where support has broken.',
    'Быть снаружи может дать место увидеть, где сломалась опора.',
  ),
  shadow: L10nTriple(
    'Kıtlık, utanca, kendini değersiz saymaya veya yardım istememeye kayabilir.',
    'Scarcity may slide into shame, counting oneself unworthy, or not asking for help.',
    'Нехватка может стать стыдом, ощущением недостойности или отказом просить помощи.',
  ),
  tension: L10nTriple(
    'İçeri alınma ihtiyacı ile dışarıda kalmış hissetme aynı anda durur.',
    'The need to be let in sits beside the feeling of remaining outside.',
    'Нужда быть впущенным соседствует с ощущением остаться снаружи.',
  ),
  desire: L10nTriple(
    'Kişi, yeniden eşikte yer bulmayı veya yükün hafiflemesini isteyebilir.',
    'Quietly, one may seek to find a place at the threshold again, or for the strain to ease.',
    'Может хотеться снова найти место у порога или чтобы напряжение ослабло.',
  ),
  fear: L10nTriple(
    'Görülmemek, dışlanmak veya yalnız taşımak kaygı yaratabilir.',
    'Going unseen, being shut out, or carrying alone may cause unease.',
    'Тревогу может вызывать остаться незамеченным, быть отсечённым или нести в одиночку.',
  ),
  relationshipDynamic: L10nTriple(
    'İki kişi arasında destek bulma zorluğu ortaya çıkabilir; ardından gelen utanç genellikle dışarıda bırakılmış olmanın sade gerçeğiyle pek ilgili değildir.',
    'Trouble finding support can show up between two people, and the shame that follows often has little to do with the plain fact of being shut out.',
    'Между двумя людьми может возникнуть трудность с поддержкой, и стыд, приходящий следом, часто мало связан с простым фактом оставленности снаружи.',
  ),
  decisionDynamic: L10nTriple(
    'Desteğin tam olarak nerede kırıldığını bulmak, yoksunluğu birinin değeri hakkında bir hükme çevirmekten daha faydalıdır.',
    'Finding exactly where support broke down helps more than turning scarcity into a verdict on someone\'s worth.',
    'Найти, где именно сломалась опора, полезнее, чем превращать нехватку в приговор чьей-то ценности.',
  ),
  actionDirection: L10nTriple(
    'Tam olarak nerede dışarıda durduğunuzu adlandırın ve değerinizi silmesine izin vermek yerine desteğe giden yolu kontrol edin.',
    'Name exactly where you are standing outside, and check the path back to support instead of letting it erase your worth.',
    'Назовите точно, где вы остаётесь снаружи, и проверьте путь обратно к поддержке, вместо того чтобы позволять этому стирать вашу ценность.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Dürüst bir kıtlık hissi, değeri eşik dışından ayırır.',
      'An honest sense of scarcity separates worth from being outside the door.',
      'Честное ощущение нехватки отделяет достоинство от положения за дверью.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['outsideThreshold', 'feltScarcity', 'strain'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Kıtlık utanca, değersizliğe veya yardım kapısını kapatmaya kayabilir.',
      'Scarcity may slide into shame, unworthiness, or closing the door to help.',
      'Нехватка может стать стыдом, недостойностью или закрытием двери к помощи.',
    ),
    transforms: [
      ReversedTransformKind.internalization,
      ReversedTransformKind.avoidance,
    ],
    keywordIds: ['shame', 'unworthiness', 'closedHelp'],
  ),
  symbolTags: [
    NarrativeSymbolTags.threshold,
    NarrativeSymbolTags.burden,
    NarrativeSymbolTags.belonging,
  ],
  profileRevision: 1,
);
