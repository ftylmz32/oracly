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
  'astro.report_theme': L10nTriple(
    'GÖZLEM',
    'OBSERVATION',
    'НАБЛЮДЕНИЕ',
  ),
  'astro.report_message': L10nTriple(
    'NE ANLAMA GELİYOR',
    'WHAT IT MEANS',
    'ЧТО ЭТО ЗНАЧИТ',
  ),
  'astro.report_attention': L10nTriple(
    'NÜANS',
    'NUANCE',
    'НЮАНС',
  ),
  'astro.report_next': L10nTriple(
    'YANSIMA',
    'REFLECTION',
    'ОТРАЖЕНИЕ',
  ),
  'astro.report_depths': L10nTriple(
    'DERİNLİKLER',
    'DEPTHS',
    'ГЛУБИНЫ',
  ),
  'star.preview': L10nTriple('Önizleme', 'Preview', 'Предпросмотр'),
  'star.lead': L10nTriple(
    'Arşivindeki yaprak\nsenin hakkında hangi hikâyeyi tutuyor?',
    'What story does this archive leaf\nhold about you?',
    'Какую историю хранит о тебе\nэтот лист архива?',
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
  'star.story_title': L10nTriple(
    'Yaprak',
    'Leaf',
    'Лист',
  ),
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
    'Güneş burcuna göre sembolik bir yıldızname arşivi — hüküm değil, kendi hikâyenin faslı.',
    'A symbolic star-archive from the sun sign — a chapter of your story, not a verdict.',
    'Символический звёздный архив по Солнцу — глава твоей истории, не приговор.',
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
    'Arşiv yaprağını aç',
    'Open the archive leaf',
    'Открыть лист архива',
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
    'Kişisel yıldızname arşivinin senin hakkında tuttuğu sembolik fasıl. Hüküm değil.',
    'The symbolic chapter your personal star-archive holds about you. Not a verdict.',
    'Символическая глава, которую хранит о тебе личный звёздный архив. Не приговор.',
  ),
  'star.sky_title': L10nTriple(
    'Bu yaprağın izi',
    'The mark on this leaf',
    'След на этом листе',
  ),
  'star.sky_hint': L10nTriple(
    'Sembolik bir yıldızname faslı — kişisel yol, günlük burç özeti değil.',
    'A symbolic archive chapter — a personal path, not a daily horoscope.',
    'Символическая глава архива — личный путь, не дневной гороскоп.',
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
    'İçeride gerilen iplik. Teşhis değil; arşivde bakılacak bir fasıl.',
    'The thread drawn taut inside. Not a diagnosis; a chapter to regard.',
    'Нить, натянутая внутри. Не диагноз; глава, на которую смотреть.',
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
    'Arşiv dilindeki sembolik imgeler — modern gökyüzü enstrümanı değil.',
    'Symbolic images in archive language — not a modern sky instrument.',
    'Символические образы языка архива — не современный инструмент неба.',
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
  'star.handoff.deck_name': L10nTriple('Yıldızname', 'Star map', 'Звёздная карта'),
  'astro.app_bar': L10nTriple('ASTROLOJİ', 'ASTROLOGY', 'АСТРОЛОГИЯ'),
  'star.app_bar': L10nTriple('YILDIZNAME', 'YILDIZNAME', 'ЙЫЛДЫЗНАМЕ'),
};
