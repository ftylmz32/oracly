/// Astrology + Yıldızname chrome — TR / EN / RU.
/// Distinct chambers: Astrology = today's sky instrument;
/// Yıldızname = personal symbolic archive path.
library;

import '../l10n_triple.dart';

const kL10nAstrology = <String, L10nTriple>{
  'astro.today_title': L10nTriple(
    'Güneş burcunun bugünkü ritmi',
    "Today's sun-sign rhythm",
    'Сегодняшний ритм солнечного знака',
  ),
  'astro.lead': L10nTriple(
    'Bu Güneş burcu\nbugün nasıl duruyor?',
    'How does this sun sign\nsit with you today?',
    'Как этот солнечный знак\nстоит сегодня?',
  ),
  'astro.loading_today_sky': L10nTriple(
    'Güneş burcu ritmini dikkatle okuyorum...',
    'Reading the sun-sign rhythm with care...',
    'Внимательно читаю ритм солнечного знака...',
  ),
  'astro.unavailable_more_info': L10nTriple(
    'Bu bölüm için biraz daha bilgi gerekiyor.',
    'I need a bit more information for this section.',
    'Для этого раздела нужно немного больше информации.',
  ),
  'astro.your_sky_title': L10nTriple(
    'GÜNEŞ BURCUN',
    'YOUR SUN SIGN',
    'ТВОЙ СОЛНЕЧНЫЙ ЗНАК',
  ),
  'astro.general': L10nTriple('Gökyüzü özü', 'Sky essence', 'Суть неба'),
  'astro.love': L10nTriple('Aşkta', 'In love', 'В любви'),
  'astro.career': L10nTriple('Hayatta', 'In life', 'В жизни'),
  'astro.inner': L10nTriple('Netlikte', 'In clarity', 'В ясности'),
  'astro.recurring': L10nTriple(
    'SON GÜNLERİN RİTMİ',
    'RECENT SKY RHYTHM',
    'НЕДАВНИЙ РИТМ НЕБА',
  ),
  'astro.journey_empty': L10nTriple(
    'Son günlerde ayrı bir gökyüzü ritmi birikmedi. Bugünkü duruş yeter.',
    'No separate sky rhythm has gathered lately. Today’s stance is enough.',
    'В последние дни отдельный ритм неба не накопился. Сегодняшней стойки довольно.',
  ),
  'astro.detail_cta': L10nTriple(
    'Günün derinliğine geç',
    'Continue into today’s depth',
    'Перейти к глубине дня',
  ),
  'astro.today_ask': L10nTriple(
    'BUGÜN GÖKYÜZÜ NE ÖNERİYOR?',
    'WHAT DOES THE SKY SUGGEST TODAY?',
    'ЧТО ПРЕДЛАГАЕТ НЕБО СЕГОДНЯ?',
  ),
  'astro.lane_love': L10nTriple('YAKINLIK', 'CLOSENESS', 'БЛИЗОСТЬ'),
  'astro.lane_work': L10nTriple('YÖN', 'DIRECTION', 'НАПРАВЛЕНИЕ'),
  'astro.lane_inner': L10nTriple('İÇERİDE', 'WITHIN', 'ВНУТРИ'),
  'astro.report_theme': L10nTriple('GÖZLEM', 'OBSERVATION', 'НАБЛЮДЕНИЕ'),
  'astro.report_message': L10nTriple(
    'NE ANLAMA GELİYOR',
    'WHAT IT MEANS',
    'ЧТО ЭТО ЗНАЧИТ',
  ),
  'astro.report_attention': L10nTriple('NÜANS', 'NUANCE', 'НЮАНС'),
  'astro.report_next': L10nTriple('YANSIMA', 'REFLECTION', 'ОТРАЖЕНИЕ'),
  'astro.report_depths': L10nTriple('DERİNLİKLER', 'DEPTHS', 'ГЛУБИНЫ'),
  'star.preview': L10nTriple('Önizleme', 'Preview', 'Предпросмотр'),
  'star.lead': L10nTriple(
    'Doğduğun anın gökyüzü\nsenin hakkında ne anlatıyor?',
    'What does the sky of your birth\nsay about you?',
    'Что небо твоего рождения\nговорит о тебе?',
  ),
  'star.told_today': L10nTriple(
    'ARŞİVDE ANLATILAN YOL',
    'THE PATH THE ARCHIVE HOLDS',
    'ПУТЬ, ЧТО ХРАНИТ АРХИВ',
  ),
  'star.sun_theme': L10nTriple(
    'GÜNEŞ YOLUNUN FASLI',
    'CHAPTER OF THE SUN PATH',
    'ГЛАВА СОЛНЕЧНОГО ПУТИ',
  ),
  'star.inner_theme': L10nTriple(
    'İÇİNDEKİ TEMA',
    'THE THEME INSIDE',
    'ВНУТРЕННЯЯ ТЕМА',
  ),
  'star.today_mirror': L10nTriple(
    'BU SAYFANIN YANSIMASI',
    'THIS PAGE’S REFLECTION',
    'ОТРАЖЕНИЕ ЭТОЙ СТРАНИЦЫ',
  ),
  'star.recent_yours': L10nTriple(
    'SON DÖNEMİN HİKÂYESİ',
    'THE RECENT CHAPTER',
    'ИСТОРИЯ ПОСЛЕДНЕГО ПЕРИОДА',
  ),
  'star.story_title': L10nTriple('Yaprak', 'Leaf', 'Лист'),
  'star.journey_title': L10nTriple(
    'SON DÖNEMİN HİKÂYESİ',
    'THE RECENT CHAPTER',
    'ИСТОРИЯ ПОСЛЕДНЕГО ПЕРИОДА',
  ),
  'star.journey_empty': L10nTriple(
    'Arşivde henüz ayrı bir fasıl birikmedi. Bu yaprak yeter.',
    'No separate chapter has gathered in the archive yet. This leaf is enough.',
    'В архиве ещё нет отдельной главы. Этого листа довольно.',
  ),
  'star.capability': L10nTriple(
    'Güneş burcuna göre başlayan, doğum bilgilerinle derinleşen sembolik bir yıldızname.',
    'A symbolic star reading that starts from your sun sign and deepens with your birth details.',
    'Символическая звёздная книга: начинается с солнечного знака и углубляется с данными рождения.',
  ),
  'star.enter_birth': L10nTriple(
    'Doğum Bilgilerini Gir',
    'Enter birth details',
    'Введи данные рождения',
  ),
  'star.chart_ready': L10nTriple(
    'Doğum tarihin kayıtlı.',
    'Your birth date is saved.',
    'Дата рождения сохранена.',
  ),
  'star.view_chart': L10nTriple(
    'Kişisel yorumunu aç',
    'Open your personal reading',
    'Открыть личное чтение',
  ),
  'star.personalize_empty': L10nTriple(
    'Güneş burcuna göre kişisel yıldızname yolu için doğum tarihini ekle.',
    'Add a birth date for a personal sun-sign archive path.',
    'Добавь дату рождения для личного пути архива по Солнцу.',
  ),
  'star.general_daily': L10nTriple(
    'ARŞİVİN GENEL YAPRAĞI',
    'GENERAL ARCHIVE LEAF',
    'ОБЩИЙ ЛИСТ АРХИВА',
  ),
  'star.personalized_daily': L10nTriple(
    'SENİN FASLIN',
    'YOUR CHAPTER',
    'ТВОЯ ГЛАВА',
  ),
  'star.today_card': L10nTriple(
    'Bugünün yıldızname yaprağı',
    "Today's archive leaf",
    'Сегодняшний лист звёздной книги',
  ),
  'star.birth_chart_title': L10nTriple(
    'Kişisel yıldızname yolu',
    'Personal star-archive path',
    'Личный путь звёздной книги',
  ),
  'star.birth_chart_hint': L10nTriple(
    'Haritanın bütününü birlikte okuyan, sembolik ve kişisel yorumun.',
    'Your personal reading of the whole chart together.',
    'Личное чтение всей твоей карты целиком.',
  ),
  'star.sky_title': L10nTriple(
    'Bu yaprağın izi',
    'The mark on this leaf',
    'След на этом листе',
  ),
  'star.sky_hint': L10nTriple(
    'Bugün için kısa ve sembolik bir yıldızname notu.',
    'A short star note for today.',
    'Короткая звёздная заметка на сегодня.',
  ),
  'star.karmic_title': L10nTriple(
    'Hikâyenin iplikleri',
    'Threads of the story',
    'Нити истории',
  ),
  'star.karmic_result': L10nTriple(
    'İÇİNDEKİ TEMA',
    'THE THEME INSIDE',
    'ВНУТРЕННЯЯ ТЕМА',
  ),
  'star.karmic_hint': L10nTriple(
    'Hayatında tekrar eden temalar ve iç gerilimlerin.',
    'The themes and inner tensions that keep returning in your life.',
    'Темы и внутренние напряжения, которые возвращаются в твоей жизни.',
  ),
  'star.sun_sign': L10nTriple(
    'Güneş yolunun faslı',
    'Chapter of the Sun path',
    'Глава солнечного пути',
  ),
  'star.today_reflection': L10nTriple(
    'BUGÜNÜN İZİ',
    "TODAY'S MARK",
    'СЛЕД ДНЯ',
  ),
  'star.planets_title': L10nTriple(
    'Geleneksel gök imgeleri',
    'Traditional sky images',
    'Традиционные небесные образы',
  ),
  'star.planets_hint': L10nTriple(
    'Geleneksel yıldızname dilinde gök cisimlerinin simgeleri.',
    'Sky symbols in the traditional star-book language.',
    'Небесные символы на традиционном языке звёздной книги.',
  ),
  'star.sky_headline': L10nTriple(
    'Kısa arşiv cümlesi',
    'A short archive line',
    'Краткая строка архива',
  ),
  'star.sky_meaning': L10nTriple(
    'Bu faslın günlük hayattaki yeri',
    'Where this chapter sits in daily life',
    'Место этой главы в повседневности',
  ),
  'star.sky_advice': L10nTriple(
    'Bu yaprak için küçük bir duruş',
    'A small stance for this leaf',
    'Маленькая стойка для этого листа',
  ),
  'star.karmic_theme': L10nTriple(
    'Faslın özü',
    'Essence of the chapter',
    'Суть главы',
  ),
  'star.karmic_meaning': L10nTriple(
    'Bu ipliğin anlamı',
    'Meaning of this thread',
    'Значение этой нити',
  ),
  'star.karmic_ask': L10nTriple(
    'ÖNÜNDEKİ EŞİK',
    'THE THRESHOLD AHEAD',
    'ПОРОГ ВПЕРЕДИ',
  ),
  'star.left_question': L10nTriple(
    'SANA BIRAKTIĞI SORU',
    'THE QUESTION IT LEAVES YOU',
    'ВОПРОС, КОТОРЫЙ ОСТАВЛЯЕТ',
  ),
  'star.karmic_step': L10nTriple(
    'Bu fasıl için küçük adım',
    'A small step for this chapter',
    'Маленький шаг для этой главы',
  ),
  'star.disclaimer': L10nTriple(
    'Bu, sembolik bir yıldızname yorumudur.',
    'This is a symbolic star-archive reading.',
    'Это символическое чтение звёздной книги.',
  ),
  'star.planets_note': L10nTriple(
    'Bunlar sembolik arşiv imgeleri; senin yolunda nasıl durduklarına bakılır.',
    'These are symbolic archive images; regard how they sit on your path.',
    'Это символические образы архива; смотри, как они стоят на твоём пути.',
  ),
  'star.or_hint': L10nTriple(
    'Bu yıldızname faslı hakkında aklına takılanları sor.',
    'Ask what stays with you about this archive chapter.',
    'Спроси то, что осталось с тобой об этой главе архива.',
  ),
  'star.handoff.no_birth': L10nTriple(
    'Doğum bilgisi yok',
    'No birth details',
    'Нет данных о рождении',
  ),
  'star.handoff.general_catalog': L10nTriple(
    'genel katalog',
    'general catalogue',
    'общий каталог',
  ),
  'star.handoff.sun_from_date': L10nTriple(
    '{sign} Güneş (tarihten)',
    '{sign} Sun (from date)',
    '{sign} Солнце (по дате)',
  ),
  'star.handoff.source': L10nTriple(
    'Kaynak: yerel yıldızname arşivi · {section}',
    'Source: local star-map archive · {section}',
    'Источник: локальный архив звёздной карты · {section}',
  ),
  'star.handoff.source_label': L10nTriple(
    'Yıldızname · {section}',
    'Star map · {section}',
    'Звёздная карта · {section}',
  ),
  'star.handoff.deck_name': L10nTriple(
    'Yıldızname',
    'Star map',
    'Звёздная карта',
  ),
  'astro.or.daily': L10nTriple('Günlük', 'Daily', 'Ежедневно'),
  'astro.or.sign': L10nTriple('Burç: {sign}', 'Sign: {sign}', 'Знак: {sign}'),
  'astro.or.source': L10nTriple(
    'Kaynak: yerel Güneş burcu kataloğu · {kind}',
    'Source: local sun-sign catalogue · {kind}',
    'Источник: местный каталог солнечного знака · {kind}',
  ),
  'astro.app_bar': L10nTriple('ASTROLOJİ', 'ASTROLOGY', 'АСТРОЛОГИЯ'),
  'star.app_bar': L10nTriple('YILDIZNAME', 'YILDIZNAME', 'ЙЫЛДЫЗНАМЕ'),
};
