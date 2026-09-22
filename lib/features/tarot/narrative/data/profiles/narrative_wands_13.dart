/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeWands13 = NarrativeCardProfile(
  canonicalCardId: 'wands_13',
  coreMeaning: L10nTriple(
    'Evin içindeki olgun ateşi anlatır; sahne ateşi değildir.',
    'The card holds mature fire inside a house, not stage-fire.',
    'Говорит о зрелом огне внутри дома; не о сценическом огне.',
  ),
  light: L10nTriple(
    'İçselleşmiş sıcaklık, başkalarını yakmadan bir ocağı canlı tutabilir.',
    'Internalized warmth can keep a hearth alive without scorching others.',
    'Внутренняя теплота может держать очаг живым, не обжигая других.',
  ),
  shadow: L10nTriple(
    'Sıcaklık, kontrole, kıskançlığa veya sahiplenmeye kayabilir.',
    'Pushed too far, warmth yields control, envy, or possession.',
    'Теплота может стать контролем, завистью или присвоением.',
  ),
  tension: L10nTriple(
    'Ocağı canlı tutma arzusu ile kimseyi içine kapatmama sorumluluğu birlikte durur.',
    'The wish to keep the hearth alive coexists with the duty not to shut anyone inside it.',
    'Желание держать очаг живым соседствует с долгом никого в него не запирать.',
  ),
  desire: L10nTriple(
    'Kişi, olgun bir sıcaklığın güvenle paylaşılabildiği bir ev atmosferi isteyebilir.',
    'The energy leans toward a household climate where mature warmth can be shared safely.',
    'Может хотеться домашнего климата, где зрелую теплоту можно безопасно делить.',
  ),
  fear: L10nTriple(
    'Sönükleşmek, kıskanılmak veya sıcaklığın baskıya dönmesi kaygı yaratabilir.',
    'Dimming, being envied, or warmth turning into pressure may cause unease.',
    'Тревогу может вызывать угасание, зависть или превращение тепла в давление.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda olgun bir sıcaklık barınabilir; daveti sahiplenmeden ayırmayı ister.',
    'Mature warmth may dwell in a bond; it asks to separate invitation from possession.',
    'В связи может жить зрелая теплота; карта просит отделить приглашение от присвоения.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, sahne etkisi yerine ocağı sürdüren ölçülü bir sıcaklığı gözetir.',
    'The choice favors measured warmth that sustains a hearth rather than stage effect.',
    'Выбор хранит сдержанную теплоту, поддерживающую очаг, а не сценический эффект.',
  ),
  actionDirection: L10nTriple(
    'Ocağı canlı tutun, alanı koruyun; kimseyi içine kapatmayın.',
    'Keep the hearth alive, protect the space; do not shut anyone inside it.',
    'Держите очаг живым, берегите пространство; никого в него не запирайте.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Olgunlaşmış ev ateşi, sıcaklığı sahne olmadan içeride tutar ve paylaşır.',
      'Mature household fire holds and shares warmth inwardly without making a stage of it.',
      'Зрелый домашний огонь держит и делит теплоту внутри, не превращая её в сцену.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['warmHouse', 'matureFire', 'invitation'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Ev ateşi kontrole, kıskançlığa veya sönükleşmeye kayabilir.',
      'Household fire may slide into control, envy, or dimming.',
      'Домашний огонь может стать контролем, завистью или угасанием.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.distortion,
    ],
    keywordIds: ['control', 'envy', 'dimming'],
  ),
  symbolTags: [
    NarrativeSymbolTags.nurture,
    NarrativeSymbolTags.vitality,
    NarrativeSymbolTags.belonging,
  ],
  profileRevision: 1,
);
