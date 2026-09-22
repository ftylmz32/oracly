/// Narrative Tarot V2 Major Arcana profile — seeded from Oracly deck meanings.
/// Phase 3A: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeMajor07 = NarrativeCardProfile(
  canonicalCardId: 'major_07',
  coreMeaning: L10nTriple(
    'Farklı dürtüleri ortak bir yöne getirerek kararlı ilerleme kurmayı temsil eder.',
    'It represents creating determined progress by bringing competing drives into one direction.',
    'Карта означает решительное продвижение через объединение разных импульсов в одном направлении.',
  ),
  light: L10nTriple(
    'Disiplinli irade, karmaşık koşullarda bile hareketi tutarlı kılabilir.',
    'Disciplined will can keep movement coherent even amid complicated conditions.',
    'Дисциплинированная воля помогает сохранять цельность движения даже в сложных обстоятельствах.',
  ),
  shadow: L10nTriple(
    'Hız ve zafer isteği, duyguları bastıran sert bir zorlamaya dönüşebilir.',
    'The wish for speed and victory can become force that suppresses feeling.',
    'Стремление к скорости и победе может стать жестким нажимом, подавляющим чувства.',
  ),
  tension: L10nTriple(
    'İleri gitme dürtüsü ile iç çatışmaları düzenleme gereği birbirini sınar.',
    'The drive to advance is tested by the need to coordinate inner conflict.',
    'Порыв двигаться вперед проверяется необходимостью согласовать внутренние противоречия.',
  ),
  desire: L10nTriple(
    'Kişi, enerjisini dağıtmadan belirlediği hedefe doğru somut yol almak isteyebilir.',
    'What is sought is to make concrete progress without scattering energy.',
    'Может возникнуть желание заметно продвинуться к цели, не рассеивая силы.',
  ),
  fear: L10nTriple(
    'Kontrolü yitirmek, durmak veya karşıt güçler arasında bölünmek kaygı yaratabilir.',
    'Losing control, coming to a halt, or splitting between opposing forces may cause unease.',
    'Тревогу могут вызывать потеря контроля, остановка или разрыв между противоборствующими силами.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağa yön ve ivme getirir; ortak rotanın tek taraflı belirlenmemesini hatırlatır.',
    'It brings direction and momentum to a bond while warning against a one-sided route.',
    'Карта придает связи направление и импульс, напоминая не выбирать общий путь в одиночку.',
  ),
  decisionDynamic: L10nTriple(
    'Karar, hedefin netleşmesini ve çelişen önceliklerin yönetilebilir hale gelmesini ister.',
    'The decision calls for a clear destination and manageable competing priorities.',
    'Решение требует ясной цели и приведения противоречивых приоритетов в управляемый вид.',
  ),
  actionDirection: L10nTriple(
    'Rotayı belirleyin, dikkati dağıtan yükleri azaltın ve hızınızı koşullara göre ayarlayın.',
    'Set the route, reduce distracting burdens, and match your pace to conditions.',
    'Определите маршрут, уменьшите отвлекающую нагрузку и соотнесите темп с условиями.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Toparlanmış irade, baskı kurmadan kararlı ve yönü belli bir hareket yaratır.',
      'Gathered will creates decisive, directed movement without relying on force.',
      'Собранная воля создает решительное и направленное движение без опоры на давление.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['movement', 'will', 'direction'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'İvme bloke olabilir, rota şaşabilir veya kontrol ihtiyacı gereğinden fazla büyüyebilir.',
      'Momentum may be blocked, the route may drift, or the need for control may grow excessive.',
      'Импульс может блокироваться, курс — сбиваться, а потребность в контроле — чрезмерно усиливаться.',
    ),
    transforms: [
      ReversedTransformKind.blockedExpression,
      ReversedTransformKind.misdirection,
    ],
    keywordIds: ['stall', 'drift', 'overcontrol'],
  ),
  symbolTags: [
    NarrativeSymbolTags.movement,
    NarrativeSymbolTags.will,
    NarrativeSymbolTags.direction,
  ],
  profileRevision: 1,
);
