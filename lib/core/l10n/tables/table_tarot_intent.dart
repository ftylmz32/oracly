/// Intention-specific local reading lines.
library;

import '../l10n_triple.dart';

const kL10nTarotIntent = <String, L10nTriple>{
  'tarot.intent.love': L10nTriple(
    '{name} ({ori}) duygusal hali sadeleştirmeden görünür kılıyor. {meaning}{related}{q} Asıl mesele çoğu zaman iletişimdeki netlik: ne hissettiğini kısa ve sakin söylemek, belirsiz bekleyişten daha sağlam durur.',
    '{name} ({ori}) makes the emotional weather visible without flattening it. {meaning}{related}{q} The real matter is often clarity in speech: saying what you feel briefly and calmly stands more firmly than a vague wait.',
    '{name} ({ori}) делает видимой душевную погоду, не упрощая её. {meaning}{related}{q} Часто дело в ясности речи: коротко и спокойно сказать, что чувствуешь, стоит крепче смутного ожидания.',
  ),
  'tarot.intent.love.q': L10nTriple(
    ' “{asked}” sorusu duygunun içinden okunuyor; genel tarot nutku değil.',
    ' The question “{asked}” is read from inside the feeling; not a general tarot speech.',
    ' Вопрос «{asked}» читается изнутри чувства, а не общей речью Таро.',
  ),
  'tarot.intent.career': L10nTriple(
    '{name} ({ori}) iş tablosunu görünür kılıyor. {meaning}{q} Mevcut tempoda engel çoğu zaman dağınık öncelik; asıl kazanç tek bir işi bitirmekte duruyor olabilir. Acele büyük hamle değil, görünür ve ölçülü bir odak.',
    '{name} ({ori}) makes the work table visible. {meaning}{q} At the present pace the obstacle is often scattered priority; the real gain may sit in finishing one task. Not a hurried grand move — a visible, measured focus.',
    '{name} ({ori}) делает видимым рабочий стол. {meaning}{q} В нынешнем темпе препятствие часто в разбросанных приоритетах; настоящий выигрыш может быть в том, чтобы закончить одно дело. Не скорый большой ход — видимый, мерный фокус.',
  ),
  'tarot.intent.career.q': L10nTriple(
    ' “{asked}” sorusu iş tablosunun içinden okunuyor.',
    ' The question “{asked}” is read from inside the work table.',
    ' Вопрос «{asked}» читается изнутри рабочего стола.',
  ),
  'tarot.intent.daily': L10nTriple(
    'Bugünün baskın teması {name} ({ori}). {meaning}{q} Dikkat edilecek yer, dağınık savaş yerine tek net adım.',
    'Today’s prevailing theme is {name} ({ori}). {meaning}{q} The place to attend is one clear step, not a scattered fight.',
    'Господствующая тема дня — {name} ({ori}). {meaning}{q} Внимание — к одному ясному шагу, а не к разбросанной борьбе.',
  ),
  'tarot.intent.daily.q': L10nTriple(
    ' “{asked}” bugünün merceği.',
    ' “{asked}” is today’s lens.',
    ' «{asked}» — линза сегодняшнего дня.',
  ),
  'tarot.intent.general': L10nTriple(
    'Baskın yaşam teması {name} ({ori}) etrafında. {meaning}{related}{q} Dikkat noktası: neyi taşıdığını, neyi bırakabileceğini ayırmak.',
    'The prevailing life theme sits around {name} ({ori}). {meaning}{related}{q} The point of attention: separating what you are carrying from what you can set down.',
    'Господствующая жизненная тема вокруг {name} ({ori}). {meaning}{related}{q} Точка внимания: отличить, что ты несёшь, от того, что можно оставить.',
  ),
  'tarot.intent.general.q': L10nTriple(
    ' “{asked}” sorusu genel bakışın yerine geçmiyor; onun içinden okunuyor.',
    ' The question “{asked}” does not replace the wider view; it is read from inside it.',
    ' Вопрос «{asked}» не заменяет общий взгляд; он читается изнутри него.',
  ),
};
