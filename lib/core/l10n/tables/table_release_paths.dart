/// Critical release-path chrome — Splash, Premium plans, Tarot panels, reading flow.
library;

import '../l10n_triple.dart';

const kL10nReleasePaths = <String, L10nTriple>{
  'splash.tagline': L10nTriple(
    'Bir an dur. Kendini dinle.',
    'Pause for a moment. Listen to yourself.',
    'Остановись на мгновение. Прислушайся к себе.',
  ),
  'premium.plans_section': L10nTriple(
    'ÜYELİK PLANI',
    'MEMBERSHIP PLAN',
    'ПЛАН ПОДПИСКИ',
  ),
  'premium.plan_name.monthly': L10nTriple(
    'Aylık',
    'Monthly',
    'Месячный',
  ),
  'premium.plan_name.yearly': L10nTriple(
    'Yıllık',
    'Yearly',
    'Годовой',
  ),
  'premium.plan_name.lifetime': L10nTriple(
    'Ömür Boyu',
    'Lifetime',
    'Навсегда',
  ),
  'premium.plan_period.monthly': L10nTriple(
    'Aylık fatura',
    'Billed monthly',
    'Ежемесячная оплата',
  ),
  'premium.plan_period.yearly': L10nTriple(
    'Yıllık fatura',
    'Billed yearly',
    'Ежегодная оплата',
  ),
  'premium.plan_period.lifetime': L10nTriple(
    'Tek seferlik',
    'One-time',
    'Разовый платёж',
  ),
  'reading.flow.breath': L10nTriple(
    'Bir an nefes al…',
    'Take a breath…',
    'Сделай вдох…',
  ),
  'reading.flow.preparing': L10nTriple(
    'Yorumun sakin bir tempoda açılıyor.',
    'Your reading opens at a calm pace.',
    'Толкование открывается спокойным темпом.',
  ),
  'reading.flow.reveal_missing': L10nTriple(
    'Açılım oturumu bulunamadı. Lütfen yeniden başla.',
    'The spread session was not found. Please start again.',
    'Сеанс расклада не найден. Пожалуйста, начни снова.',
  ),
  'reading.flow.reading_missing': L10nTriple(
    'Yorum yüklenemedi. Açılım oturumu sona ermiş olabilir.',
    'The reading could not load. The spread session may have ended.',
    'Толкование не загрузилось. Сеанс расклада мог завершиться.',
  ),
  'tarot.panel.card_message': L10nTriple(
    'Kart Mesajı',
    'Card Message',
    'Послание карты',
  ),
  'tarot.panel.inner_meaning': L10nTriple(
    'İç Anlam',
    'Inner Meaning',
    'Внутренний смысл',
  ),
  'tarot.panel.guidance': L10nTriple(
    'Rehberlik',
    'Guidance',
    'Опора',
  ),
  'tarot.panel.daily_reflection': L10nTriple(
    'Günün Yansıması',
    "Day's Reflection",
    'Отражение дня',
  ),
  'tarot.continue.title': L10nTriple(
    'Okumaya Devam Et',
    'Continue Reading',
    'Продолжить чтение',
  ),
  'tarot.continue.all': L10nTriple(
    'Tümü',
    'All',
    'Все',
  ),
  'tarot.action.do_spread': L10nTriple(
    'Açılım Yap',
    'Do a Spread',
    'Сделать расклад',
  ),
  'tarot.action.share': L10nTriple(
    'Paylaş',
    'Share',
    'Поделиться',
  ),
  'tarot.history.clear_filter': L10nTriple(
    'Filtreyi temizle',
    'Clear filter',
    'Сбросить фильтр',
  ),
  'tarot.history.personal_archive': L10nTriple(
    'Kişisel Arşiv',
    'Personal Archive',
    'Личный архив',
  ),
  'tarot.history.delete_reflection': L10nTriple(
    'Bu yansımayı sil',
    'Delete this reflection',
    'Удалить это отражение',
  ),
  'or.answer.tarot': L10nTriple(
    'Tarot masadaki tabloyu gösterir. Acele bir sonuç çıkarmam — en duran kartı yazarsan onu geleneksel okumayla birlikte bakarız.\n\nKartlar "ne olacak" demez; neyi ertelediğini gösterir. Bir açılım yaptıysan, en çok durduğun kartın kısa anlamını yaz; onu net okuruz.',
    'Tarot shows the table as it sits. I do not rush a conclusion — if you name the card that stays with you, we read it with the traditional meaning.\n\nThe cards do not say what will happen; they show what you postponed. If you drew a spread, write the short meaning of the card you held most; we read it clearly.',
    'Таро показывает стол, как он стоит. Я не тороплю итог — если назовёшь карту, которая держится, прочитаем её с традиционным смыслом.\n\nКарты не говорят, что будет; они показывают, что ты отложил. Если сделал расклад, напиши краткий смысл карты, на которой остановился; прочитаем ясно.',
  ),
  'or.answer.dream': L10nTriple(
    'Rüya, gün içinde taşıdığın duyguyu sembolle anlatır. En net imgeyi veya sahnedeki hissi bir cümleyle yazarsan daha yakından bakarız.\n\nBelirsiz sahneler kaçman gereken bir işaret değil. Anlattığın sahnede duranı söylemen yeter.',
    'A dream tells a feeling you carried through the day in symbols. If you write the clearest image or the feeling in the scene in one sentence, we look closer.\n\nUnclear scenes are not a sign to flee. Naming what sits in the scene you told is enough.',
    'Сон символом рассказывает чувство, которое ты нёс днём. Если одной фразой напишешь самый ясный образ или чувство в сцене, посмотрим ближе.\n\nНеясные сцены — не знак бежать. Достаточно назвать то, что стоит в рассказанной сцене.',
  ),
  'or.answer.astrology': L10nTriple(
    'Astroloji ve yıldızname, güneş ritmin ve gerçekten duran temalarınla okunur. Elinde burç veya son keşif varsa onları doğrudan bağlarız.\n\nBurç yorumu kader cümlesi değil. Tempo tut, büyük riski ertele.',
    'Astrology and Yıldızname are read with your sun rhythm and the themes that actually sit. If you have a sign or a recent discovery, we bind them directly.\n\nA sign reading is not a fate sentence. Hold your pace; postpone large risk.',
    'Астрология и Йылдызнаме читаются по ритму Солнца и темам, что реально стоят. Если есть знак или недавнее открытие, свяжем прямо.\n\nЧтение знака — не фраза судьбы. Держи темп; крупный риск отложи.',
  ),
  'or.answer.coffee': L10nTriple(
    'Kahve falı fincandaki izlerin hikâyesidir. Sembolleri yan yana okurum, sonra geleneği bağlarım.\n\nBir fal baktıysan, en çok durduğun izi yaz; onu geleneksel anlamda açıkça okuruz.',
    'Coffee reading is the story of the marks in the cup. I read the symbols side by side, then bind tradition.\n\nIf you had a reading, write the mark that stayed most; we read it clearly in the traditional sense.',
    'Кофейное чтение — история следов в чашке. Читаю символы рядом, затем связываю традицию.\n\nЕсли было чтение, напиши след, на котором остановился; прочитаем ясно в традиционном смысле.',
  ),
  'or.answer.love': L10nTriple(
    'Aşk alanında bugün net konuşmak, belirsiz bekleyişten daha güçlü. Karşı tarafı tahmin etmek yerine kendi sınırını ve ihtiyacını söylemek bağdaki ısıyı korur.\n\nYalnızsan, acele yeni kapı açma; önce ne istediğini netleştir. Birlikteysen, küçük ve gerçek bir cümle yeter.',
    'In love, speaking clearly today is stronger than waiting in fog. Naming your boundary and need keeps the warmth in the bond better than guessing the other person.\n\nIf you are alone, do not rush a new door; first clarify what you want. If you are together, one small true sentence is enough.',
    'В любви сегодня ясная речь сильнее туманного ожидания. Назвать свою границу и нужду бережёт тепло связи лучше, чем угадывать другого.\n\nЕсли один — не спеши открывать новую дверь; сначала проясни, чего хочешь. Если вместе — достаточно одной маленькой настоящей фразы.',
  ),
  'or.answer.energy': L10nTriple(
    'Şu an sende tempo, yorgunluk veya netlik mi duruyor — onu söyle, oradan okuruz.\n\nAsıl duran: tempo tutmak, bir işi tamamlamak. Kısa bir durak da yeter.',
    'Is tempo, tiredness, or clarity sitting in you now — name it, and we read from there.\n\nWhat sits most: hold pace, finish one task. A short pause is also enough.',
    'Сейчас в тебе темп, усталость или ясность — назови, и оттуда прочитаем.\n\nГлавное: держать темп, закончить одно дело. Короткая пауза тоже довольно.',
  ),
  'or.answer.general': L10nTriple(
    'Bu düşünce bir yön gösteriyor: önce durduğun yeri netleştir, sonra tek görünür adım at.\n\nTarot, astroloji, rüya, yıldızname veya kahve falı hakkında somut bir şey yazarsan daha net yorumlarım.',
    'This thought shows a direction: first clarify where you stand, then take one visible step.\n\nIf you write something concrete about tarot, astrology, a dream, Yıldızname, or coffee, I can read more clearly.',
    'Эта мысль показывает направление: сначала проясни, где стоишь, затем сделай один видимый шаг.\n\nЕсли напишешь что-то конкретное о таро, астрологии, сне, Йылдызнаме или кофе, прочитаю яснее.',
  ),
  'or.answer.unrelated': L10nTriple(
    'Bunu falın içine çekmem. Düz konuşmak da olur.\n\nPratik çıkarım: acele karar yerine bugün tek görünür adım daha doğru. İstersen burç, rüya veya bir açılıma bağlarız.',
    'I will not pull this into a fortune. Plain talk is fine too.\n\nPractical take: one visible step today sits better than a rushed decision. If you like, we can bind a sign, a dream, or a spread.',
    'Не буду втягивать это в гадание. Прямой разговор тоже уместен.\n\nПрактический вывод: сегодня один видимый шаг вернее спешного решения. Если хочешь, свяжем знак, сон или расклад.',
  ),
  'or.answer.memory': L10nTriple(
    'Daha önce bıraktığın bir not: "{note}". Bugünkü düşüncenle bağ kuruyor gibi. Aynı temada acele etme; o nottaki ritmi koru.',
    'A note you left earlier: "{note}". It seems to bind to today’s thought. Do not rush the same theme; keep the rhythm in that note.',
    'Заметка, которую ты оставил раньше: "{note}". Кажется, связана с сегодняшней мыслью. Не спеши в той же теме; держи ритм этой заметки.',
  ),
  'or.answer.memory_none': L10nTriple(
    'Buna net bağlanan bir not bulamadım. Uydurmam — istersen sen yaz, tutarız.',
    'I could not find a note that clearly matches. I will not invent one — you can write it if you want, and we will hold it.',
    'Ясной подходящей заметки не нашёл. Выдумывать не буду — можешь написать, и мы удержим.',
  ),
  'tarot.continue.loading': L10nTriple(
    'Son açılımlar dinleniyor...',
    'Recent spreads are settling...',
    'Недавние расклады утихают...',
  ),
  'tarot.continue.error': L10nTriple(
    'Son açılımlara şu an ulaşılamıyor.',
    'Recent spreads are unavailable right now.',
    'Недавние расклады сейчас недоступны.',
  ),
  'tarot.action.favorite': L10nTriple('Favori', 'Favorite', 'Избранное'),
  'tarot.history.filter_empty': L10nTriple(
    'Bu filtrede açılım bulunamadı.',
    'No spreads found for this filter.',
    'Для этого фильтра раскладов нет.',
  ),
  'tarot.history.journey_since': L10nTriple(
    'Yolculuğun {date}’den beri burada.',
    'Your journey has been here since {date}.',
    'Твой путь здесь с {date}.',
  ),
  'tarot.history.recorded_moment': L10nTriple(
    'Kayıtlı An',
    'Recorded moment',
    'Запись',
  ),
  'tarot.history.this_month': L10nTriple(
    'Bu Ay',
    'This month',
    'В этом месяце',
  ),
  'tarot.history.search_hint': L10nTriple(
    'Açılım veya kart ara...',
    'Search spreads or cards...',
    'Искать расклады или карты...',
  ),
};
