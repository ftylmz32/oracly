/// Freemium V1 — daily Coffee / Palm allowance, Premium daily rights,
/// Fincan Haritası Premium door — TR / EN / RU. Facts only: no allowance
/// is claimed before the server answers, no price, no "better AI" promise.
library;

import '../l10n_triple.dart';

const kL10nFreemium = <String, L10nTriple>{
  // ── Coffee ───────────────────────────────────────────────────────
  'freemium.coffee.free_title': L10nTriple(
    'Günde bir kahve falı ücretsiz.',
    'One coffee reading a day is free.',
    'Одно гадание на кофе в день — бесплатно.',
  ),
  'freemium.coffee.premium_title': L10nTriple(
    'Premium üyeliğinde günde iki kahve falı, beklemeden.',
    'With Premium: two coffee readings a day, no wait.',
    'С Премиумом — два гадания на кофе в день, без ожидания.',
  ),
  'freemium.coffee.used_title': L10nTriple(
    'Bugünkü ücretsiz kahve falını kullandın.',
    'You have used today’s free coffee reading.',
    'Сегодняшнее бесплатное гадание на кофе уже использовано.',
  ),
  'freemium.coffee.used_premium_title': L10nTriple(
    'Bugünkü iki kahve falını da kullandın.',
    'You have used both of today’s coffee readings.',
    'Оба сегодняшних гадания на кофе уже использованы.',
  ),
  'freemium.coffee.cta': L10nTriple('Falına Bak', 'Read My Cup', 'Посмотреть'),
  // ── Palm ─────────────────────────────────────────────────────────
  'freemium.palm.free_title': L10nTriple(
    'Günde bir el falı ücretsiz.',
    'One palm reading a day is free.',
    'Одно гадание по руке в день — бесплатно.',
  ),
  'freemium.palm.premium_title': L10nTriple(
    'Premium üyeliğinde günde iki el falı, beklemeden.',
    'With Premium: two palm readings a day, no wait.',
    'С Премиумом — два гадания по руке в день, без ожидания.',
  ),
  'freemium.palm.used_title': L10nTriple(
    'Bugünkü ücretsiz el falını kullandın.',
    'You have used today’s free palm reading.',
    'Сегодняшнее бесплатное гадание по руке уже использовано.',
  ),
  'freemium.palm.used_premium_title': L10nTriple(
    'Bugünkü iki el falını da kullandın.',
    'You have used both of today’s palm readings.',
    'Оба сегодняшних гадания по руке уже использованы.',
  ),
  // ── Shared allowance lines ───────────────────────────────────────
  'freemium.free_note': L10nTriple(
    'Ücretsiz falın her zamanki bekleme süresinin ardından açılır.',
    'Your free reading opens after the usual wait.',
    'Бесплатное гадание откроется после обычного ожидания.',
  ),
  'freemium.premium_badge': L10nTriple('PREMIUM', 'PREMIUM', 'PREMIUM'),
  'freemium.used_body': L10nTriple(
    'Günlük hakkın yenilendiğinde yeniden bakabilirsin.',
    'You can read again once your daily reading renews.',
    'Ты сможешь погадать снова, когда обновится дневное гадание.',
  ),
  'freemium.used_premium_offer': L10nTriple(
    "Premium'da günde iki fal ve beklemesiz sonuç var.",
    'Premium includes two readings a day and no wait.',
    'В Премиуме — два гадания в день и без ожидания.',
  ),
  'freemium.checking': L10nTriple(
    'Günlük hakların kontrol ediliyor…',
    'Checking your daily readings…',
    'Проверяем дневные гадания…',
  ),
  'freemium.check_failed': L10nTriple(
    'Üyelik durumun şu an doğrulanamadı. Günlük hakkın, falına baktığında kontrol edilir.',
    'Your membership could not be confirmed right now. Your daily reading is checked when you start.',
    'Сейчас не удалось подтвердить подписку. Дневное гадание проверим, когда ты начнёшь.',
  ),
  'freemium.retry': L10nTriple('Yeniden dene', 'Try again', 'Повторить'),
  'freemium.recheck': L10nTriple(
    'Yeniden kontrol et',
    'Check again',
    'Проверить снова',
  ),
  'freemium.see_premium': L10nTriple(
    'Premium avantajlarını gör',
    'See Premium benefits',
    'Преимущества Премиума',
  ),
  'freemium.back_home': L10nTriple(
    'Ana sayfaya dön',
    'Back to home',
    'На главную',
  ),
  // ── Premium screen ───────────────────────────────────────────────
  'freemium.premium.hero_lead': L10nTriple(
    "Günde bir kahve ve bir el falı ücretsiz. Premium'da her birinden günde iki, beklemeden.",
    'One coffee and one palm reading are free every day. Premium gives two of each a day, no wait.',
    'Каждый день одно гадание на кофе и одно по руке — бесплатно. С Премиумом — по два в день, без ожидания.',
  ),
  'freemium.premium.section_title': L10nTriple(
    'GÜNLÜK HAKLARIN',
    'YOUR DAILY READINGS',
    'ТВОИ ДНЕВНЫЕ ГАДАНИЯ',
  ),
  'freemium.premium.coffee_title': L10nTriple(
    'Günde 2 Kahve Falı',
    '2 Coffee Readings a Day',
    '2 гадания на кофе в день',
  ),
  'freemium.premium.palm_title': L10nTriple(
    'Günde 2 El Falı',
    '2 Palm Readings a Day',
    '2 гадания по руке в день',
  ),
  'freemium.premium.daily_free_body': L10nTriple(
    'Ücretsiz planda günde 1.',
    'One a day on the free plan.',
    'В бесплатном плане — одно в день.',
  ),
  'freemium.premium.instant_title': L10nTriple(
    'Beklemesiz sonuç',
    'No waiting',
    'Без ожидания',
  ),
  'freemium.premium.instant_body': L10nTriple(
    'Ücretsiz plandaki bekleme süresi olmadan açılır.',
    'Opens without the free plan’s wait.',
    'Открывается без ожидания бесплатного плана.',
  ),
  'freemium.premium.cup_map_title': L10nTriple(
    'Fincan Haritası',
    'Cup Map',
    'Карта чашки',
  ),
  'freemium.premium.cup_map_body': L10nTriple(
    'Fincanına kendi işaretlerini koy; fotoğraflar yalnızca cihazında kalır.',
    'Place your own marks on your cup; photos stay only on your device.',
    'Отмечай знаки на своей чашке; фото остаются только на устройстве.',
  ),
  'freemium.premium.same_care': L10nTriple(
    'Yorumlar her iki planda da aynı özenle hazırlanır.',
    'Readings are prepared with the same care on both plans.',
    'Толкования в обоих планах готовятся с одинаковой заботой.',
  ),
  'freemium.premium.active_note': L10nTriple(
    'Premium üyeliğinde bunların hepsi açık.',
    'All of these are open with your membership.',
    'С твоей подпиской всё это открыто.',
  ),
  // ── Fincan Haritası Premium door ─────────────────────────────────
  'freemium.cup_map.locked_body': L10nTriple(
    'Bu fincanın fotoğrafları ve işaretlerin cihazında duruyor. Haritayı açmak için Premium gerekir.',
    'This cup’s photos and your marks are still on your device. Opening the map needs Premium.',
    'Фото этой чашки и твои отметки остаются на устройстве. Чтобы открыть карту, нужен Премиум.',
  ),
  'freemium.cup_map.locked_cta': L10nTriple(
    "Premium'u incele",
    'Explore Premium',
    'Узнать о Премиуме',
  ),
  'freemium.cup_map.delete': L10nTriple(
    'Fotoğrafları bu cihazdan sil',
    'Delete the photos from this device',
    'Удалить фото с устройства',
  ),
  'freemium.cup_map.delete_title': L10nTriple(
    'Fincan Haritası silinsin mi?',
    'Delete this Cup Map?',
    'Удалить карту чашки?',
  ),
  'freemium.cup_map.delete_body': L10nTriple(
    'Bu fincanın fotoğrafları, işaretleri ve notları bu cihazdan kalıcı olarak silinir.',
    'This cup’s photos, marks and notes are removed from this device for good.',
    'Фото, отметки и заметки этой чашки будут навсегда удалены с устройства.',
  ),
  'freemium.cup_map.delete_confirm': L10nTriple('Sil', 'Delete', 'Удалить'),
  'freemium.cup_map.delete_cancel': L10nTriple('Vazgeç', 'Cancel', 'Отмена'),
  'freemium.cup_map.checking': L10nTriple(
    'Üyelik durumun kontrol ediliyor…',
    'Checking your membership…',
    'Проверяем подписку…',
  ),
  'freemium.cup_map.check_failed': L10nTriple(
    'Üyelik durumun doğrulanamadı.',
    'Your membership could not be confirmed.',
    'Не удалось подтвердить подписку.',
  ),
  'freemium.cup_map.review_note': L10nTriple(
    "Fincan Haritası Premium'la açılır: fotoğraflarına kendi işaretlerini koyabilirsin.",
    'Cup Map opens with Premium: place your own marks on your photos.',
    'Карта чашки открывается с Премиумом: отмечай знаки на своих фото.',
  ),
};
