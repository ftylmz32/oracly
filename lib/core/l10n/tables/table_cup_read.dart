/// Continuous coffee-cup reading beats — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nCupRead = <String, L10nTriple>{
  'cup.zone.rim': L10nTriple('ağızda ', 'at the rim, ', 'у края, '),
  'cup.zone.wall': L10nTriple('duvarda ', 'on the wall, ', 'на стенке, '),
  'cup.zone.base': L10nTriple('dipte ', 'at the base, ', 'на дне, '),
  'cup.zone.handle': L10nTriple('kulpa yakın ', 'near the handle, ', 'у ручки, '),
  'cup.shape.bird': L10nTriple(
    'kuşa benzeyen bir şekil',
    'a shape that resembles a bird',
    'форма, похожая на птицу',
  ),
  'cup.shape.road': L10nTriple(
    'yol gibi açık bir çizgi',
    'an open line like a road',
    'открытая линия, как дорога',
  ),
  'cup.shape.heart': L10nTriple(
    'kalbe benzeyen bir küme',
    'a cluster that resembles a heart',
    'скопление, похожее на сердце',
  ),
  'cup.shape.ring': L10nTriple(
    'yüzük gibi bir halka izi',
    'a ring-like circle in the grounds',
    'след кольца в гуще',
  ),
  'cup.shape.eye': L10nTriple(
    'göze benzeyen bir açıklık',
    'an opening that resembles an eye',
    'просвет, похожий на глаз',
  ),
  'cup.shape.mountain': L10nTriple(
    'dağ gibi duran yoğun telve',
    'dense grounds sitting like a mountain',
    'гуща, стоящая как гора',
  ),
  'cup.shape.key': L10nTriple(
    'anahtara benzeyen bir iz',
    'a mark that resembles a key',
    'след, похожий на ключ',
  ),
  'cup.shape.star': L10nTriple(
    'yıldıza benzeyen bir çatallı iz',
    'a forked mark that resembles a star',
    'разветвлённый след, похожий на звезду',
  ),
  'cup.shape.tree': L10nTriple(
    'ağaca benzeyen bir küme',
    'a cluster that resembles a tree',
    'скопление, похожее на дерево',
  ),
  'cup.shape.person': L10nTriple(
    'silüete benzeyen bir iz',
    'a mark that resembles a silhouette',
    'след, похожий на силуэт',
  ),
  'cup.shape.letter': L10nTriple(
    'mektuba benzeyen kırık çizgiler',
    'broken lines that resemble a letter',
    'рваные линии, похожие на письмо',
  ),
  'cup.form.bird': L10nTriple(
    'kuş gibi duran bir şekil',
    'a shape sitting like a bird',
    'форма, стоящая как птица',
  ),
  'cup.form.road': L10nTriple(
    'yol gibi duran açık bir çizgi',
    'an open line sitting like a road',
    'открытая линия, стоящая как дорога',
  ),
  'cup.form.heart': L10nTriple(
    'kalp gibi duran bir küme',
    'a cluster sitting like a heart',
    'скопление, стоящее как сердце',
  ),
  'cup.form.ring': L10nTriple(
    'yüzük gibi duran bir halka',
    'a circle sitting like a ring',
    'круг, стоящий как кольцо',
  ),
  'cup.form.eye': L10nTriple(
    'göz gibi duran bir açıklık',
    'an opening sitting like an eye',
    'просвет, стоящий как глаз',
  ),
  'cup.form.mountain': L10nTriple(
    'dağ gibi duran yoğun telve',
    'dense grounds sitting like a mountain',
    'гуща, стоящая как гора',
  ),
  'cup.form.key': L10nTriple(
    'anahtar gibi duran bir iz',
    'a mark sitting like a key',
    'след, стоящий как ключ',
  ),
  'cup.form.star': L10nTriple(
    'yıldız gibi duran çatallı bir iz',
    'a forked mark sitting like a star',
    'разветвлённый след, стоящий как звезда',
  ),
  'cup.form.tree': L10nTriple(
    'ağaç gibi duran bir küme',
    'a cluster sitting like a tree',
    'скопление, стоящее как дерево',
  ),
  'cup.form.person': L10nTriple(
    'silüet gibi duran bir iz',
    'a mark sitting like a silhouette',
    'след, стоящий как силуэт',
  ),
  'cup.form.letter': L10nTriple(
    'mektup gibi duran kırık çizgiler',
    'broken lines sitting like a letter',
    'рваные линии, стоящие как письмо',
  ),
  'cup.read.look.0': L10nTriple(
    'İlk seçilen iz: {seen}.',
    'The first mark that settles is {seen}.',
    'Первый ясный след: {seen}.',
  ),
  'cup.read.look.1': L10nTriple(
    'Okumaya {place}{seen} ile başlıyorum.',
    'I begin from {place}{seen}.',
    'Начинаю с {place}{seen}.',
  ),
  'cup.read.look.2': L10nTriple(
    'Fincanı çevirirken {place}{seen} karşıma çıkıyor.',
    'Turning the cup, {place}{seen} meets me.',
    'Поворачивая чашку, я встречаю {place}{seen}.',
  ),
  'cup.read.look.3': L10nTriple(
    'Net duran iz {place}{seen}.',
    'The clear mark is {place}{seen}.',
    'Ясный след — {place}{seen}.',
  ),
  'cup.read.look.4': L10nTriple(
    'Asıl durduğum yer {place}{seen}.',
    'Where I actually stop is {place}{seen}.',
    'Где я действительно останавливаюсь — {place}{seen}.',
  ),
  'cup.read.together.0': L10nTriple(
    'Yan yana gelince {a} ile {b} ayrı okunmuyor.',
    'Side by side, {a} and {b} do not read apart.',
    'Рядом {a} и {b} не читаются по отдельности.',
  ),
  'cup.read.together.1': L10nTriple(
    '{a} net; hemen yanındaki {b} onu yalnız bırakmıyor.',
    '{a} is clear; {b} beside it does not leave it alone.',
    '{a} ясно; {b} рядом не оставляет его одного.',
  ),
  'cup.read.together.2': L10nTriple(
    'Fincanı çevirince {place}{a} ile {b} aynı telvede toplanıyor.',
    'Turning the cup, {place}{a} and {b} gather in the same grounds.',
    'Поворачивая чашку, {place}{a} и {b} собираются в одной гуще.',
  ),
  'cup.read.together.3': L10nTriple(
    'Önce {a} görünüyor; yanında {b} çizgiyi tamamlıyor.',
    'First {a} comes into view; {b} beside it completes the line.',
    'Сначала видно {a}; рядом {b} завершает линию.',
  ),
  'cup.read.together.4': L10nTriple(
    '{place}{a} ve yanındaki {b} tek iz gibi duruyor.',
    '{place}{a} and {b} beside it sit as one mark.',
    '{place}{a} и {b} рядом стоят как один след.',
  ),
  'cup.read.you.theme': L10nTriple(
    'Senin tarafında {life} meselesi zaten canlıysa, fincandaki bu iz aynı yere bağlanıyor — yeni bir kehanet gibi değil.',
    'If {life} is already alive on your side, this mark in the cup binds to the same place — not as a new prophecy.',
    'Если {life} уже живо с твоей стороны, этот след связывается с тем же местом — не как новое пророчество.',
  ),
  'cup.read.you.0': L10nTriple(
    'Bunu ben daha çok {life} olarak okuyorum.',
    'I read this more as {life}.',
    'Я читаю это скорее как {life}.',
  ),
  'cup.read.you.1': L10nTriple(
    '{life} meselesi fincanda da duruyor; senin tarafında da aynı yerden bakılıyor.',
    'The {life} matter sits in the cup too; it is looked at from the same place on your side.',
    'Дело {life} стоит и в чашке; с твоей стороны смотрят оттуда же.',
  ),
  'cup.read.you.2': L10nTriple(
    'Sende duran yer {life} gibi görünüyor.',
    'Where this sits in you looks like {life}.',
    'То, где это стоит в тебе, похоже на {life}.',
  ),
  'cup.read.develop.near.0': L10nTriple(
    'Yakın bir kıpırdanma ihtimali var; acele bir sonuç gibi bağlamıyorum.',
    'There may be a near stir; I am not binding it as a rushed outcome.',
    'Возможно близкое шевеление; я не связываю это со спешным исходом.',
  ),
  'cup.read.develop.near.1': L10nTriple(
    '{seen} ağıza yakın durduğu için bunu yakın bir eğilim gibi okuyorum — tarih değil.',
    'Because {seen} sits toward the rim, I read a near tendency — not a date.',
    'Потому что {seen} ближе к краю, читаю близкую склонность — не дату.',
  ),
  'cup.read.develop.later': L10nTriple(
    '{seen} duvarda; bunu biraz sonrasına bağlıyorum, acele bir takvim değil.',
    '{seen} sits on the wall; I rest this a little further on, not a hurried calendar.',
    '{seen} на стенке; отношу это чуть дальше, не к календарю.',
  ),
  'cup.read.develop.base': L10nTriple(
    '{seen} dipte duruyor; bunu daha uzun bir iz olarak okuyorum.',
    '{seen} sits at the base; I read this as a longer-running mark.',
    '{seen} на дне; читаю это как более долгий след.',
  ),
  'cup.read.develop.wait': L10nTriple(
    'Dağ gibi duran iz, acele bir çözümü değil beklemeyi düşündürüyor.',
    'The mountain-like mark suggests waiting, not a rushed solution.',
    'След вроде горы думается как ожидание, не спешное решение.',
  ),
  'cup.read.unsure': L10nTriple(
    '{seen} gölgesine benzeyen bir şekil seçiliyor; çok net değil ama çevresindeki telve ile bağlı duruyor.',
    'A shape that resembles a hint of {seen} is visible; it is not sharp, but it sits with the grounds around it.',
    'Виднеется форма, похожая на тень {seen}; неясно, но связана с гущей вокруг.',
  ),
  'cup.read.hedge': L10nTriple(
    '{seen} seçiliyor; çok net değil ama çevresindeki izle birlikte duruyor.',
    '{seen} is visible; it is not sharp, but it sits with the mark beside it.',
    'Виднеется {seen}; неясно, но стоит вместе с соседним следом.',
  ),
  'cup.read.ask.news': L10nTriple(
    'Asıl mesele çoğu zaman beklenen haber değil; geldikten sonra vereceğin karar.',
    'The real matter is often not the awaited news, but the choice after it arrives.',
    'Главное чаще не ожидаемая весть, а решение после неё.',
  ),
  'cup.read.ask.news.1': L10nTriple(
    'Beklenen şey gelmeden de bir sözün duruyorsa, haberden önce o söz daha yakın.',
    'If a word already sits before what you wait for arrives, that word is closer than the news.',
    'Если слово уже стоит до прибытия того, чего ждёшь, оно ближе самой вести.',
  ),
  'cup.read.ask.bind': L10nTriple(
    'Bu kişide asıl gerilim çoğu zaman bağın kendisinden çok, hâlâ yer bırakmanda.',
    'With this person the real tension often sits less in the bond itself than in the room you still leave.',
    'С этим человеком настоящее натяжение чаще не в самой связи, а в месте, которое ты всё ещё оставляешь.',
  ),
  'cup.read.ask.bind.1': L10nTriple(
    'Yakınlık ile alışkanlık burada karışabiliyor; ikisi aynı şey değil.',
    'Closeness and habit can blur here; they are not the same thing.',
    'Близость и привычка здесь могут смешиваться; это не одно и то же.',
  ),
  'cup.read.ask.change': L10nTriple(
    'Beklettiğin kararı uzatmak ile küçük görünür bir adım atmak aynı kapı değil.',
    'Stretching a postponed decision and taking one small visible step are not the same door.',
    'Тянуть отложенное решение и сделать маленький видимый шаг — не одна дверь.',
  ),
  'cup.read.ask.change.1': L10nTriple(
    'Kilidi çevirmeden önce durup bakmak çoğu zaman daha temiz.',
    'Stopping to look before turning the lock is often cleaner.',
    'Остановиться и посмотреть перед тем как повернуть замок чаще чище.',
  ),
  'cup.read.ask.wait': L10nTriple(
    'Bu eşikte acele etmekten çok, beklemeyi dürüst tutmak daha temiz duruyor.',
    'At this threshold, holding the wait honestly sits cleaner than rushing.',
    'У этого порога честнее держать ожидание, чем спешить.',
  ),
  'cup.read.ask.wait.1': L10nTriple(
    'Bugün itmek yerine eşiği olduğu gibi bırakmak daha dürüst olabilir.',
    'Leaving the threshold as it is may be more honest today than pushing.',
    'Сегодня честнее оставить порог как есть, чем толкать.',
  ),
  'cup.read.ask.open': L10nTriple(
    'Fincanın açık yeri çoğu zaman henüz adı konmamış bir konuya bağlanır.',
    'The open place in the cup often binds to a subject not yet named.',
    'Открытое место в чашке часто связано с ещё не названной темой.',
  ),
  'cup.read.ask.open.1': L10nTriple(
    'Adı konmamış bir mesele ile sade duruluk burada karışabiliyor.',
    'An unnamed matter and plain stillness can blur here.',
    'Неназванное дело и простая тишина здесь могут смешиваться.',
  ),
  'cup.life.bind': L10nTriple('yakınlık', 'closeness', 'близость'),
  'cup.life.news': L10nTriple('haber', 'news', 'весть'),
  'cup.life.choice': L10nTriple('karar', 'a decision', 'решение'),
};
