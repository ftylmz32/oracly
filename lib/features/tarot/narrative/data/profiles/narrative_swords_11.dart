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
    'A messenger of air; not a judge, but a field of sharp learning curiosity.',
    'Говорит о вестнике воздуха; не о судье, а о поле острого любопытства к учению.',
  ),
  light: L10nTriple(
    'Soru sormak, mahkeme kurmadan düşünce dilini öğrenmeye alan açabilir.',
    'Asking can make room to learn the language of thought without assembling a court.',
    'Спрашивать может дать место учить язык мысли, не собирая суд.',
  ),
  shadow: L10nTriple(
    'Merak dedikoduya, acele hükme veya dinlememeye kayabilir.',
    'When unbalanced, Curiosity becomes gossip, hasty verdict, or not listening.',
    'Любопытство может стать сплетней, поспешным приговором или неслушанием.',
  ),
  tension: L10nTriple(
    'Keskin soru arzusu ile yaralamadan sorma ihtiyacı birlikte durur.',
    'The wish for a sharp question coexists with the need to ask without wounding.',
    'Желание острого вопроса соседствует с нуждой спрашивать, не раня.',
  ),
  desire: L10nTriple(
    'Kişi, henüz olgun olmayan ama canlı bir zihinle öğrenmek isteyebilir.',
    'Learning with a mind still sharp and not yet mature may be the pull.',
    'Может хотеться учиться острым, ещё не зрелым умом.',
  ),
  fear: L10nTriple(
    'Aptal görünmek veya sorunun yaralaması kaygı yaratabilir.',
    'Looking foolish, or the question wounding, may cause unease.',
    'Тревогу может вызывать выглядеть глупо или ранение вопросом.',
  ),
  relationshipDynamic: L10nTriple(
    'İki kişi arasında sorulan bir soru, nazik bir kapı açabilir; yeter ki merak, bir hüküm vermekten ayrı kalsın.',
    'A question asked between two people can open a gentle door, as long as curiosity stays apart from handing down a verdict.',
    'Вопрос, заданный между двумя людьми, может открыть мягкую дверь — при условии, что любопытство остаётся отдельным от вынесения приговора.',
  ),
  decisionDynamic: L10nTriple(
    'Bilineni bilinmeyenden ayırmak, burada spekülasyonu izlemekten daha iyi işler.',
    'Sorting the known from the unknown works better here than following speculation.',
    'Отделить известное от неизвестного здесь полезнее, чем следовать догадкам.',
  ),
  actionDirection: L10nTriple(
    'Soruyu doğrudan sorun ve arkasındaki varsayımı kontrol edin; onun üzerine bir mahkeme kurmak yerine.',
    'Ask the question directly and check the assumption behind it, rather than convening a court over it.',
    'Задайте вопрос прямо и проверьте стоящее за ним допущение, вместо того чтобы созывать из-за этого суд.',
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
