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
    'It speaks of matter left outside the threshold; scarcity may be felt, but worth is not erased.',
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
    'There may be a wish to find a place at the threshold again, or for the strain to ease.',
    'Может хотеться снова найти место у порога или чтобы напряжение ослабло.',
  ),
  fear: L10nTriple(
    'Görülmemek, dışlanmak veya yalnız taşımak kaygı yaratabilir.',
    'Going unseen, being shut out, or carrying alone may cause unease.',
    'Тревогу может вызывать остаться незамеченным, быть отсечённым или нести в одиночку.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda destek zorluğu belirebilir; utancı dışarıda kalmış hissetmekten ayırmayı ister.',
    'Difficulty of support may appear in a bond; it asks to separate shame from feeling shut out.',
    'В связи может явиться трудность опоры; карта просит отделить стыд от ощущения отсечённости.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, yokluğu ahlak yargısı yapmak yerine nerede destek kırıldığını netleştirir.',
    'The choice clarifies where support broke rather than turning scarcity into a moral verdict.',
    'Выбор проясняет, где сломалась опора, а не превращает нехватку в моральный приговор.',
  ),
  actionDirection: L10nTriple(
    'Nerede dışarıda kaldığınızı adlandırın; değeri silmeyin, destek yolunu yoklayın.',
    'Name where you stand outside; do not erase worth — check the path to support.',
    'Назовите, где вы снаружи; не стирайте достоинство — проверьте путь к опоре.',
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
