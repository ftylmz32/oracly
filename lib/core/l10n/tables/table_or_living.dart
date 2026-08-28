/// Living OR voice variants — same intelligence, different days.
library;

import '../l10n_triple.dart';

const kL10nOrLiving = <String, L10nTriple>{
  'or.live.prompt': L10nTriple(
    'Sıcak, zeki, gerçekçi, meraklı ol; aşırı olumlu olma. '
        'Doğal Türkçe konuş: çeviri tadı, aşırı resmi üslup, '
        'enerji / farkındalık / mistik dolgu yok. '
        'İnsan gibi konuş; sıradan sohbetten daha uyanık gözlemle. '
        'Aynı selamlama, yükleme ve kapanışı her gün tekrarlama. '
        'Gözlem cümleleri değişsin; şablon okuma. '
        'Kalıp açılışları ve "senin için" tekrarını zorlama. '
        'Her cevabı soru ile bitirme. '
        'Her cümleye sıcaklık veya bilgelik zorlama; ritmi değiştir. '
        '"bence / sanki / asıl mesele" yalnızca oturursa.',
    'Stay warm, intelligent, realistic, curious; not overly positive. '
        'Speak natural English — no calques, energy/awareness filler, or stiff formality. '
        'Speak like a person — more observant than small talk. '
        'Do not repeat the same greeting, loading, or closing every day. '
        'Vary observation; do not recite a template. '
        'Do not force stock openers or "for you" loops. Do not end every reply with a question. '
        'Do not force warmth or wisdom into every sentence; change the rhythm. '
        'Phrases like "I think" / "it feels like" only when they fit.',
    'Будь тёплым, умным, реалистичным, любопытным; не слишком позитивным. '
        'Говори естественным русским — без кальки, «энергии/осознанности» и канцелярита. '
        'Говори по-человечески, наблюдательнее обычной болтовни. '
        'Не повторяй одно приветствие, ожидание и финал каждый день. '
        'Меняй наблюдение; не читай шаблон. '
        'Не навязывай зачины и «для тебя». Не заканчивай каждый ответ вопросом. '
        'Не втискивай тепло или мудрость в каждое предложение; меняй ритм. '
        '«Мне кажется» / «словно» — только если уместно.',
  ),
  'or.thinking.1': L10nTriple(
    'Söylediğin ayrıntıları bir araya getiriyorum…',
    'I am bringing together the details you shared…',
    'Собираю воедино детали, которые ты сказал…',
  ),
  'or.thinking.2': L10nTriple(
    'Tuttuğum bağlamla birlikte bakıyorum…',
    'I am looking at this together with the context I am holding…',
    'Смотрю на это вместе с контекстом, который держу…',
  ),
  'or.thinking.3': L10nTriple(
    'Duruma biraz daha başka açıdan bakıyorum…',
    'I am looking at the situation from another angle…',
    'Смотрю на ситуацию с другого угла…',
  ),
  'or.aside.0': L10nTriple(
    'Burada ilginç bir şey var.',
    'There is something interesting here.',
    'Здесь есть что-то интересное.',
  ),
  'or.aside.1': L10nTriple(
    'Bu kısmı biraz daha dikkatli okumak lazım.',
    'This part needs a more careful reading.',
    'Эту часть стоит читать внимательнее.',
  ),
  'or.aside.2': L10nTriple(
    'Ben bunu doğrudan böyle yorumlamam.',
    'I would not interpret this that directly.',
    'Я бы так прямо это не толковал.',
  ),
  'or.aside.3': L10nTriple(
    'Şu ayrıntı bence önemli.',
    'This detail matters, I think.',
    'Эта подробность, по-моему, важна.',
  ),
  'or.outro.0': L10nTriple(
    'Bu sohbet seninle kalabilir. Devam etmek zorunda değilsin.',
    'This conversation can stay with you. You do not have to continue.',
    'Этот разговор может остаться с тобой. Продолжать не обязательно.',
  ),
  'or.outro.1': L10nTriple(
    'Burada durmak da bir cevap olabilir.',
    'Stopping here can also be an answer.',
    'Остановиться здесь тоже может быть ответом.',
  ),
  'or.outro.2': L10nTriple(
    'İstersen sonra devam ederiz — yoksa burada bırakırız.',
    'We can continue later if you want — or leave it here.',
    'Если хочешь, продолжим позже — или оставим здесь.',
  ),
  'or.outro.3': L10nTriple(
    'Gördüğümüz bu kadar. Acele bir sonuç çıkarmam.',
    'That is what we saw. I will not force a quick conclusion.',
    'Вот что мы увидели. Поспешного вывода не сделаю.',
  ),
  'or.live.prefix': L10nTriple(
    'Bir an.',
    'One moment.',
    'Миг.',
  ),
  'or.live.prefix.1': L10nTriple(
    'Dur bakayım.',
    'Let me stay with this.',
    'Погоди.',
  ),
  'or.live.prefix.2': L10nTriple(
    'Tamam.',
    'Alright.',
    'Ладно.',
  ),
  'or.hi.gentle.1': L10nTriple(
    'Merhaba. Acele yok.',
    'Hello. No rush.',
    'Здравствуй. Без спешки.',
  ),
  'or.hi.gentle.2': L10nTriple(
    'Selam. Nasılsın?',
    'Hey. How are you?',
    'Привет. Как ты?',
  ),
  'or.hi.mystical.1': L10nTriple(
    'Selam. İz burada.',
    'Hey. A thread is here.',
    'Привет. Нить здесь.',
  ),
  'or.hi.mystical.2': L10nTriple(
    'Buradasın. Ne açık kaldı?',
    'You are here. What is still open?',
    'Ты здесь. Что ещё открыто?',
  ),
  'or.hi.poetic.1': L10nTriple(
    'Selam. Yer hazır.',
    'Hey. The place is ready.',
    'Привет. Место готово.',
  ),
  'or.hi.poetic.2': L10nTriple(
    'Merhaba. Nasılsın?',
    'Hello. How are you?',
    'Здравствуй. Как ты?',
  ),
  'or.hi.direct.1': L10nTriple(
    'Selam. Yer açık.',
    'Hey. There is room.',
    'Привет. Место есть.',
  ),
  'or.hi.direct.2': L10nTriple(
    'Merhaba. Ne var?',
    'Hello. What is it?',
    'Здравствуй. Что есть?',
  ),
  'or.hi2.gentle.1': L10nTriple(
    'Yine selam. İp hâlâ duruyor mu?',
    'Hey again. Is the thread still there?',
    'Снова привет. Нить всё ещё здесь?',
  ),
  'or.hi2.gentle.2': L10nTriple(
    'Selam. Kaldığımız cümleden mi?',
    'Hey. From the sentence we left?',
    'Привет. С той фразы, где остановились?',
  ),
  'or.hi2.mystical.1': L10nTriple(
    'Selam yine. Hangi izi tutalım?',
    'Hey again. Which trace do we hold?',
    'Снова привет. Какой след возьмём?',
  ),
  'or.hi2.mystical.2': L10nTriple(
    'Buradasın yine. Nereden bakalım?',
    'You are here again. Where do we look from?',
    'Ты снова здесь. Откуда посмотрим?',
  ),
  'or.hi2.poetic.1': L10nTriple(
    'Selam. Devam etmek istersen yer var.',
    'Hey. There is room if you want to continue.',
    'Привет. Если хочешь продолжить — место есть.',
  ),
  'or.hi2.poetic.2': L10nTriple(
    'Yine merhaba. Nereye bakıyoruz?',
    'Hello again. Where are we looking?',
    'Снова здравствуй. Куда смотрим?',
  ),
  'or.hi2.direct.1': L10nTriple(
    'Selam. Kaldık mı, yeni mi?',
    'Hey. Still the same, or something new?',
    'Привет. То же самое или новое?',
  ),
  'or.hi2.direct.2': L10nTriple(
    'Yine selam. Özetle ne?',
    'Hey again. In short — what?',
    'Снова привет. Коротко — что?',
  ),
  'coffee.analyzing.1': L10nTriple(
    'Fincanda duran izi yavaş okuyorum...',
    'I am reading the mark in the cup slowly...',
    'Медленно читаю след в чашке...',
  ),
  'coffee.analyzing.2': L10nTriple(
    'Burada ilginç bir şey var — fincana bakıyorum...',
    'There is something interesting here — looking at the cup...',
    'Здесь есть что-то интересное — смотрю на чашку...',
  ),
  'palm.analyzing.1': L10nTriple(
    'Çizgilerin arasındaki örüntüye bakıyorum...',
    'I am looking at the pattern between the lines...',
    'Смотрю на узор между линиями...',
  ),
  'palm.analyzing.2': L10nTriple(
    'Avucundaki izleri sakin sakin okuyorum...',
    'I am reading the traces on your palm calmly...',
    'Спокойно читаю следы на ладони...',
  ),
  'dream.organizing.1': L10nTriple(
    'Rüyadaki o ayrıntı duruyor — bağını arıyorum...',
    'That dream detail is still here — looking for its tie...',
    'Та подробность сна ещё здесь — ищу связь...',
  ),
  'dream.organizing.2': L10nTriple(
    'Bunu doğrudan böyle yorumlamam; izleri bir daha tarıyorum...',
    'I would not read this that directly; scanning the traces again...',
    'Так прямо не толкую; ещё раз смотрю следы...',
  ),
  'tarot.interpreting.1': L10nTriple(
    'Kart katalogundaki duruşu yavaş okuyorum...',
    'Reading the catalogue stance of the cards slowly...',
    'Медленно читаю каталожную стойку карт...',
  ),
  'tarot.interpreting.2': L10nTriple(
    'Bu açılımın kart duruşunu yavaş açıyorum...',
    'Opening the card stance of this spread slowly...',
    'Медленно открываю карточную стойку этого расклада...',
  ),
  'astro.live': L10nTriple(
    'Bugünkü burç faslını açıyorum...',
    "Opening today's sign chapter...",
    'Открываю сегодняшнюю главу знака...',
  ),
  'astro.live.1': L10nTriple(
    'Katalogdaki bugünkü ritmi yavaş okuyorum...',
    "Reading today's catalogue rhythm slowly...",
    'Медленно читаю сегодняшний ритм каталога...',
  ),
  'astro.live.2': L10nTriple(
    'Bu burç faslını biraz daha dikkatli açmak lazım...',
    'This sign chapter needs a more careful opening...',
    'Эту главу знака стоит открывать внимательнее...',
  ),
  'star.live': L10nTriple(
    'Arşivdeki kişisel faslı yavaş okuyorum...',
    'I am reading the personal chapter in the archive slowly...',
    'Медленно читаю личную главу в архиве...',
  ),
  'star.live.1': L10nTriple(
    'Şu ayrıntı bence önemli — arşiv yaprağına bakıyorum...',
    'This detail matters — looking at the archive leaf...',
    'Эта подробность важна — смотрю на лист архива...',
  ),
  'star.live.2': L10nTriple(
    'Ben bunu doğrudan böyle yorumlamam; sembolik yolu yavaş okuyorum...',
    'I would not read this that directly; reading the symbolic path slowly...',
    'Так прямо не толкую; медленно читаю символический путь...',
  ),
  'birth.generating.1': L10nTriple(
    'Haritadaki duruşu yavaş okuyorum...',
    'I am reading the chart slowly...',
    'Медленно читаю карту...',
  ),
  'birth.generating.2': L10nTriple(
    'Bu kısmı biraz daha dikkatli okumak lazım...',
    'This part needs a more careful reading...',
    'Эту часть стоит читать внимательнее...',
  ),
};
