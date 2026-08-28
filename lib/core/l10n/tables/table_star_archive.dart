/// Archive chapter sentences — one story, never theatrical, never natal.
library;

import '../l10n_triple.dart';

const kL10nStarArchive = <String, L10nTriple>{
  'star.arc.today.sun.0': L10nTriple(
    'Bu arşiv yaprağında {sign} yolunda duran fasıl: {mark}.',
    'On this archive leaf, the chapter on the {sign} path: {mark}.',
    'На этом листе архива глава на пути {sign}: {mark}.',
  ),
  'star.arc.today.sun.1': L10nTriple(
    '{sign} yolunda bu sembolik fasıl senin hakkında {mark} öneriyor.',
    'On the {sign} path, this symbolic chapter suggests {mark} about you.',
    'На пути {sign} эта символическая глава предлагает о тебе {mark}.',
  ),
  'star.arc.today.sun.2': L10nTriple(
    'Arşivde {sign} ipliği seçilir: {mark}.',
    'In the archive the {sign} thread shows: {mark}.',
    'В архиве видна нить {sign}: {mark}.',
  ),
  'star.arc.today.bare.0': L10nTriple(
    'Bu yaprağın faslı: {mark}.',
    'The chapter on this leaf: {mark}.',
    'Глава на этом листе: {mark}.',
  ),
  'star.arc.today.bare.1': L10nTriple(
    'Arşiv yaprağı şöyle duruyor: {mark}.',
    'The archive leaf sits like this: {mark}.',
    'Лист архива стоит так: {mark}.',
  ),
  'star.arc.today.bare.2': L10nTriple(
    'Bu sembolik yolda bakılacak fasıl {mark}.',
    'The chapter to regard on this symbolic path is {mark}.',
    'Глава, на которую смотреть на этом символическом пути, — {mark}.',
  ),
  'star.arc.sky.sun.0': L10nTriple(
    'Bu faslın yüzü {sign} ipliğinde seçilir: {mark}.',
    "This chapter's face shows on the {sign} thread: {mark}.",
    'Лицо этой главы видно на нити {sign}: {mark}.',
  ),
  'star.arc.sky.sun.1': L10nTriple(
    '{sign} tarafında bu yaprağın yüzü: {mark}.',
    "On the {sign} side, this leaf's face: {mark}.",
    'На стороне {sign} лицо этого листа: {mark}.',
  ),
  'star.arc.sky.sun.2': L10nTriple(
    '{sign} ritminde arşivin seçtiği yüz {mark}.',
    'The face the archive chooses in the {sign} rhythm is {mark}.',
    'Лицо, которое архив выбирает в ритме {sign}, — {mark}.',
  ),
  'star.arc.sky.bare.0': L10nTriple(
    'Bu yaprağın yüzü: {mark}.',
    "This leaf's face: {mark}.",
    'Лицо этого листа: {mark}.',
  ),
  'star.arc.sky.bare.1': L10nTriple(
    'Arşivde görünen yüz {mark}.',
    'The face that shows in the archive is {mark}.',
    'Лицо, что видно в архиве, — {mark}.',
  ),
  'star.arc.sky.bare.2': L10nTriple(
    'Bu faslın yüzü şöyle duruyor: {mark}.',
    "This chapter's face sits like this: {mark}.",
    'Лицо этой главы стоит так: {mark}.',
  ),
  'star.arc.knot.full.0': L10nTriple(
    'İçeride bu iz {knot} olarak geriliyor. Acele yok; hangi ipin çekildiğini görmek yeter.',
    'Inside, this mark draws taut as {knot}. No hurry; seeing which thread is pulled is enough.',
    'Внутри этот след натягивается как {knot}. Спешить не нужно; увидеть, какая нить тянется, довольно.',
  ),
  'star.arc.knot.full.1': L10nTriple(
    'Aynı iz içeride duruyor: {knot}. Dışarıdaki gürültüden çok, bu gerilim bakılacak yer.',
    'The same mark sits inside: {knot}. More than the noise outside, this tautness is the place to look.',
    'Тот же след стоит внутри: {knot}. Больше чем внешний шум, это натяжение — место, на которое смотреть.',
  ),
  'star.arc.knot.full.2': L10nTriple(
    'İçerideki tema, senin keşiflerinde biriken izden geliyor: {knot}.',
    'The theme inside comes from the mark gathered in your discoveries: {knot}.',
    'Внутренняя тема идёт от следа, накопленного в твоих открытиях: {knot}.',
  ),
  'star.arc.knot.soft.0': L10nTriple(
    'İçeride henüz adı konmuş bir tema birikmedi. Bu yaprak sessiz duruyor; acele yok.',
    'Inside, no named theme has gathered yet. This leaf sits quiet; no hurry.',
    'Внутри ещё нет названной темы. Этот лист тих; спешить не нужно.',
  ),
  'star.arc.knot.soft.1': L10nTriple(
    'İçeride ayrı bir tema henüz seçilmedi. Bu yaprak yeter; fazlasını zorlamıyorum.',
    'Inside, a separate theme has not been chosen yet. This leaf is enough; I will not force more.',
    'Внутри отдельная тема ещё не выбрана. Этого листа довольно; большего не навязываю.',
  ),
  'star.arc.knot.soft.2': L10nTriple(
    'İçerideki tema için henüz yeterli iz yok. Kısa durmak da bir cevap.',
    'There is not yet enough mark for the theme inside. A short pause is also an answer.',
    'Для внутренней темы ещё недостаточно следа. Короткая пауза тоже ответ.',
  ),
  'star.arc.recent.full.0': L10nTriple(
    'Son dönemde bu damar geri geliyor. {story} Uzun hikâye burada; tek günün ödevi değil.',
    "Lately this vein returns. {story} The longer story is here, not a day's assignment.",
    'В последнее время эта жила возвращается. {story} Длинная история здесь, не задание дня.',
  ),
  'star.arc.recent.full.1': L10nTriple(
    'Son dönemin hikâyesi aynı izden geçiyor: {story}',
    'The recent story passes through the same mark: {story}',
    'Недавняя история проходит через тот же след: {story}',
  ),
  'star.arc.recent.full.2': L10nTriple(
    'Geriye bakınca bu iz son dönemde tekrar ediyor. {story}',
    'Looking back, this mark repeats in the recent stretch. {story}',
    'Оглядываясь, этот след в последнее время повторяется. {story}',
  ),
  'star.arc.recent.soft.0': L10nTriple(
    'Son dönemde arşivde henüz tekrar eden bir fasıl birikmedi. Bu yaprak yeter.',
    'Lately no repeating chapter has gathered in the archive yet. This leaf is enough.',
    'В последнее время в архиве ещё нет повторяющейся главы. Этого листа довольно.',
  ),
  'star.arc.recent.soft.1': L10nTriple(
    'Son dönemin hikâyesi henüz net çizilmedi. Keşif birikince burası açılır.',
    'The recent story is not yet clearly drawn. This place opens when discoveries gather.',
    'История последнего периода ещё не ясно начерчена. Это место откроется, когда накопятся открытия.',
  ),
  'star.arc.recent.soft.2': L10nTriple(
    'Son dönemde ayrı bir damar seçilmedi. Sessiz arşiv; acele yok.',
    'Lately no separate vein was chosen. A quiet archive; no hurry.',
    'В последнее время отдельная жила не выбрана. Тихий архив; спешить не нужно.',
  ),
  'star.arc.gate.bind.0': L10nTriple(
    'Önündeki eşik az önce duran çizgiden gelir. Geride bırakmak ile gerçekten veda etmek aynı kapı değil. Hangisinde durduğunu sen bilirsin.',
    'The threshold ahead comes from the line that just sat here. Leaving something behind and truly bidding farewell are not the same door. You know which one you are in.',
    'Порог впереди идёт от линии, что только что стояла. Оставить позади и по-настоящему проститься — не одна дверь. Ты знаешь, в какой ты.',
  ),
  'star.arc.gate.bind.1': L10nTriple(
    'Önündeki eşik bu bağdaki netleşmeyen yer. Konuşmak ile susmak aynı kapı değil.',
    'The threshold ahead is the unclarified place in this bond. Speaking and staying silent are not the same door.',
    'Порог впереди — непрояснённое место в этой связи. Сказать и молчать — не одна дверь.',
  ),
  'star.arc.gate.work.0': L10nTriple(
    'Önündeki eşik az önce duran çizgiden gelir. Dağıtmak ile bir işi sessizce bitirmek aynı kapı değil. Hangisinde durduğunu sen bilirsin.',
    'The threshold ahead comes from the line that just sat here. Scattering and quietly finishing one work are not the same door. You know which one you are in.',
    'Порог впереди идёт от линии, что только что стояла. Рассредоточиться и тихо закончить одно дело — не одна дверь. Ты знаешь, в какой ты.',
  ),
  'star.arc.gate.work.1': L10nTriple(
    'Önündeki eşik tek görünür teslim. Listeyi uzatmak başka kapı.',
    'The threshold ahead is one visible delivery. Lengthening the list is another door.',
    'Порог впереди — одна видимая сдача. Удлинять список — другая дверь.',
  ),
  'star.arc.gate.open.0': L10nTriple(
    'Önündeki eşik az önce duran çizgiden gelir. Aceleye gerek yok; durduğun yerde hangi ipin gerildiğine bir kez daha bakmak yeter.',
    'The threshold ahead comes from the line that just sat here. No need to rush; looking once more at which thread is taut where you stand is enough.',
    'Порог впереди идёт от линии, что только что стояла. Спешить не нужно; ещё раз увидеть, какая нить натянута там, где ты стоишь, довольно.',
  ),
  'star.arc.gate.open.1': L10nTriple(
    'Önündeki eşik bu izden gelir. Aceleye gerek yok; durduğun yerde bir kez daha bakmak yeter.',
    'The threshold ahead comes from this mark. No need to rush; looking once more where you stand is enough.',
    'Порог впереди идёт от этого следа. Спешить не нужно; ещё раз посмотреть там, где ты стоишь, довольно.',
  ),
  'star.arc.gate.open.2': L10nTriple(
    'Önündeki eşik, biriken hikâyenin uzadığı kapı. Geçmek zorunda değilsin; durduğunu görmek yeter.',
    'The threshold ahead is the door the gathered story stretches toward. You do not have to pass through; seeing where you stand is enough.',
    'Порог впереди — дверь, к которой тянется накопленная история. Проходить не обязан; увидеть, где стоишь, довольно.',
  ),
  'star.arc.gate.thin.0': L10nTriple(
    'Önündeki eşik henüz net çizilmedi. Aceleye gerek yok; biriken hikâyeyi beklemek yeter.',
    'The threshold ahead is not yet clearly drawn. No need to rush; waiting for the gathered story is enough.',
    'Порог впереди ещё не ясно начерчен. Спешить не нужно; ждать накопленную историю довольно.',
  ),
  'star.arc.gate.thin.1': L10nTriple(
    'Önündeki eşik için arşivde henüz yeter iz yok. Sessizlik de bir duruş.',
    'There is not yet enough mark in the archive for the threshold ahead. Silence is also a stance.',
    'Для порога впереди в архиве ещё недостаточно следа. Тишина тоже стойка.',
  ),
  'star.arc.gate.thin.2': L10nTriple(
    'Önündeki eşik belirsiz kalabilir. Kapıyı zorla açmaya gerek yok.',
    'The threshold ahead may stay unclear. No need to force the door open.',
    'Порог впереди может остаться неясным. Насильно открывать дверь не нужно.',
  ),
  'star.arc.ask.full.0': L10nTriple(
    'Bu faslın bıraktığı yer: {knot} izinin yanında, netleştirmek istediğin tek bir kısım.',
    'What this chapter leaves: beside the mark of {knot}, one part you actually want to clarify.',
    'Что оставляет эта глава: рядом со следом {knot} — одна часть, которую ты правда хочешь прояснить.',
  ),
  'star.arc.ask.full.1': L10nTriple(
    'Bu faslın bıraktığı yer, {knot} tarafında neyi taşımayı seçtiğin.',
    'What this chapter leaves is what you choose to carry on the side of {knot}.',
    'Что оставляет эта глава — что ты выбираешь нести со стороны {knot}.',
  ),
  'star.arc.ask.full.2': L10nTriple(
    'Bu faslın bıraktığı ayrım kısa: {knot} içinde hangisi senin, hangisi alışkanlık.',
    'The split this chapter leaves is short: inside {knot}, which is yours, and which is habit.',
    'Различие, которое оставляет эта глава, коротко: внутри {knot} что твоё, а что привычка.',
  ),
  'star.arc.ask.thin.0': L10nTriple(
    'Bu faslın bıraktığı yer henüz net değil; arşiv daha sessiz.',
    'What this chapter leaves is not yet clear; the archive is still quieter.',
    'Что оставляет эта глава, ещё не ясно; архив тише.',
  ),
  'star.arc.ask.thin.1': L10nTriple(
    'Bu faslın bıraktığı yer, birikecek izlerle netleşir. Bugün zorlamıyorum.',
    'What this chapter leaves will clarify with marks that gather. I am not forcing it today.',
    'Что оставляет эта глава, прояснится с накапливающимися следами. Сегодня не навязываю.',
  ),
  'star.arc.ask.thin.2': L10nTriple(
    'Bu faslın bıraktığı yer için henüz yeter iz yok. Kısa durmak yeter.',
    'There is not yet enough mark for what this chapter leaves. A short pause is enough.',
    'Для того, что оставляет эта глава, ещё недостаточно следа. Короткой паузы довольно.',
  ),
};
