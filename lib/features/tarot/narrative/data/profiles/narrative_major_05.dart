/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeMajor05 = NarrativeCardProfile(
  canonicalCardId: 'major_05',
  coreMeaning: L10nTriple(
    'Aktarılan bilgiyi, ortak değerleri ve öğrenmeyi taşıyan yapılarla ilişkiyi anlatır.',
    'It concerns inherited knowledge, shared values, and our relationship with structures of learning.',
    'Карта связана с унаследованным знанием, общими ценностями и отношением к системам обучения.',
  ),
  light: L10nTriple(
    'Güvenilir bir öğreti, deneyimi anlamlandırmak için sağlam bir dil sunabilir.',
    'A trusted teaching can offer steady language for making sense of experience.',
    'Надежное учение может дать устойчивый язык для осмысления опыта.',
  ),
  shadow: L10nTriple(
    'Gelenek, sorgulanmadığında canlı anlayışın yerine kör uyumu koyabilir.',
    'When unquestioned, tradition can replace living understanding with automatic conformity.',
    'Если традицию не осмысливать, она может заменить живое понимание слепым соответствием.',
  ),
  tension: L10nTriple(
    'Aidiyet ihtiyacı ile kişisel doğruluğu koruma isteği arasında denge aranır.',
    'A balance is sought between the need to belong and the wish to remain personally truthful.',
    'Ищется равновесие между потребностью принадлежать и желанием сохранять личную правду.',
  ),
  desire: L10nTriple(
    'Kişi, deneyimini yerleştirebileceği anlamlı bir çerçeve ve rehberlik arayabilir.',
    'Guidance and a meaningful framework that can hold experience may be sought.',
    'Может появиться желание найти наставление и осмысленную рамку для своего опыта.',
  ),
  fear: L10nTriple(
    'Dışlanmak, yanlış yolu izlemek veya kendi değerlerinden uzaklaşmak kaygı yaratabilir.',
    'Exclusion, following the wrong path, or drifting from one\'s values may cause concern.',
    'Тревогу могут вызывать исключение, неверный путь или отдаление от собственных ценностей.',
  ),
  relationshipDynamic: L10nTriple(
    'Ortak ilkeleri görünür kılar; bağın ezberlerden çok karşılıklı anlamla kurulmasını ister.',
    'It makes shared principles visible and asks that connection rest on mutual meaning, not scripts.',
    'Карта проявляет общие принципы и предлагает строить связь на взаимном смысле, а не шаблонах.',
  ),
  decisionDynamic: L10nTriple(
    'Dışarıdan alınan öğüt, kişisel deneyim ve güncel koşullarla sınanmayı hak eder.',
    'Advice received from outside deserves to be tested against personal experience and present conditions.',
    'Совет, полученный со стороны, заслуживает проверки личным опытом и нынешними обстоятельствами.',
  ),
  actionDirection: L10nTriple(
    'Kaynağı sorun, özü öğrenin ve size artık hizmet etmeyen biçimi nazikçe bırakın.',
    'Ask about the source, learn the essence, and gently release forms that no longer serve.',
    'Уточните источник, усвойте суть и мягко отпустите формы, которые больше не помогают.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Yaşayan bir gelenek, deneyimi kısıtlamadan yön veren bilgelik sunabilir.',
      'A living tradition can offer wisdom that guides experience without confining it.',
      'Живая традиция может дать мудрость, направляющую опыт без его ограничения.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [
      NarrativeKeywordIds.teaching,
      NarrativeKeywordIds.tradition,
      NarrativeKeywordIds.values,
    ],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Öğreti içsel bir sorguya çekilebilir veya biçim, anlamın önüne geçebilir.',
      'Teaching may be privately questioned, or its form may overshadow its meaning.',
      'Учение может подвергнуться внутреннему сомнению, либо форма заслонит его смысл.',
    ),
    transforms: [
      ReversedTransformKind.privateInternal,
      ReversedTransformKind.distortion,
    ],
    keywordIds: [
      NarrativeKeywordIds.conformity,
      NarrativeKeywordIds.rigidity,
      NarrativeKeywordIds.learning,
    ],
  ),
  symbolTags: [
    NarrativeSymbolTags.teaching,
    NarrativeSymbolTags.tradition,
    NarrativeSymbolTags.values,
  ],
  profileRevision: 1,
);
