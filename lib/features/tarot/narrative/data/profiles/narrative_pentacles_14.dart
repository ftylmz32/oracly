/// Narrative Tarot V2 Pentacles profile — seeded from Oracly deck meanings.
/// Phase 3B4: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativePentacles14 = NarrativeCardProfile(
  canonicalCardId: 'pentacles_14',
  coreMeaning: L10nTriple(
    'Sorumlu maddeyi anlatır; yalnızca bakmak değil, yön ve hesap verebilirlik tutmaktır.',
    'The center is responsible matter — holding direction and accountability, rather than care alone.',
    'Говорит об ответственном веществе; не об одной заботе, а об удержании направления и подотчётности.',
  ),
  light: L10nTriple(
    'Hesap verebilir bir el, kaynakları net sınırlarla yönlendirebilir.',
    'An accountable hand can guide resources with clear bounds.',
    'Подотчётная рука может направлять ресурсы с ясными границами.',
  ),
  shadow: L10nTriple(
    'Sorumluluk, baskıya, katı otoriteye veya yükü başkasına atmaya kayabilir.',
    'Pressure, rigid authority, or casting the load onto others appears when Responsibility dominates.',
    'Ответственность может стать давлением, жёсткой властью или сбрасыванием нагрузки на других.',
  ),
  tension: L10nTriple(
    'Yön tutma isteği ile bakımı boğmama ihtiyacı çekişir.',
    'The wish to hold direction contends with the need not to smother care.',
    'Желание держать направление спорит с нуждой не удушить заботу.',
  ),
  desire: L10nTriple(
    'Kişi, maddenin güvenilir ve hesaplı durmasını isteyebilir.',
    'Someone may long for matter to stand reliable and accountable.',
    'Может хотеться, чтобы вещество стояло надёжным и подотчётным.',
  ),
  fear: L10nTriple(
    'Kontrolü kaybetmek veya hesap verememek kaygı yaratabilir.',
    'Losing control, or failing to account, may cause unease.',
    'Тревогу может вызывать потеря контроля или неспособность отчитаться.',
  ),
  relationshipDynamic: L10nTriple(
    'Bir bağa maddi bir yön duygusu girebilir; hesap verebilir olmak, tek başına bakımdan daha fazlasını taşır.',
    'A sense of material direction can enter a bond, where being accountable is worth more than care by itself.',
    'В связь может войти чувство вещественного направления, где быть подотчётным значит больше, чем одна лишь забота.',
  ),
  decisionDynamic: L10nTriple(
    'Kimin gerçekten neyden sorumlu olduğunu adlandırmak, burada tek başına vekillikten daha önemlidir.',
    'Naming who actually answers for what matters more here than stewardship on its own.',
    'Назвать, кто на самом деле за что отвечает, здесь важнее одного лишь попечения.',
  ),
  actionDirection: L10nTriple(
    'Sorumluluğu açıkça adlandırın ve oradan yön tutun; baskının gerçek otoriteyle karıştırılmamasına dikkat ederek.',
    'Name the responsibility clearly and hold direction from there, watching that pressure never gets mistaken for real authority.',
    'Ясно назовите ответственность и держите направление, исходя из неё, следя, чтобы давление не приняли за настоящую власть.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Hesap verebilir yön, maddeyi baskıdan ve bakımsızlıktan ayırır.',
      'Accountable direction separates matter from pressure and from neglect.',
      'Подотчётное направление отделяет вещество от давления и от запустения.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['rootedMeans', 'accountability', 'materialDirection'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Sorumluluk baskı ve katı otoritede şişebilir veya yükü başkasına yönlendirerek sapabilir.',
      'Responsibility may swell into excess pressure and rigid authority, or misdirect the load onto others.',
      'Ответственность может раздуться в избыточное давление и жёсткую власть или сбить нагрузку на других.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.misdirection,
    ],
    keywordIds: ['rigidAuthority', 'pressure', 'castLoad'],
  ),
  symbolTags: [
    NarrativeSymbolTags.accountability,
    NarrativeSymbolTags.structure,
    NarrativeSymbolTags.authority,
  ],
  profileRevision: 1,
);
