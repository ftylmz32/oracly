/// Narrative Tarot V2 Wands profile — seeded from Oracly deck meanings.
/// Phase 3B1: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeWands11 = NarrativeCardProfile(
  canonicalCardId: 'wands_11',
  coreMeaning: L10nTriple(
    'Yeni bir ateşin habercisini anlatır; usta veya sahne ustası değildir.',
    'A messenger of new fire; not a master or staged expert.',
    'Говорит о вестнике нового огня; не о мастере и не о сценическом знатоке.',
  ),
  light: L10nTriple(
    'Öğrenci merakı, taze bir kapıyı bilmişlik yapmadan aralayabilir.',
    'Student curiosity can open a fresh door without performing knowingness.',
    'Любопытство ученика может приоткрыть свежую дверь, не играя всезнайку.',
  ),
  shadow: L10nTriple(
    'Haberci, dağınık hevese, övünce veya dinlememeye kayabilir.',
    'The messenger may harden into scattered zeal, boast, or not listening.',
    'Вестник может стать рассеянным пылом, похвальбой или неслушанием.',
  ),
  tension: L10nTriple(
    'Yeni ateşi duyurma isteği ile henüz öğrenmekte olma hali çekişir.',
    'The wish to announce new fire contends with still being in learning.',
    'Желание возвестить новый огонь спорит с тем, что учение ещё идёт.',
  ),
  desire: L10nTriple(
    'Kişi, taze bir kıvılcımı soru sorarak keşfetmek isteyebilir.',
    'It can feel important to discover a fresh spark by asking questions.',
    'Может хотеться открыть свежую искру через вопросы.',
  ),
  fear: L10nTriple(
    'Acemi görünmek, ciddiye alınmamak veya hevesin dağılması kaygı yaratabilir.',
    'Looking unripe, not being taken seriously, or zeal scattering may cause unease.',
    'Тревогу может вызывать страх выглядеть незрелым, не быть принятым всерьёз или рассеяния пыла.',
  ),
  relationshipDynamic: L10nTriple(
    'İki kişi arasında taze, biraz ham bir sıcaklık ortaya çıkabilir; her şeyi biliyormuş gibi davranmaktansa gerçek bir soru sormak daha iyi işler.',
    'A fresh, slightly unripe warmth can appear between two people, and a genuine question serves better than acting all-knowing.',
    'Между людьми может появиться свежее, немного незрелое тепло; искренний вопрос работает лучше, чем поза всезнайки.',
  ),
  decisionDynamic: L10nTriple(
    'Gerçekten öğrenilmeye değer tek bir kapı, her yerde kıvılcım avlamaktan daha faydalıdır.',
    'One door worth truly learning is more useful than hunting for sparks everywhere at once.',
    'Одна дверь, которую действительно стоит изучить, полезнее, чем охота за искрами повсюду.',
  ),
  actionDirection: L10nTriple(
    'Gerçek bir soru sorun ve dinleyin; merak, her şeyi biliyormuş gösterisinin yerini alsın.',
    'Ask a real question and listen, letting curiosity replace the performance of already knowing.',
    'Задайте настоящий вопрос и слушайте — пусть любопытство заменит собой позу всезнания.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Öğrenmeye açık haberci ateşi, merakı ustalık iddiasına çevirmeden taşır.',
      'Messenger fire open to learning carries curiosity without claiming mastery.',
      'Огонь вестника, открытый учению, несёт любопытство без притязания на мастерство.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['message', 'studentFire', 'curiosity'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Haberci enerjisi dağınık hevese, övünce veya dinlememeye dönüşebilir.',
      'Messenger energy may become scattered zeal, boast, or refusal to listen.',
      'Энергия вестника может стать рассеянным пылом, похвальбой или отказом слушать.',
    ),
    transforms: [
      ReversedTransformKind.misdirection,
      ReversedTransformKind.excess,
    ],
    keywordIds: ['scatteredZeal', 'boast', 'notListening'],
  ),
  symbolTags: [
    NarrativeSymbolTags.curiosity,
    NarrativeSymbolTags.inquiry,
    NarrativeSymbolTags.awakening,
  ],
  profileRevision: 1,
);
