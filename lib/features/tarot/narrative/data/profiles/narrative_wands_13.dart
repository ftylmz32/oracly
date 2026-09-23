/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeWands13 = NarrativeCardProfile(
  canonicalCardId: 'wands_13',
  coreMeaning: L10nTriple(
    'Evin içindeki olgun ateşi anlatır; sahne ateşi değildir.',
    'Mature fire inside a house; not stage-fire.',
    'Говорит о зрелом огне внутри дома; не о сценическом огне.',
  ),
  light: L10nTriple(
    'İçselleşmiş sıcaklık, başkalarını yakmadan bir ocağı canlı tutabilir.',
    'Internalized warmth can keep a hearth alive without scorching others.',
    'Внутренняя теплота может держать очаг живым, не обжигая других.',
  ),
  shadow: L10nTriple(
    'Sıcaklık, kontrole, kıskançlığa veya sahiplenmeye kayabilir.',
    'Warmth may slide into control, envy, or possession.',
    'Теплота может стать контролем, завистью или присвоением.',
  ),
  tension: L10nTriple(
    'Ocağı canlı tutma arzusu ile kimseyi içine kapatmama sorumluluğu birlikte durur.',
    'The wish to keep the hearth alive coexists with the duty not to shut anyone inside it.',
    'Желание держать очаг живым соседствует с долгом никого в него не запирать.',
  ),
  desire: L10nTriple(
    'Kişi, olgun bir sıcaklığın güvenle paylaşılabildiği bir ev atmosferi isteyebilir.',
    'A household climate where mature warmth can be shared safely may be longed for.',
    'Может хотеться домашнего климата, где зрелую теплоту можно безопасно делить.',
  ),
  fear: L10nTriple(
    'Sönükleşmek, kıskanılmak veya sıcaklığın baskıya dönmesi kaygı yaratabilir.',
    'Dimming, being envied, or warmth turning into pressure may cause unease.',
    'Тревогу может вызывать угасание, зависть или превращение тепла в давление.',
  ),
  relationshipDynamic: L10nTriple(
    'Olgun bir sıcaklık bir bağın içinde yaşayabilir; bir davet, sahiplenmekten farklı kalır.',
    'A mature warmth can live inside a bond, and an invitation stays different from a claim of ownership.',
    'Зрелое тепло может жить внутри связи, и приглашение остаётся не тем же самым, что притязание на владение.',
  ),
  decisionDynamic: L10nTriple(
    'Ocağı canlı tutan ölçülü bir sıcaklık, seyirci için sahnelenen herhangi bir etkiden daha değerlidir.',
    'A measured warmth that keeps the hearth alive matters more than any effect staged for an audience.',
    'Сдержанное тепло, поддерживающее очаг живым, значит больше, чем любой эффект, разыгранный на публику.',
  ),
  actionDirection: L10nTriple(
    'Ocağı canlı tutun ve çevresindeki alanı koruyun; kapıyı kapatıp kimseyi içeri kilitlemek yerine açık bırakın.',
    'Keep the hearth alive and protect the space around it, leaving the door open rather than shutting anyone inside.',
    'Держите очаг живым и берегите пространство вокруг него, оставляя дверь открытой, а не запирая кого-то внутри.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Olgunlaşmış ev ateşi, sıcaklığı sahne olmadan içeride tutar ve paylaşır.',
      'Mature household fire holds and shares warmth inwardly without making a stage of it.',
      'Зрелый домашний огонь держит и делит теплоту внутри, не превращая её в сцену.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.nurture,
      NarrativeKeywordIds.mastery,
      NarrativeKeywordIds.opening,
    ],
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
    keywordIds: [
      NarrativeKeywordIds.control,
      NarrativeKeywordIds.envy,
      NarrativeKeywordIds.withdrawal,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.nurture,
    NarrativeSymbolTags.vitality,
    NarrativeSymbolTags.belonging,
  ],
  profileRevision: 1,
);
