/// OR conversation lines — TR / EN / RU, one personality, four expressions.
library;

import '../l10n_triple.dart';

const kL10nOrCore = <String, L10nTriple>{
  'or.hi.gentle': L10nTriple(
    'Selam. Yer açık.',
    'Hey. There is room.',
    'Привет. Место есть.',
  ),
  'or.hi.mystical': L10nTriple(
    'Selam. Yer açık.',
    'Hey. There is room.',
    'Привет. Место есть.',
  ),
  'or.hi.poetic': L10nTriple(
    'Selam. Konuşmak istersen yer var.',
    'Hey. There is room if you want to talk.',
    'Привет. Если хочешь говорить — место есть.',
  ),
  'or.hi.direct': L10nTriple(
    'Selam. Dinliyorum.',
    'Hey. Listening.',
    'Привет. Слушаю.',
  ),
  'or.hi2.gentle': L10nTriple(
    'Selam yine. Kaldığımız yerden mi?',
    'Hey again. From where we left off?',
    'Привет снова. С того места, где остановились?',
  ),
  'or.hi2.mystical': L10nTriple(
    'Selam. İp hâlâ duruyor — nereden tutalım?',
    'Hey. The thread is still here — where do we take it?',
    'Привет. Нить всё ещё здесь — откуда возьмём?',
  ),
  'or.hi2.poetic': L10nTriple(
    'Yine selam. Nereye devam edelim?',
    'Hey again. Where do we continue?',
    'Снова привет. Куда продолжим?',
  ),
  'or.hi2.direct': L10nTriple(
    'Selam. Asıl konu ne?',
    'Hey. What is the actual subject?',
    'Привет. В чём суть?',
  ),
  'or.mood.gentle': L10nTriple(
    'Neye takıldın — bir cümle yeter.',
    'What are you stuck on — one sentence is enough.',
    'На чём ты застрял — одной фразы достаточно.',
  ),
  'or.mood.mystical': L10nTriple(
    'Neye takıldın — o ağırlık nereden geliyor?',
    'What are you stuck on — where is that weight coming from?',
    'На чём ты застрял — откуда эта тяжесть?',
  ),
  'or.mood.poetic': L10nTriple(
    'Neye takıldın, en çok ne duruyor?',
    'What are you stuck on — what weighs most?',
    'На чём ты застрял — что тяжелее всего?',
  ),
  'or.mood.direct': L10nTriple(
    'Neye takıldın tam olarak?',
    'What exactly are you stuck on?',
    'На чём именно ты застрял?',
  ),
  'or.listen.gentle': L10nTriple(
    'Bunu duydum. Asıl duran yeri bir cümleyle tutmak yeter.',
    'I heard that. Holding the real sticking point in one sentence is enough.',
    'Я это слышу. Удержать настоящее место одной фразой довольно.',
  ),
  'or.listen.mystical': L10nTriple(
    'Bu cümle burada duruyor. İzini kısa bırakman yeter.',
    'That sentence is here. A short trace of it is enough.',
    'Эта фраза здесь. Короткого следа довольно.',
  ),
  'or.listen.poetic': L10nTriple(
    'Anladım. Şimdi asıl duran yer neresi?',
    'Got it. Where is the real sticking point now?',
    'Понял. Где теперь настоящее место, которое стоит?',
  ),
  'or.listen.direct': L10nTriple(
    'Duydum. Asıl cümle ne?',
    'Heard. What is the real sentence?',
    'Слышу. Какая настоящая фраза?',
  ),
  'or.undecided.gentle': L10nTriple(
    'Bu kararsızlık şimdi daha çok işte mi duruyor, yoksa genel olarak mı?',
    'Is this indecision more at work, or more in general?',
    'Эта нерешительность сейчас больше в работе или вообще?',
  ),
  'or.undecided.mystical': L10nTriple(
    'Kararsızlık henüz adını koymadığın bir yerde. İş tarafında mı, yoksa daha geniş mi?',
    'The indecision has not named its place yet. Work, or something wider?',
    'Нерешительность ещё не назвала место. В работе или шире?',
  ),
  'or.undecided.poetic': L10nTriple(
    'Anladım, bugün net durmuyor. İş mi ağır geliyor, yoksa her şey biraz mı karışık?',
    'Got it — today is not clear. Is work the heavy part, or is everything a bit mixed?',
    'Понял, сегодня не ясно. Работа тяжела или всё немного смешалось?',
  ),
  'or.undecided.direct': L10nTriple(
    'Daha çok iş konusunda mı, yoksa genel olarak mı?',
    'More about work, or in general?',
    'Больше про работу или вообще?',
  ),
  'or.held.gentle': L10nTriple(
    'Tamam — {topic} tarafında duruyoruz. Acele etmeden, orada ne sıkışıyor?',
    'Alright — we are on the {topic} side. Without rushing, what is jammed there?',
    'Хорошо — мы на стороне {topic}. Без спешки, что там застряло?',
  ),
  'or.held.mystical': L10nTriple(
    'O zaman konu {topic}. Oradaki duruşu bir cümleyle tutmak yeter.',
    'Then the subject is {topic}. Holding the stance there in one sentence is enough.',
    'Значит тема — {topic}. Удержать тамошнюю стойку одной фразой довольно.',
  ),
  'or.held.poetic': L10nTriple(
    'Anladım, {topic} tarafı. Orada seni en çok ne yoruyor?',
    'Got it, the {topic} side. What is tiring you most there?',
    'Понял, сторона {topic}. Что там тебя больше всего утомляет?',
  ),
  'or.held.direct': L10nTriple(
    '{topic} tamam. Asıl sıkışma ne?',
    '{topic} — got it. What is actually jammed?',
    '{topic} ясно. В чём настоящее застревание?',
  ),
  'or.switched.gentle': L10nTriple(
    'Peki, yeni konuya geçelim. Şimdi ne duruyor?',
    'Alright, we move. What’s here now?',
    'Хорошо, переходим. Что стоит теперь?',
  ),
  'or.switched.mystical': L10nTriple(
    'Sayfa değişti. Şimdi hangi iz önde?',
    'The page turned. Which trace is in front now?',
    'Страница сменилась. Какой след теперь впереди?',
  ),
  'or.switched.poetic': L10nTriple(
    'Tamam, başka yere bakalım. Ne var aklında?',
    'Alright, another place. What is on your mind?',
    'Ладно, посмотрим в другое место. Что у тебя в уме?',
  ),
  'or.switched.direct': L10nTriple(
    'Konu değişti. Yeni olan ne?',
    'Subject changed. What is new?',
    'Тема сменилась. Что новое?',
  ),
  'or.cont.gentle': L10nTriple(
    'Hâlâ {topic} tarafındayız. Bunu biraz daha açmana yer var.',
    'We are still on the {topic} side. There is room to open this a little more.',
    'Мы всё ещё на стороне {topic}. Есть место чуть открыть это.',
  ),
  'or.cont.mystical': L10nTriple(
    '{topic} hâlâ açık. Yeni cümleyi oraya bırakman yeter.',
    '{topic} is still open. Leaving the new sentence there is enough.',
    '{topic} всё ещё открыта. Оставить новую фразу там довольно.',
  ),
  'or.cont.poetic': L10nTriple(
    'Anladım, hâlâ {topic}. Orada şimdi ne var?',
    'Got it — still {topic}. What is there now?',
    'Понял, всё ещё {topic}. Что там сейчас?',
  ),
  'or.cont.direct': L10nTriple(
    '{topic} duruyor. Asıl cümle ne?',
    '{topic} is still here. What is the real sentence?',
    '{topic} стоит. Какая настоящая фраза?',
  ),
  'or.fear.gentle': L10nTriple(
    'Hâlâ {topic} tarafındayız. Değişmekten korkmak da orada duruyor — tam olarak ne durduruyor?',
    'We are still on the {topic} side. Fear of changing sits there too — what exactly is stopping you?',
    'Мы всё ещё на стороне {topic}. Страх меняться тоже там здесь — что именно тебя держит?',
  ),
  'or.fear.mystical': L10nTriple(
    '{topic} konusunda duruyoruz. Değişmenin korkusu o duruşun yanında — hangi ağırlık önde?',
    'We are on {topic}. The fear of changing stands beside that stance — which weight is in front?',
    'Мы на теме {topic}. Страх перемены стоит рядом с этой стойкой — какая тяжесть впереди?',
  ),
  'or.fear.poetic': L10nTriple(
    'Anladım — {topic} tarafındaki kararsızlık, değişmek korkusuyla duruyor. Hangisi daha yakın?',
    'Got it — the indecision on the {topic} side carries fear of change. Which is closer?',
    'Понял — нерешительность на стороне {topic} стоит со страхом перемены. Что ближе?',
  ),
  'or.fear.direct': L10nTriple(
    '{topic} ve değişme korkusu aynı düğüm. Hangisi önde?',
    '{topic} and the fear of changing are the same knot. Which is in front?',
    '{topic} и страх меняться — один узел. Что впереди?',
  ),
  'or.insuff': L10nTriple(
    'Bunu kesin söylemek için yeterli veri yok.',
    'There is not enough here to say that for certain.',
    'Чтобы сказать это наверняка, данных мало.',
  ),
  'or.predict': L10nTriple(
    'Bunu kesin söyleyemem. Elindeki işaretleri birlikte okuyabiliriz.',
    'I cannot say that for certain. We can read the signs you have, together.',
    'Этого наверняка не скажу. Знаки, что у тебя есть, можем прочесть вместе.',
  ),
  'or.advice': L10nTriple(
    'Emir yok. Sıkışanı bir cümlede yaz; küçük bir sonraki adımı dene — kararı acele etme.',
    'No orders. Name what is stuck in one sentence; try a small next step — do not rush the decision.',
    'Приказа нет. Назови затор одной фразой; сделай маленький шаг — решение не торопи.',
  ),
  'or.advice_topic': L10nTriple(
    '{topic} konusunda buyruk yok. Sıkışanı yaz; iki hafta küçük bir deneme (konuşma, araştırma) yeter.',
    'No command on {topic}. Name the jam; two weeks of a small trial (a talk, some research) is enough.',
    'По теме {topic} приказа нет. Назови затор; двух недель маленькой пробы (разговор, поиск) хватит.',
  ),
  'or.disagree': L10nTriple(
    'Katılmıyorum. Bunu bu kadar kesin kurmak için zemin ince — başka yollar da duruyor.',
    'I disagree. The ground is thin for that certainty — other paths are still open.',
    'Не согласен. Для такой уверенности почва тонкая — есть и другие пути.',
  ),
  'or.direct.slow': L10nTriple(
    'Burada acele var. Bir adım yavaşlamak, yanlış kapıyı zorlamaktan daha sağlam durur.',
    'There is rush here. Slowing one step is sturdier than forcing the wrong door.',
    'Здесь спешка. Замедлиться на шаг надёжнее, чем ломиться не в ту дверь.',
  ),
  'or.direct.overthink': L10nTriple(
    'Bu tur fazla düşünmeye kayıyor. Bir cümlede asıl takılanı yaz; gerisini şimdilik kenara bırak.',
    'This turn is tipping into overthinking. Name the real jam in one sentence; leave the rest aside for now.',
    'Этот ход уходит в зацикливание. Назови затор одной фразой; остальное пока в сторону.',
  ),
  'or.direct.unconvincing': L10nTriple(
    'Bu kadar kesin durmuyor. Zemin ince — iddiayı biraz daha somut tutmak daha dürüst olur.',
    'That does not look convincing enough. The ground is thin — keeping the claim more concrete would be more honest.',
    'Это не выглядит убедительно. Почва тонкая — держать тезис конкретнее было бы честнее.',
  ),
  'or.medical': L10nTriple(
    'Buna kesin diyemem — ve ölüm ya da hastalık cümlesi kurmam. İzler sembolik okunur; ispattan değil, o çerçeveden konuşabiliriz.',
    'I cannot say that for certain — and I will not make a death or illness claim. Marks are read symbolically; we can talk in that frame, not as a verdict.',
    'Этого наверняка не скажу — и фразы про смерть или болезнь не будет. Следы читают символически; можем говорить в этой рамке, не как приговор.',
  ),
  'or.python': L10nTriple(
    'Python\'da async, işi kilitleyip beklemek yerine beklerken başka işe izin verir. `async def` bir coroutine tanımlar; `await` sonucu bekler, thread\'i dondurmaz. Event loop sıradaki hazır işi alır — fal değil, çalışma modeli bu.',
    'In Python, async lets other work run while one task waits. `async def` defines a coroutine; `await` waits for the result without freezing the thread. The event loop picks up the next ready job — that is the model, not a fortune.',
    'В Python async разрешает другую работу, пока одна задача ждёт. `async def` задаёт корутину; `await` ждёт результат, не замораживая поток. Цикл событий берёт следующее готовое дело — это модель работы, не гадание.',
  ),
  'or.knowledge': L10nTriple(
    'Bu konuda net konuşabilirim. Tam olarak hangi parçası takıldı?',
    'I can speak clearly on this. Which part exactly is stuck?',
    'Об этом могу говорить ясно. Какая именно часть застряла?',
  ),
  'or.boss': L10nTriple(
    'Patronunla tartışmak yorucu olur. Bence burada asıl mesele o anda neyin kırıldığı. Ne takıldı tam olarak?',
    'A fight with a boss wears you down. I think the real matter is what broke in that moment. What exactly got stuck?',
    'Спор с начальником утомляет. Думаю, суть в том, что сломалось в тот момент. Что именно застряло?',
  ),
  'or.repeat': L10nTriple(
    'Peki, başka bir yerden bakalım. Şimdi ne duruyor?',
    'Alright, from another angle. What’s here now?',
    'Ладно, с другого места. Что стоит сейчас?',
  ),
  
  'or.resume.gentle': L10nTriple(
    'Selam yine. {topic} ipi hâlâ duruyor — kaldığımız yerden tutabiliriz.',
    'Hey again. The {topic} thread is still here — we can take it from where we left.',
    'Снова привет. Нить {topic} всё ещё здесь — можем взять с того места.',
  ),
  'or.resume.mystical': L10nTriple(
    'Selam. {topic} izi duruyor; kaldığımız yerden tutabiliriz.',
    'Hey. The {topic} trace is still here; we can take it from where we left.',
    'Привет. След {topic} стоит; можем взять с того места.',
  ),
  'or.resume.poetic': L10nTriple(
    'Yine selam. {topic} tarafı açık — kaldığımız yerden devam edebiliriz.',
    'Hey again. The {topic} side is open — we can continue from where we left.',
    'Снова привет. Сторона {topic} открыта — можем продолжить с того места.',
  ),
  'or.resume.direct': L10nTriple(
    'Selam. {topic} ipi duruyor — kaldığımız yerden.',
    'Hey. The {topic} thread is here — from where we left.',
    'Привет. Нить {topic} здесь — с того места.',
  ),
'or.angle': L10nTriple(
    'Başka bir açıdan: ne tam olarak sıkışıyor?',
    'From another angle: what exactly is jammed?',
    'С другого угла: что именно застряло?',
  ),
  'or.job.gentle': L10nTriple(
    'Ne zamandır bunu düşünüyorsun?',
    'How long have you been with this?',
    'Как давно ты это обдумываешь?',
  ),
  'or.job.mystical': L10nTriple(
    'Ne zamandır bu eşik orada duruyor?',
    'How long has this threshold been there?',
    'Как давно этот порог там стоит?',
  ),
  'or.job.poetic': L10nTriple(
    'Anladım. Ne zamandır aklında bu?',
    'Got it. How long has this been on your mind?',
    'Понял. Как давно это у тебя в уме?',
  ),
  'or.job.direct': L10nTriple(
    'Ne zamandır?',
    'Since when?',
    'С каких пор?',
  ),
  'or.detail.gentle': L10nTriple(
    'Hâlâ {topic} tarafındayız. Az önce açtığın yerden bakınca, asıl sıkışma hangisi?',
    'We are still on the {topic} side. From what you just opened, which jam is the real one?',
    'Мы всё ещё на стороне {topic}. Из того, что ты только что открыл, в чём настоящее застревание?',
  ),
  'or.detail.mystical': L10nTriple(
    '{topic} hâlâ duruyor. Söylediğin ayrıntı o damarda — hangisi önde?',
    '{topic} is still here. The detail you named rests on that vein — which is in front?',
    '{topic} всё ещё стоит. Названная тобой подробность на этой жиле — что впереди?',
  ),
  'or.detail.poetic': L10nTriple(
    'Anladım, hâlâ {topic}. Söylediğin yerden devam: orada asıl duran ne?',
    'Got it — still {topic}. From what you said: what actually sits there?',
    'Понял, всё ещё {topic}. С того места, что ты сказал: что там стоит на самом деле?',
  ),
  'or.detail.direct': L10nTriple(
    '{topic} duruyor. Söylediğin yerde asıl sıkışma ne?',
    '{topic} is still here. In what you just said, what is actually jammed?',
    '{topic} стоит. В том, что ты сказал, в чём настоящее застревание?',
  ),
  'or.fear_clarify.gentle': L10nTriple(
    'Hâlâ {topic} tarafındayız. Değişmekten mi korkuyorsun, yoksa yanlış karar vermekten mi?',
    'We are still on the {topic} side. Is it fear of changing, or fear of choosing wrong?',
    'Мы всё ещё на стороне {topic}. Страх перемен или страх ошибиться?',
  ),
  'or.fear_clarify.mystical': L10nTriple(
    '{topic} hâlâ açık. Değişimin korkusu mu, yoksa yanlış adımın ağırlığı mı önde?',
    '{topic} is still open. The fear of change, or the weight of a wrong step — which is in front?',
    '{topic} всё ещё открыта. Страх перемены или тяжесть неверного шага — что впереди?',
  ),
  'or.fear_clarify.poetic': L10nTriple(
    'Anladım — {topic} tarafında duruyorsun. Değişmek mi korkutuyor, yanlış karar mı?',
    'Got it — you are standing on the {topic} side. Is it change that scares you, or a wrong choice?',
    'Понял — ты стоишь на стороне {topic}. Пугает перемена или неверный выбор?',
  ),
  'or.fear_clarify.direct': L10nTriple(
    'Değişmekten mi korkuyorsun, yanlış karar vermekten mi?',
    'Afraid of changing, or of choosing wrong?',
    'Боишься меняться или ошибиться?',
  ),
  'or.reflect.gentle': L10nTriple(
    'Hâlâ {topic} tarafındayız. Az önce söylediğin cümle orada duruyor — acele etmene gerek yok.',
    'We are still on the {topic} side. What you just said sits there — no need to rush.',
    'Мы всё ещё на стороне {topic}. То, что ты сказал, стоит там — спешить не нужно.',
  ),
  'or.reflect.mystical': L10nTriple(
    '{topic} hâlâ açık. Yeni cümle o izde duruyor; bir süre orada kalabilirsin.',
    '{topic} is still open. The new sentence rests on that trace; you can stay there a while.',
    '{topic} всё ещё открыта. Новая фраза стоит на этом следе — можешь побыть там.',
  ),
  'or.reflect.poetic': L10nTriple(
    'Anladım — hâlâ {topic}. Söylediğin yer orada; bir cümle daha eklemene gerek yok.',
    'Got it — still {topic}. What you named is there; you do not need another sentence yet.',
    'Понял — всё ещё {topic}. Названное место там; второй фразы пока не нужно.',
  ),
  'or.reflect.direct': L10nTriple(
    '{topic} duruyor. Söylediğin cümle yeterli.',
    '{topic} is still here. What you said is enough for now.',
    '{topic} стоит. Сказанного достаточно.',
  ),
};
