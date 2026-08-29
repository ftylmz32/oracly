/// Onboarding, first session, home phrases — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nHome = <String, L10nTriple>{
  'onboard.skip': L10nTriple('Atla', 'Skip', 'Пропустить'),
  'onboard.continue': L10nTriple('Devam', 'Continue', 'Продолжить'),
  'onboard.start': L10nTriple(
    'İlk keşfine başla',
    'Begin your first discovery',
    'Начни первое открытие',
  ),
  'onboard.meet': L10nTriple(
    'Seni tanıyalım',
    'A short hello',
    'Давай познакомимся',
  ),
  'onboard.first_hint': L10nTriple(
    'Ana sayfada bugünün kartı seni bekliyor — bir dakikadan kısa.',
    'On Home, today’s card is waiting — less than a minute.',
    'На главной ждёт карта дня — меньше минуты.',
  ),
  'onboard.p0.title': L10nTriple('ORACLY', 'ORACLY', 'ORACLY'),
  'onboard.p0.sub': L10nTriple(
    'Kendini farklı pencerelerden keşfet.',
    'Discover yourself through different windows.',
    'Открой себя через разные окна.',
  ),
  'onboard.p0.or_hint': L10nTriple(
    'Sakin bir yol arkadaşın',
    'A quiet companion',
    'Тихий спутник',
  ),
  'onboard.honesty': L10nTriple(
    'Kehanet değil. Yorum bir davet — karar senin.',
    'Not fortune-telling. A reading is an invitation — the choice is yours.',
    'Это не предсказание. Толкование — приглашение; решение твоё.',
  ),
  'onboard.gems_whisper': L10nTriple(
    'Birkaç taş seni bekliyor — ilk keşif için yeter.',
    'A few gems await — enough for a first discovery.',
    'Несколько камней ждут — хватит на первое открытие.',
  ),
  'onboard.windows_label': L10nTriple(
    'Keşif pencereleri',
    'Discovery windows',
    'Окна открытий',
  ),
  'onboard.window.coffee': L10nTriple('Kahve', 'Coffee', 'Кофе'),
  'onboard.window.palm': L10nTriple('El', 'Palm', 'Ладонь'),
  'onboard.window.sky': L10nTriple('Gökyüzü', 'Sky', 'Небо'),
  'onboard.window.star': L10nTriple('Yıldızname', 'Yıldızname', 'Йылдызнаме'),
  'onboard.window.tarot': L10nTriple('Tarot', 'Tarot', 'Таро'),
  'onboard.window.dream': L10nTriple('Rüyalar', 'Dreams', 'Сны'),
  'onboard.window.or': L10nTriple('OR', 'OR', 'OR'),
  'onboard.p1.title': L10nTriple(
    'Nasıl çalışır?',
    'How it works',
    'Как это работает',
  ),
  'onboard.p1.sub': L10nTriple(
    'Bir keşif aç. Bir an dur. Yorum bir davettir — acele yok.',
    'Open a discovery. Pause. The reading is an invitation — no rush.',
    'Открой исследование. Остановись. Толкование — приглашение, без спешки.',
  ),
  'onboard.p2.title': L10nTriple(
    'Ne değildir?',
    'What it is not',
    'Чем это не является',
  ),
  'onboard.p2.sub': L10nTriple(
    'Kehanet değil. Aciliyet yok. Yorumlar bir davet — karar senin. İlk keşfin bir dakikadan kısa.',
    'Not fortune-telling. No urgency. Readings are an invitation — the choice is yours. Your first discovery takes less than a minute.',
    'Это не предсказание. Нет спешки. Толкования — приглашение; решение твоё. Первое открытие занимает меньше минуты.',
  ),
  'onboard.setup_title': L10nTriple(
    'Seni biraz tanıyalım',
    'Let us know you a little',
    'Давай немного познакомимся',
  ),
  'onboard.setup_sub': L10nTriple(
    'Kişisel bir dokunuş — hepsi isteğe bağlı.',
    'A personal touch — all optional.',
    'Личный штрих — всё по желанию.',
  ),
  'onboard.story_whisper': L10nTriple(
    'Hikâyen burada yavaşça birikir.',
    'Your story gathers here, slowly.',
    'Твоя история собирается здесь, медленно.',
  ),
  'onboard.style_label': L10nTriple(
    'OR nasıl konuşsun?',
    'How should OR speak?',
    'Как OR будет говорить?',
  ),
  'onboard.language_label': L10nTriple('Dil', 'Language', 'Язык'),
  'onboard.name_label': L10nTriple('Adın', 'Your name', 'Твоё имя'),
  'onboard.name_help': L10nTriple(
    'İstersen adını ekle; OR sohbet ederken sana hitap edebilir.',
    'If you want, add your name—OR can address you during chat.',
    'Если хочешь, укажи имя — OR может обращаться к тебе в разговорах.',
  ),
  'onboard.birth_label': L10nTriple(
    'Doğum tarihi',
    'Birth date',
    'Дата рождения',
  ),
  'onboard.birth_help': L10nTriple(
    'Gökyüzü ve Yıldızname için kullanılır. Diğer keşifler için gerekmez.',
    'Used for Sky and Yıldızname. Other discoveries do not need it.',
    'Нужна для Неба и Йылдызнаме. Другим открытиям она не требуется.',
  ),
  'onboard.birth_city_help': L10nTriple(
    'Doğum şehri isteğe bağlıdır. Şimdilik hesabın içine katılmıyor.',
    'Birth city is optional. For now, it is not included in the reading.',
    'Город рождения опционален. Пока он не учитывается в чтении.',
  ),
  'onboard.birth_unspecified': L10nTriple(
    'Belirtilmedi',
    'Not specified',
    'Не указано',
  ),
  'onboard.birth_pick': L10nTriple('Seç', 'Choose', 'Выбрать'),
  'onboard.language_help': L10nTriple(
    'Dil seçimi, ekran metinlerini ve OR üslubunu etkiler.',
    'Language selection affects screen text and OR tone.',
    'Выбор языка влияет на текст на экране и тон OR.',
  ),
  'onboard.style_help': L10nTriple(
    'OR üslubu, yanıtların sıcaklığını ve hızını ayarlar.',
    'OR style sets the warmth and pacing of replies.',
    'Стиль OR задаёт теплоту и темп ответов.',
  ),
  'first.home_greeting': L10nTriple(
    'Hoş geldin,',
    'Welcome,',
    'Добро пожаловать,',
  ),
  'first.guest': L10nTriple('Yolcu', 'Traveler', 'Путник'),
  'first.sub_new': L10nTriple(
    'Günün Kartı ile başla. Bu bir kehanet değil — düşünmek için bir davet.',
    'Start with today’s card. This is not a prediction — an invitation to think.',
    'Начни с карты дня. Это не предсказание — приглашение подумать.',
  ),
  'first.sub_return': L10nTriple(
    'Kaldığın yerden devam edebilirsin.',
    'You can continue where you left off.',
    'Можно продолжить с того места, где остановился.',
  ),
  'first.soulmate_later': L10nTriple(
    'Önce bugünün ücretsiz kartıyla başla — Ruh Eşi sonra açılır.',
    'Start with today’s free card — Soul Mate opens later.',
    'Начни с сегодняшней бесплатной карты — родственная душа позже.',
  ),
  'first.continuity_invite': L10nTriple(
    'İlk kartın, {card}, hâlâ burada. Sen ve OR birlikte bakmaya başlamıştınız.',
    'Your first card, {card}, is still here. You and OR started exploring what it brought up.',
    'Твоя первая карта, {card}, всё ещё здесь. Вы с OR начали разбирать, что она подняла.',
  ),
  'first.continuity_cta': L10nTriple(
    'Sohbetine devam et',
    'Continue your conversation',
    'Продолжить разговор',
  ),
  'home.reference_subtitle': L10nTriple(
    'Sakin bir yer. Düşünmek için buradasın.',
    'A calm place. You are here to think.',
    'Спокойное место. Ты здесь, чтобы думать.',
  ),
  'home.today_moment': L10nTriple('Bugünün İzi', "Today's Trace", 'След дня'),
  'home.hero.hello': L10nTriple('Merhaba,', 'Hello,', 'Привет,'),
  'home.header.premium': L10nTriple('Premium', 'Premium', 'Premium'),
  'home.hero.invite': L10nTriple(
    'Bugün senin için\nneler keşfedelim?',
    'What shall we discover for you today?',
    'Что откроем для тебя сегодня?',
  ),
  'home.or_flagship.title': L10nTriple(
    'OR ile Sohbet',
    'Talk with OR',
    'Разговор с OR',
  ),
  'home.or_flagship.body': L10nTriple(
    'Sana özel, derin ve samimi bir konuşma seni bekliyor.',
    'A deep, intimate conversation made for you is waiting.',
    'Тебя ждёт глубокий и тёплый разговор, созданный для тебя.',
  ),
  'home.or_flagship.cta': L10nTriple(
    'OR ile Başla',
    'Begin with OR',
    'Начать с OR',
  ),
  'home.today_continue': L10nTriple(
    'Devamını Keşfet',
    'Discover more',
    'Узнать дальше',
  ),
  'home.discoveries_band': L10nTriple('Keşfet', 'Explore', 'Обзор'),
  'home.discoveries.see_all': L10nTriple(
    'Tümünü Gör',
    'See all',
    'Смотреть все',
  ),
  'home.today_moment.first': L10nTriple(
    'Günün Kartı ile başlamak yeterli.',
    'Starting with today’s card is enough.',
    'Достаточно начать с карты дня.',
  ),
  'home.hello.morning': L10nTriple(
    'İyi sabahlar',
    'Good morning',
    'Доброе утро',
  ),
  'home.hello.afternoon': L10nTriple(
    'İyi günler',
    'Good afternoon',
    'Добрый день',
  ),
  'home.hello.evening': L10nTriple(
    'İyi akşamlar',
    'Good evening',
    'Добрый вечер',
  ),
  'home.hello.night': L10nTriple('İyi geceler', 'Good night', 'Доброй ночи'),
  'home.ritual.morning': L10nTriple(
    'Güne acele etmeden bak.',
    'Meet the day without rushing.',
    'Встреть день без спешки.',
  ),
  'home.ritual.afternoon': L10nTriple(
    'Bir nefes al, kendine dön.',
    'Take a breath and return to yourself.',
    'Вдохни и вернись к себе.',
  ),
  'home.ritual.evening': L10nTriple(
    'Günü yumuşakça toparla.',
    'Gather the day gently.',
    'Мягко собери день.',
  ),
  'home.ritual.night': L10nTriple(
    'Geceye biraz yer bırak.',
    'Leave a little room for the night.',
    'Оставь ночи немного места.',
  ),
  'home.birthday_greeting': L10nTriple(
    'Bugün senin günün.',
    'Today is your day.',
    'Сегодня твой день.',
  ),
  'home.birthday_body': L10nTriple(
    'Bu günü acele etmeden, kendi ritminle karşıla.',
    'Meet this day without hurry, in your own rhythm.',
    'Встреть этот день без спешки, в своём ритме.',
  ),
  'ritual.title': L10nTriple(
    'Bugünkü Ayin',
    "Today's ritual",
    'Сегодняшний ритуал',
  ),
  'ritual.morning': L10nTriple('Sabah', 'Morning', 'Утро'),
  'ritual.afternoon': L10nTriple('Öğlen', 'Afternoon', 'День'),
  'ritual.evening': L10nTriple('Akşam', 'Evening', 'Вечер'),
  'ritual.night': L10nTriple('Gece', 'Night', 'Ночь'),
  'ritual.teaser_event': L10nTriple(
    'Bugün gökyüzünde nadir bir an var. Bir düşünce seni bekliyor.',
    'There is a rare moment in the sky today. A thought is waiting.',
    'Сегодня на небе редкий миг. Мысль ждёт тебя.',
  ),
  'ritual.teaser': L10nTriple(
    'Bugün için sessiz bir düşünce hazır.',
    'A quiet thought is ready for today.',
    'На сегодня готова тихая мысль.',
  ),
  'ritual.closing': L10nTriple(
    'Gözlemevi sakinleşiyor. Döndüğünde yine burada olacak.',
    'The observatory grows quiet. It will be here when you return.',
    'Обсерватория утихает. Она будет здесь, когда вернёшься.',
  ),
  'ritual.card_of_day.title': L10nTriple(
    'Günün Kartı',
    'Card of the Day',
    'Карта дня',
  ),
  'ritual.card_of_day.draw': L10nTriple(
    'Kart çek',
    'Draw a card',
    'Вытянуть карту',
  ),
  'ritual.card_of_day.open': L10nTriple(
    'Günün kartını aç',
    'Open today’s card',
    'Открыть карту дня',
  ),
  'ritual.card_of_day.or': L10nTriple(
    'OR ile aç',
    'Open with OR',
    'Открыть с OR',
  ),
  'ritual.card_of_day.guidance': L10nTriple(
    'Günün sembolik yönü',
    'Today’s symbolic guidance',
    'Символическое направление дня',
  ),
  'ritual.card_of_day.honesty': L10nTriple(
    'Bu bir yansıma — garanti bir gelecek değildir.',
    'This is a reflection — not a guaranteed future.',
    'Это отражение — не гарантированное будущее.',
  ),
  'home.phrase.0': L10nTriple(
    'Bugün sessiz kalmak zorunda değilsin.',
    'You do not have to stay silent today.',
    'Сегодня необязательно молчать.',
  ),
  'home.phrase.1': L10nTriple(
    'Bazı cevaplar zamanını bekler.',
    'Some answers wait for their time.',
    'Некоторые ответы ждут своего часа.',
  ),
  'home.phrase.2': L10nTriple(
    'Bugün yeni bir işaret taşıyor olabilir.',
    'Today may carry a new sign.',
    'Сегодня может нести новый знак.',
  ),
  'home.tarot.title': L10nTriple('TAROT', 'Tarot', 'ТАРО'),
  'home.tarot.caption': L10nTriple(
    'Bir kart çek, bir an dur.',
    'Draw a card, then pause.',
    'Вытяни карту и остановись.',
  ),
  'home.discovery.coffee.title': L10nTriple('Kahve Falı', 'Coffee', 'Кофе'),
  'home.discovery.coffee.caption': L10nTriple(
    'Fincanı oku',
    'Read the cup',
    'Прочитай чашку',
  ),
  'home.discovery.coffee.semantics': L10nTriple(
    'Kahve Falı',
    'Coffee reading',
    'Гадание на кофе',
  ),
  'home.discovery.palm.title': L10nTriple('El Falı', 'Palm', 'Ладонь'),
  'home.discovery.palm.caption': L10nTriple(
    'Avuç izleri',
    'Palm lines',
    'Линии ладони',
  ),
  'home.discovery.palm.semantics': L10nTriple(
    'El Falı',
    'Palm reading',
    'Гадание по ладони',
  ),
  'home.discovery.astrology.title': L10nTriple(
    'Astroloji',
    'Astrology',
    'Астрология',
  ),
  'home.discovery.astrology.caption': L10nTriple(
    'Bugünün göğü',
    "Today's sky",
    'Небо сегодня',
  ),
  'home.discovery.astrology.semantics': L10nTriple(
    'Astroloji',
    'Astrology',
    'Астрология',
  ),
  'home.discovery.star_map.title': L10nTriple(
    'Yıldızname',
    'Yıldızname',
    'Йылдызнаме',
  ),
  'home.discovery.star_map.caption': L10nTriple(
    'Kişisel hikâye arşivi',
    'Personal story archive',
    'Архив личной истории',
  ),
  'home.discovery.star_map.semantics': L10nTriple(
    'Yıldızname',
    'Yıldızname',
    'Йылдызнаме',
  ),
  'home.discovery.soulmate.title': L10nTriple(
    'Ruh Eşi',
    'Soulmate',
    'Родственная душа',
  ),
  'home.discovery.soulmate.caption': L10nTriple(
    'Sembolik bir yakınlık hayali',
    'A symbolic imagining of closeness',
    'Символический образ близости',
  ),
  'home.discovery.soulmate.semantics': L10nTriple(
    'Ruh Eşi',
    'Soulmate',
    'Родственная душа',
  ),
  'home.discovery.tarot.title': L10nTriple('Tarot', 'Tarot', 'Таро'),
  'home.discovery.tarot.caption': L10nTriple(
    'Bir kart, bir an',
    'One card, one pause',
    'Одна карта — одна пауза',
  ),
  'home.discovery.tarot.semantics': L10nTriple('Tarot', 'Tarot', 'Таро'),
  'home.discovery.dream.title': L10nTriple(
    'Rüya Analizi',
    'Dream Analysis',
    'Анализ снов',
  ),
  'home.discovery.dream.caption': L10nTriple(
    'Sembollerini dinle',
    'Listen to the symbols',
    'Услышь символы',
  ),
  'home.discovery.dream.semantics': L10nTriple(
    'Rüya Analizi',
    'Dream analysis',
    'Анализ снов',
  ),
  'home.discovery.new': L10nTriple('Yeni', 'New', 'Новое'),
  'home.intro.0': L10nTriple('Merhaba', 'Hello', 'Здравствуй'),
  'home.intro.1': L10nTriple('Hoş geldin', 'Welcome', 'Добро пожаловать'),
  'home.intro.2': L10nTriple('Buradasın', 'You are here', 'Ты здесь'),
};
