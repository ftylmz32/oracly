/// Daily ritual reflection pools — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nDailyRitual = <String, L10nTriple>{
  'ritual.teaser.quiet': L10nTriple(
    'Bugün için sessiz bir düşünce hazır.',
    'A quiet thought is ready for today.',
    'На сегодня готова тихая мысль.',
  ),
  'ritual.teaser.rare': L10nTriple(
    'Bugün gökyüzünde nadir bir an var. Bir düşünce seni bekliyor.',
    'There is a rare moment in the sky today. A thought is waiting for you.',
    'Сегодня в небе редкий момент. Мысль ждёт тебя.',
  ),
  'ritual.pool.morning_spring.0': L10nTriple(
    'Sabahın ilk ışığı acele etmeden dinlemeni ister. Bugün küçük bir adım yeter — kendine nazik ol.',
    'Morning’s first light asks you to listen without hurry. One small step is enough today — be gentle with yourself.',
    'Первый свет утра просит слушать без спешки. Сегодня довольно одного маленького шага — будь мягок к себе.',
  ),
  'ritual.pool.morning_spring.1': L10nTriple(
    'Yeni bir gün, temiz bir sayfa değil; devam eden bir hikâye. Nerede kaldığını fark etmen yeterli.',
    'A new day is not a blank page; it is a continuing story. Noticing where you left off is enough.',
    'Новый день — не чистая страница; продолжающаяся история. Достаточно заметить, где ты остановился.',
  ),
  'ritual.pool.morning_spring.2': L10nTriple(
    'Baharın nefesi gibi: büyümek için baskı gerekmez. Sadece açılmak.',
    'Like spring’s breath: growth needs no pressure. Only opening.',
    'Как дыхание весны: для роста не нужно давление. Только раскрытие.',
  ),
  'ritual.pool.morning_summer.0': L10nTriple(
    'Gün parlak olsa da iç sesin fısıltı kadar değerli. Bir an durup dinle.',
    'Even on a bright day, your inner voice is as valuable as a whisper. Pause and listen.',
    'Даже в яркий день внутренний голос ценен, как шёпот. Остановись и послушай.',
  ),
  'ritual.pool.morning_summer.1': L10nTriple(
    'Sabah temposu dağılmadan önce kendine bir cümle ayır. Bu yeter.',
    'Before morning’s pace scatters, keep one sentence for yourself. That is enough.',
    'Пока утренний темп не рассеялся, оставь себе одну фразу. Этого довольно.',
  ),
  'ritual.pool.morning_summer.2': L10nTriple(
    'Bugün her şeyi çözmek zorunda değilsin. Sadece ne hissettiğine bak.',
    'You need not solve everything today. Just look at what you feel.',
    'Сегодня не нужно всё решать. Просто посмотри, что чувствуешь.',
  ),
  'ritual.pool.morning_autumn.0': L10nTriple(
    'Sonbahar gibi: bırakmak da bir tür büyümek. Bugün neyi hafifletebilirsin?',
    'Like autumn: letting go is also a kind of growth. What can you lighten today?',
    'Как осень: отпустить — тоже вид роста. Что сегодня можно облегчить?',
  ),
  'ritual.pool.morning_autumn.1': L10nTriple(
    'Sabah sessizliği, dünün yükünü taşımadan başlaman için bir davet.',
    'Morning quiet is an invitation to begin without carrying yesterday’s weight.',
    'Утренняя тишина — приглашение начать, не неся вчерашний груз.',
  ),
  'ritual.pool.morning_autumn.2': L10nTriple(
    'Değişim korkutucu olabilir — ama sen değişimin içindesin, dışında değil.',
    'Change can feel frightening — but you are inside it, not outside it.',
    'Перемены могут пугать — но ты внутри них, не снаружи.',
  ),
  'ritual.pool.morning_winter.0': L10nTriple(
    'Kış sabahları yavaşlatır. Bu yavaşlık bir eksiklik değil, bir lütuf.',
    'Winter mornings slow you down. That slowness is not a lack; it is a gift.',
    'Зимние утра замедляют. Эта медленность — не недостаток, а дар.',
  ),
  'ritual.pool.morning_winter.1': L10nTriple(
    'Soğuk hava dışarıda; sıcaklık içeride aranır. Bugün kendine sığınak ol.',
    'Cold air is outside; warmth is sought inside. Be a shelter for yourself today.',
    'Холод снаружи; тепло ищут внутри. Сегодня будь себе убежищем.',
  ),
  'ritual.pool.morning_winter.2': L10nTriple(
    'Kısa günler uzun düşüncelere yer açar. Bir nefes al, gerisi bekleyebilir.',
    'Short days make room for longer thoughts. Take one breath; the rest can wait.',
    'Короткие дни дают место длинным мыслям. Сделай вдох; остальное может подождать.',
  ),
  'ritual.pool.afternoon.0': L10nTriple(
    'Günün ortasında durmak lüks değil, ihtiyaç. Şu an tam buradasın — bu yeterli.',
    'Pausing midday is not a luxury; it is a need. You are right here now — that is enough.',
    'Остановиться в середине дня — не роскошь, а нужда. Ты сейчас здесь — этого довольно.',
  ),
  'ritual.pool.afternoon.1': L10nTriple(
    'Öğleden sonra yorgunluğu normal. Kendini zorlamadan bir an geri çekil.',
    'Afternoon tiredness is normal. Step back for a moment without forcing yourself.',
    'Послеобеденная усталость нормальна. На миг отступи, не принуждая себя.',
  ),
  'ritual.pool.afternoon.2': L10nTriple(
    'Bugün şimdiye kadar ne yaptığın kadar, ne hissettiğin de önemli.',
    'What you have done so far today matters — and so does what you feel.',
    'Важно не только то, что ты уже сделал сегодня, но и то, что чувствуешь.',
  ),
  'ritual.pool.afternoon.3': L10nTriple(
    'Gün devam ediyor ama sen durabilirsin. Bir dakika bile fark yaratır.',
    'The day continues, but you can pause. Even one minute makes a difference.',
    'День продолжается, но ты можешь остановиться. Даже минута меняет многое.',
  ),
  'ritual.pool.evening.0': L10nTriple(
    'Akşam, günü yargılamak için değil, anlamak için gelir. Nazikçe bak.',
    'Evening comes to understand the day, not to judge it. Look gently.',
    'Вечер приходит понять день, а не судить его. Смотри мягко.',
  ),
  'ritual.pool.evening.1': L10nTriple(
    'Gün biterken ne kaldığını değil, ne öğrendiğini düşün — küçük de olsa.',
    'As the day ends, think of what you learned — even if it is small — not only what remains.',
    'Когда день кончается, думай о том, чему научился — пусть малому — а не только о том, что осталось.',
  ),
  'ritual.pool.evening.2': L10nTriple(
    'Alacakaranlık geçişlerin rengidir. Sen de bir geçişin içindesin.',
    'Twilight is the colour of transitions. You are inside one too.',
    'Сумерки — цвет переходов. Ты тоже внутри перехода.',
  ),
  'ritual.pool.evening.3': L10nTriple(
    'Bugün mükemmel olmak zorunda değildi. Yeterince insandın.',
    'Today did not need to be perfect. You were human enough.',
    'Сегодня не должно было быть идеальным. Ты был достаточно человеком.',
  ),
  'ritual.pool.night.0': L10nTriple(
    'Gece, cevap aramak için değil — dinlenmek için. Zihnin yavaşlayabilir.',
    'Night is for rest, not for hunting answers. Your mind can slow.',
    'Ночь — для отдыха, не для поиска ответов. Ум может замедлиться.',
  ),
  'ritual.pool.night.1': L10nTriple(
    'Karanlık bir tehdit değil; düşüncelerin sakinleştiği bir örtü.',
    'Darkness is not a threat; it is a cover where thoughts settle.',
    'Темнота — не угроза; покров, в котором мысли утихают.',
  ),
  'ritual.pool.night.2': L10nTriple(
    'Uyumadan önce bir cümle yazmak, zihni hafifletir. Zorunlu değil — davet.',
    'Writing one sentence before sleep lightens the mind. Not required — an invitation.',
    'Одна фраза перед сном облегчает ум. Не обязанность — приглашение.',
  ),
  'ritual.pool.night.3': L10nTriple(
    'Gece geç saatlerde burada olmak da bir tercih. Kendine yargı yok.',
    'Being here late at night is also a choice. No judgment toward yourself.',
    'Быть здесь поздней ночью — тоже выбор. Без суда к себе.',
  ),
  'ritual.pool.full_moon.0': L10nTriple(
    'Dolunay aydınlatır ama kör etmez. Bugün gördüklerine güven — ama acele etme.',
    'The full moon lights without blinding. Trust what you see today — without rushing.',
    'Полнолуние освещает, но не ослепляет. Доверься увиденному сегодня — без спешки.',
  ),
  'ritual.pool.full_moon.1': L10nTriple(
    'Dolunay geceleri duygular yükselir. Bu dalga seni sürüklemek zorunda değil.',
    'On full-moon nights feelings rise. That wave need not carry you away.',
    'В полнолуние чувства поднимаются. Эта волна не обязана уносить тебя.',
  ),
  'ritual.pool.full_moon.2': L10nTriple(
    'Parlak bir gece; iç sesin de duyulabilir. Dinle, ama karar vermek zorunda değilsin.',
    'A bright night; your inner voice can be heard too. Listen, but you need not decide.',
    'Яркая ночь; внутренний голос тоже слышен. Слушай, но решать не обязан.',
  ),
  'ritual.pool.shooting_star.0': L10nTriple(
    'Nadir bir an: gökyüzü kısa bir selam verdi. Bugün küçük mucizelere açık ol.',
    'A rare moment: the sky offered a brief greeting. Stay open to small wonders today.',
    'Редкий момент: небо коротко поздоровалось. Будь открыт маленьким чудесам сегодня.',
  ),
  'ritual.pool.shooting_star.1': L10nTriple(
    'Kayan yıldızlar geçicidir — tıpkı bu an gibi. Burada olman yeterli.',
    'Shooting stars are brief — like this moment. Being here is enough.',
    'Падающие звёзды мимолётны — как этот миг. Быть здесь довольно.',
  ),
  'ritual.pool.shooting_star.2': L10nTriple(
    'Kısa bir parıltı geçti. Cevap beklemek zorunda değilsin; sadece bak.',
    'A short gleam passed. You need not wait for an answer; just look.',
    'Короткий блеск прошёл. Не обязан ждать ответа; просто смотри.',
  ),
};
