/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeMajor13 = NarrativeCardProfile(
  canonicalCardId: 'major_13',
  coreMeaning: L10nTriple(
    'Tamamlanan bir biçimin bırakılmasıyla dönüşüm ve yeni alan oluşmasını temsil eder.',
    'It represents transformation and new space created by releasing a form that has ended.',
    'Карта означает преобразование и новое пространство, возникающее после отпускания завершившейся формы.',
  ),
  light: L10nTriple(
    'Dürüst bir vedalaşma, tükenmiş olanı taşımadan yenilenmeye yer açabilir.',
    'An honest farewell can make room for renewal without carrying what is exhausted.',
    'Честное прощание освобождает место обновлению без ноши того, что исчерпано.',
  ),
  shadow: L10nTriple(
    'Değişim korkusu, işlevini yitirmiş bağları ve kimlikleri gereğinden fazla uzatabilir.',
    'Fear of change can prolong bonds and identities that no longer function.',
    'Страх перемен может чрезмерно продлевать связи и роли, утратившие свое назначение.',
  ),
  tension: L10nTriple(
    'Tanıdık olanı koruma isteği ile dönüşümün gerektirdiği kayıp karşı karşıyadır.',
    'The wish to preserve the familiar faces the loss required by transformation.',
    'Желание сохранить знакомое сталкивается с утратой, необходимой для преобразования.',
  ),
  desire: L10nTriple(
    'Kişi, ağırlaşmış bir dönemi kapatıp daha dürüst bir yaşam alanı isteyebilir.',
    'A longing to close a burdensome chapter and inhabit a truer space may surface.',
    'Может возникнуть желание завершить тяжелый этап и перейти в более честное пространство жизни.',
  ),
  fear: L10nTriple(
    'Bırakmanın geri döndürülemez olması veya sonrasında boşlukla kalmak ürkütebilir.',
    'The irreversibility of letting go or the emptiness afterward may feel unsettling.',
    'Может пугать необратимость отпускания или пустота, которая останется после.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağın eski biçimini sorgular; sürdürmek ile saygıyla tamamlamak arasındaki farkı gösterir.',
    'It questions an old relational form and distinguishes continuation from respectful completion.',
    'Карта ставит под вопрос прежнюю форму связи и различает продолжение и уважительное завершение.',
  ),
  decisionDynamic: L10nTriple(
    'Karar, artık canlı olmayanı açıkça tanıyıp gerekli kapanışı kabul etmeyi ister.',
    'The decision asks for clear recognition of what is no longer alive and acceptance of closure.',
    'Решение требует ясно увидеть утратившее жизнь и принять необходимость завершения.',
  ),
  actionDirection: L10nTriple(
    'Neyin bittiğini adlandırın, geride kalan değeri alın ve fazlalığı serbest bırakın.',
    'Name what has ended, carry forward its value, and release the remainder.',
    'Назовите завершившееся, сохраните его ценность и отпустите остальное.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Kabul edilen bir son, dönüşümün sade ve temiz biçimde ilerlemesine alan açar.',
      'An accepted ending allows transformation to proceed with clarity and simplicity.',
      'Принятый конец позволяет преобразованию идти ясно и без лишнего груза.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['transformation', 'release', 'ending'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Bırakış gecikebilir, kayıp içeride tutulabilir veya değişim yarım kalabilir.',
      'Release may be delayed, loss held inwardly, or transformation left incomplete.',
      'Отпускание может задержаться, утрата остаться внутри, а преобразование — незавершенным.',
    ),
    transforms: [
      ReversedTransformKind.delay,
      ReversedTransformKind.internalization,
    ],
    keywordIds: ['resistance', 'stagnation', 'grief'],
  ),
  symbolTags: [
    NarrativeSymbolTags.transformation,
    NarrativeSymbolTags.release,
    NarrativeSymbolTags.ending,
  ],
  profileRevision: 1,
);
