/// Narrative Tarot V2 Swords profile — seeded from Oracly deck meanings.
/// Phase 3B3: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';

const kNarrativeSwords11 = NarrativeCardProfile(
  canonicalCardId: 'swords_11',
  coreMeaning: L10nTriple(
    'Havanın habercisini anlatır; yargıç değil, keskin merakla öğrenme alanıdır.',
    'It speaks of a messenger of air; not a judge, but a field of sharp learning curiosity.',
    'Говорит о вестнике воздуха; не о судье, а о поле острого любопытства к учению.',
  ),
  light: L10nTriple(
    'Soru sormak, mahkeme kurmadan düşünce dilini öğrenmeye alan açabilir.',
    'Asking can make room to learn the language of thought without assembling a court.',
    'Спрашивать может дать место учить язык мысли, не собирая суд.',
  ),
  shadow: L10nTriple(
    'Merak dedikoduya, acele hükme veya dinlememeye kayabilir.',
    'Curiosity may slide into gossip, hasty verdict, or not listening.',
    'Любопытство может стать сплетней, поспешным приговором или неслушанием.',
  ),
  tension: L10nTriple(
    'Keskin soru arzusu ile yaralamadan sorma ihtiyacı birlikte durur.',
    'The wish for a sharp question coexists with the need to ask without wounding.',
    'Желание острого вопроса соседствует с нуждой спрашивать, не раня.',
  ),
  desire: L10nTriple(
    'Kişi, henüz olgun olmayan ama canlı bir zihinle öğrenmek isteyebilir.',
    'There may be a wish to learn with a mind still sharp and not yet mature.',
    'Может хотеться учиться острым, ещё не зрелым умом.',
  ),
  fear: L10nTriple(
    'Aptal görünmek veya sorunun yaralaması kaygı yaratabilir.',
    'Looking foolish, or the question wounding, may cause unease.',
    'Тревогу может вызывать выглядеть глупо или ранение вопросом.',
  ),
  relationshipDynamic: L10nTriple(
    'Bağda soru sormak yumuşak bir kapı olabilir; hükmü meraktan ayırmayı ister.',
    'Asking in a bond may be a gentle door; it asks to separate verdict from curiosity.',
    'Спрашивать в связи может быть мягкой дверью; карта просит отделить приговор от любопытства.',
  ),
  decisionDynamic: L10nTriple(
    'Seçim, spekülasyondan ayrı, bilineni ve bilinmeyeni yoklamaya yaslanır.',
    'The choice leans on testing known from unknown, apart from speculation.',
    'Выбор опирается на проверку известного и неизвестного, отдельно от догадки.',
  ),
  actionDirection: L10nTriple(
    'Sorun; mahkeme kurmayın, varsayımı yoklayın.',
    'Ask; do not assemble a court — check the assumption.',
    'Спросите; не собирайте суд — проверьте допущение.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Öğrenen merak, haberciliği yargıçlık sanmadan tutar.',
      'Learning curiosity holds the messenger role without mistaking it for judge.',
      'Учащееся любопытство держит роль вестника, не принимая её за судью.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: ['airMessenger', 'sharpStudent', 'question'],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Merak dedikodu ve acele hükümde taşabilir veya soruşturmayı dinlemekten sapıtabilir.',
      'Curiosity may tip into excess gossip and hasty verdict, or misdirect inquiry away from listening.',
      'Любопытство может перейти в избыточную сплетню и поспешный приговор или сбить расследование в сторону от слушания.',
    ),
    transforms: [
      ReversedTransformKind.excess,
      ReversedTransformKind.misdirection,
    ],
    keywordIds: ['gossip', 'hastyVerdict', 'notListening'],
  ),
  symbolTags: [
    NarrativeSymbolTags.curiosity,
    NarrativeSymbolTags.inquiry,
    NarrativeSymbolTags.clarity,
  ],
  profileRevision: 1,
);
