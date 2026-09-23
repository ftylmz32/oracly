/// Narrative Tarot V2 Swords profile — seeded from Oracly deck meanings.
/// Phase 3B3: not wired into the user reading path.
library;

import '../../../../../core/l10n/l10n_triple.dart';
import '../../domain/narrative_card_profile.dart';
import '../../domain/narrative_orientation_profile.dart';
import '../../domain/narrative_symbol_tags.dart';
import '../../domain/reversed_transform_kind.dart';
import '../../domain/narrative_keyword_ids.dart';

const kNarrativeSwords10 = NarrativeCardProfile(
  canonicalCardId: 'swords_10',
  coreMeaning: L10nTriple(
    'Zihinsel bir sonu anlatır; bedenin sonu değildir, tükenmiş bir düşünce döngüsüdür.',
    'The center is a mental ending — an exhausted thought-cycle, rather than the end of a body.',
    'Говорит об умственном конце; не о конце тела, а об исчерпанном цикле мысли.',
  ),
  light: L10nTriple(
    'Yerde yatmayı bitirmek, henüz dans etmeden döngüyü kapatmaya alan açabilir.',
    'Finishing lying on the ground can make room to close the cycle without dancing yet.',
    'Закончить лежать на земле может дать место закрыть цикл, ещё не танцуя.',
  ),
  shadow: L10nTriple(
    'Son felaket kimliğine, kalkmamaya veya her şey bitti hikâyesine kayabilir.',
    'An ending can turn brittle when it becomes identifying with disaster, refusing to rise, or telling a story that everything is over.',
    'Конец может стать личностью бедствия, невставанием или историей «всё кончено».',
  ),
  tension: L10nTriple(
    'Bitmişliği kabul etmek ile sonsuz yenilgi hikâyesine bağlanmama ihtiyacı birlikte durur.',
    'Accepting finishedness coexists with the need not to bind to endless defeat.',
    'Принятие законченности соседствует с нуждой не привязаться к вечному поражению.',
  ),
  desire: L10nTriple(
    'Kişi, tükenmiş bir dilin veya fikir savaşının kapanmasını isteyebilir.',
    'There may be a wish for exhausted language or a war of ideas to close.',
    'Может хотеться, чтобы исчерпанный язык или война идей закрылась.',
  ),
  fear: L10nTriple(
    'Hiç ayağa kalkamamak veya sonun kimlik olması kaygı yaratabilir.',
    'Never rising again, or the ending becoming identity, may cause unease.',
    'Тревогу может вызывать невозможность встать снова или превращение конца в личность.',
  ),
  relationshipDynamic: L10nTriple(
    'Bir bağda tükenmiş bir konuşma biçimi ortaya çıkabilir; bu, bedenin değil yalnızca zihnin yorgunluğu yüzünden kesin gibi duyulur.',
    'An exhausted way of talking can show up in a bond, sounding final only because the mind is tired, not because the body has spoken.',
    'В связи может проявиться истощённая манера речи, звучащая как приговор лишь потому, что устал ум, а не потому, что заговорило тело.',
  ),
  decisionDynamic: L10nTriple(
    'Hangi düşünce döngüsünün gerçekten bittiğini adlandırmak, gece kaygısının ona eklediklerinden daha önemlidir.',
    'Naming which thought-cycle has actually finished matters more than whatever night worry adds to it.',
    'Назвать, какой цикл мысли действительно завершён, важнее того, что добавляет к этому ночная тревога.',
  ),
  actionDirection: L10nTriple(
    'Yerde yatmayı bitirin; henüz dans etmek zorunda değilsiniz.',
    'Finish lying on the ground; you do not have to dance yet.',
    'Закончите лежать на земле; ещё не обязательно танцевать.',
  ),
  upright: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Kapanan bir zihin döngüsü, beden sonu sanılmadan tamamlanır.',
      'A closing mind-cycle completes without being mistaken for bodily ending.',
      'Закрывающийся цикл ума завершается, не принимаясь за конец тела.',
    ),
    transforms: <ReversedTransformKind>[],
    keywordIds: [NarrativeKeywordIds.ending, NarrativeKeywordIds.enough],
  ),
  reversed: NarrativeOrientationProfile(
    expression: L10nTriple(
      'Son felaket kimliğine içe çekilebilir veya kalkışı engelleyerek her şey bitti hikâyesinde tutabilir.',
      'The ending may internalize into disaster-identity, or block rising until an all-is-over story holds still.',
      'Конец может уйти внутрь в личность бедствия или заблокировать подъём, пока история «всё кончено» держит неподвижным.',
    ),
    transforms: [
      ReversedTransformKind.internalization,
      ReversedTransformKind.blockedExpression,
    ],
    keywordIds: [NarrativeKeywordIds.despair, NarrativeKeywordIds.stagnation],
  ),
  symbolTags: [
    NarrativeSymbolTags.ending,
    NarrativeSymbolTags.release,
    NarrativeSymbolTags.completion,
  ],
  profileRevision: 1,
);
