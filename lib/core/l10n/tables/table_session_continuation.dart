/// Cross-feature session continuation — one relevant action.
library;

import '../l10n_triple.dart';

const kL10nSessionContinuation = <String, L10nTriple>{
  'continue.coffee.tarot': L10nTriple(
    'Bu yön teması Tarot\'ta da açılabilir.',
    'This path theme can also open in Tarot.',
    'Эту тему пути можно раскрыть и в Таро.',
  ),
  'continue.coffee.or': L10nTriple(
    'Luna ile günlük bağlamında aç',
    'Open this with Luna in daily context',
    'Раскрой это с Luna в повседневном контексте',
  ),
  'continue.coffee.or_whisper': L10nTriple(
    'Fincanda öne çıkan {theme} teması varsa, Luna bunu günlük hayatındaki bağlamla birlikte açabilir.',
    'If {theme} stands out in the cup, Luna can open it with the context of your daily life.',
    'Если в чашке выделяется тема {theme}, Luna может раскрыть её в контексте твоей повседневности.',
  ),
  'continue.coffee.or_whisper.generic': L10nTriple(
    'Fincanda öne çıkan tema kararlarla ilgiliyse, Luna bunu günlük hayatındaki bağlamla birlikte açabilir.',
    'If the cup highlights a decision theme, Luna can open it with the context of your daily life.',
    'Если в чашке выделяется тема решений, Luna может раскрыть её в контексте твоей повседневности.',
  ),
  'continue.palm.tarot': L10nTriple(
    'Bu iz Tarot\'ta da açılabilir.',
    'This mark can also open in Tarot.',
    'Этот след можно раскрыть и в Таро.',
  ),
  'continue.palm.or': L10nTriple(
    'Luna ile bu izi biraz daha aç',
    'Open this mark a little more with Luna',
    'Раскрой этот след немного глубже с Luna',
  ),
  'continue.palm.or_whisper': L10nTriple(
    'Avuçta öne çıkan {theme} teması varsa, Luna bunu sakin bir sohbette açabilir.',
    'If {theme} stands out in the palm, Luna can open it in a quiet conversation.',
    'Если на ладони выделяется тема {theme}, Luna может раскрыть её в спокойном разговоре.',
  ),
  'continue.palm.or_whisper.generic': L10nTriple(
    'Avuçta öne çıkan bir tema varsa, Luna bunu sakin bir sohbette açabilir.',
    'If a theme stands out in the palm, Luna can open it in a quiet conversation.',
    'Если на ладони выделяется тема, Luna может раскрыть её в спокойном разговоре.',
  ),
  'continue.tarot.or': L10nTriple(
    'İstersen bunu Luna ile biraz daha açabiliriz.',
    'If you like, we can open this a little more with Luna.',
    'Если хочешь, можем чуть глубже раскрыть это с Luna.',
  ),
  'continue.dream.journal': L10nTriple(
    '{theme} temasının diğer keşiflerinde de izine bakabilirsin.',
    'You can also look for {theme} in your other discoveries.',
    'Тему {theme} можно поискать и в других открытиях.',
  ),
  'continue.dream.journal.generic': L10nTriple(
    'Bu temanın diğer keşiflerinde de izine bakabilirsin.',
    'You can also look for this theme in your other discoveries.',
    'Эту тему можно поискать и в других открытиях.',
  ),
  'continue.star.journal': L10nTriple(
    '{theme} temasını Keşif Günlüğünde de görebilirsin.',
    'You can also see {theme} in your Discovery Journal.',
    'Тему {theme} можно увидеть и в Дневнике открытий.',
  ),
  'continue.star.journal.generic': L10nTriple(
    'Keşif Günlüğünde devam edebilirsin.',
    'You can continue in Discovery Journal.',
    'Можно продолжить в Дневнике открытий.',
  ),
  'continue.relation.journal': L10nTriple(
    '{theme} temasını Keşif Günlüğünde de görebilirsin.',
    'You can also see {theme} in your Discovery Journal.',
    'Тему {theme} можно увидеть и в Дневнике открытий.',
  ),
  'continue.relation.journal.generic': L10nTriple(
    'Bu bağ temasını Keşif Günlüğünde de görebilirsin.',
    'You can also see this bond theme in your Discovery Journal.',
    'Эту тему связи можно увидеть и в Дневнике открытий.',
  ),
  'continue.astro.journal': L10nTriple(
    '{theme} temasını Keşif Günlüğünde de görebilirsin.',
    'You can also see the theme of {theme} in your Discovery Journal.',
    'Тему {theme} можно увидеть и в Дневнике открытий.',
  ),
  'continue.astro.journal.generic': L10nTriple(
    'Bu temayı Keşif Günlüğünde de görebilirsin.',
    'You can also see this theme in your Discovery Journal.',
    'Эту тему можно увидеть и в Дневнике открытий.',
  ),
};
