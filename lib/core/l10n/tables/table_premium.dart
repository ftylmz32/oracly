/// Premium, gems, and purchase honesty — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nPremium = <String, L10nTriple>{
  'premium.hero_title': L10nTriple(
    'ÖZEL BİR ODA',
    'A PRIVATE CHAMBER',
    'ЧАСТНАЯ КОМНАТА',
  ),
  'premium.hero_lead': L10nTriple(
    'Premium isteğe bağlıdır. Acele yok.',
    'Premium is optional. There is no hurry.',
    'Премиум необязателен. Спешки нет.',
  ),
  'premium.hero_subtitle': L10nTriple(
    'ORACLY’nin daha derin, sessiz bir katmanı — isteğe bağlı bir oda.',
    'A deeper, quieter layer of ORACLY — an optional chamber.',
    'Более глубокий, тихий слой ORACLY — комната по желанию.',
  ),
  'premium.app_bar_title': L10nTriple(
    'PREMİUM',
    'PREMIUM',
    'ПРЕМИУМ',
  ),
  'premium.status_active_label': L10nTriple(
    'AKTİF',
    'ACTIVE',
    'АКТИВНО',
  ),
  'premium.status_premium_label': L10nTriple(
    'PREMIUM',
    'PREMIUM',
    'ПРЕМИУМ',
  ),
  'premium.plan_selected_label': L10nTriple(
    'Seçildi',
    'Selected',
    'Выбрано',
  ),
  'premium.plan_select_label': L10nTriple(
    'Planı Seç',
    'Select plan',
    'Выбрать план',
  ),
  'premium.benefits_title': L10nTriple(
    'Derinlik · Süreklilik · Kişiselleştirme',
    'Depth · Continuity · Personalization',
    'Глубина · Непрерывность · Персонализация',
  ),
  'premium.experiences_title':
      L10nTriple('Premium deneyimler', 'Premium experiences', 'Премиум-опыты'),
  'premium.included_title':
      L10nTriple('Ücretsiz kalanlar', 'What stays free', 'Что остаётся бесплатным'),
  'premium.exclusive': L10nTriple('Premium', 'Premium', 'Премиум'),
  'premium.gem_note': L10nTriple(
    'Üç kart ve üzeri tarot · {n} Mücevher',
    'Three-card tarot and above · {n} gems',
    'Таро из трёх карт и больше · {n} кристаллов',
  ),
  'premium.benefit.soulmate.title': L10nTriple('Ruh Eşi', 'Soulmate', 'Родственная душа'),
  'premium.benefit.soulmate.body': L10nTriple(
    'Kişisel portre ve beş bölümlük yorum — kaydedilir, tekrar açılır ve OR ile devam eder.',
    'A personal portrait and five-part reading — saved, revisit anytime, and continues in OR.',
    'Личный портрет и пятичастное толкование — сохраняется, открывается снова и продолжается в OR.',
  ),
  'premium.benefit.coffee.title': L10nTriple('Kahve', 'Coffee', 'Кофе'),
  'premium.benefit.coffee.body': L10nTriple(
    'Fincanı sakin bir ritüelle oku — kehanet değil, yansıma.',
    'Read the cup as a calm ritual — reflection, not prediction.',
    'Читай чашку как спокойный ритуал — размышление, не предсказание.',
  ),
  'premium.benefit.palm.title': L10nTriple('El', 'Palm', 'Ладонь'),
  'premium.benefit.palm.body': L10nTriple(
    'Avucun çizgilerini sembolik ve dikkatli bir bakışla dinle.',
    'Listen to the lines of the palm with a symbolic, careful eye.',
    'Слушай линии ладони символическим и внимательным взглядом.',
  ),
  'premium.benefit.discovery.title':
      L10nTriple('Keşif Günlüğü', 'Discovery journal', 'Дневник открытий'),
  'premium.benefit.discovery.body': L10nTriple(
    'Gerçek keşiflerinden örülen temalar — uydurma istatistik yok.',
    'Themes drawn from your real discoveries — no invented statistics.',
    'Темы из твоих настоящих открытий — без выдуманной статистики.',
  ),
  'premium.benefit.or.title': L10nTriple('OR sohbeti', 'OR conversation', 'Разговор с OR'),
  'premium.benefit.or.body': L10nTriple(
    'Okumalarından taşınan bağlamla konuş — daha derin, sakin ve geleceği iddia etmeyen.',
    'Talk with context carried from your readings — deeper, calm, never claiming the future.',
    'Разговор с контекстом из твоих чтений — глубже, спокойнее, без претензии на будущее.',
  ),
  'premium.benefit.journey.title': L10nTriple(
    'Yolculuk derinliği',
    'Journey depth',
    'Глубина пути',
  ),
  'premium.benefit.journey.body': L10nTriple(
    'Gerçek izler biriktiğinde: theme arşivi, alanlar arası karşılaştırma ve OR için daha derin bağlam. Temel gözlem ücretsiz kalır.',
    'When real traces have gathered: theme archive, cross-area comparison, and deeper OR context. Basic observation stays free.',
    'Когда накопятся реальные следы: архив тем, сравнение между областями и более глубокий контекст для OR. Базовое наблюдение остаётся бесплатным.',
  ),
  'premium.benefit.atmosphere.title':
      L10nTriple('Günün Mesajı', "Today's message", 'Послание дня'),
  'premium.benefit.atmosphere.body': L10nTriple(
    'Bugün için sakin bir yansıma — kehanet değil.',
    'A calm reflection for today — not a prediction.',
    'Спокойное размышление на сегодня — не предсказание.',
  ),
  'premium.benefit.depth.title': L10nTriple(
    'Derinlik',
    'Depth',
    'Глубина',
  ),
  'premium.benefit.depth.body': L10nTriple(
    'OR sohbeti ve Ruh Eşi gibi daha derin odalar — ritüeli kilitlemeden.',
    'Deeper chambers such as OR conversation and Soulmate — without locking the ritual.',
    'Более глубокие комнаты — разговор с OR и родственная душа — без закрытия ритуала.',
  ),
  'premium.benefit.continuity.title': L10nTriple(
    'Süreklilik',
    'Continuity',
    'Непрерывность',
  ),
  'premium.benefit.continuity.body': L10nTriple(
    'Gerçek izler biriktikçe yolculuk arşivi ve alanlar arası bağlam korunur.',
    'As real traces gather, journey archive and cross-area context stay with you.',
    'По мере накопления реальных следов архив пути и межобластный контекст остаются с тобой.',
  ),
  'premium.benefit.personalization.title': L10nTriple(
    'Kişiselleştirme',
    'Personalization',
    'Персонализация',
  ),
  'premium.benefit.personalization.body': L10nTriple(
    'Yalnızca senin geçmişine dayanan sakin bir katman — uydurma istatistik yok.',
    'A quiet layer grounded only in your history — no invented statistics.',
    'Тихий слой, основанный только на твоей истории — без выдуманной статистики.',
  ),
  'premium.what_title': L10nTriple(
    'NEDİR BU KATMAN',
    'WHAT THIS LAYER IS',
    'ЧТО ЭТО ЗА СЛОЙ',
  ),
  'premium.what_body': L10nTriple(
    'Premium üç şey sunar: derinlik, süreklilik ve kişiselleştirme. Temel ritüeller ücretsiz kalır.',
    'Premium offers three things: depth, continuity, and personalization. Core rituals stay free.',
    'Премиум даёт три вещи: глубину, непрерывность и персонализацию. Базовые ритуалы остаются бесплатными.',
  ),
  'premium.why_title': L10nTriple(
    'NEDEN VAR',
    'WHY IT EXISTS',
    'ЗАЧЕМ ОН ЕСТЬ',
  ),
  'premium.why_body': L10nTriple(
    'Daha derin bir oda olsun diye — baskısız, isteğe bağlı, sürekliliği bozmadan.',
    'So a deeper chamber can exist — without pressure, optional, without breaking continuity.',
    'Чтобы была более глубокая комната — без давления, по желанию, без разрыва непрерывности.',
  ),
  'premium.entitlement_unverified': L10nTriple(
    'Üyelik henüz doğrulanamadı. Mağaza onayından sonra yeniden dene.',
    'Membership could not be verified yet. Try again after store confirmation.',
    'Подписку пока не удалось подтвердить. Попробуй снова после подтверждения магазина.',
  ),
  'premium.unlock_title': L10nTriple(
    'NEDİR BU KATMAN',
    'WHAT THIS LAYER IS',
    'ЧТО ЭТО ЗА СЛОЙ',
  ),
  'premium.active_body': L10nTriple(
    'Ruh Eşi odası senin için açık — sessiz, kişisel bir katman.',
    'The Soulmate chamber is open for you — a quiet, personal layer.',
    'Комната родственной души открыта для тебя — тихий, личный слой.',
  ),
  'premium.gate_title': L10nTriple(
    'Bu oda Premium’da duruyor.',
    'This chamber stays in Premium.',
    'Эта комната находится в Премиуме.',
  ),
  'premium.gate_lead': L10nTriple(
    'Temel keşiflerin açık kalır. Burada yalnızca daha derin bir katmanı sakinçe görebilirsin.',
    'Your core discoveries stay open. Here you can calmly see only a deeper layer.',
    'Твои основные открытия остаются открытыми. Здесь можно спокойно увидеть лишь более глубокий слой.',
  ),
  'premium.unlock.0': L10nTriple('Derinlik', 'Depth', 'Глубина'),
  'premium.unlock.1': L10nTriple('Süreklilik', 'Continuity', 'Непрерывность'),
  'premium.unlock.2': L10nTriple(
    'Kişiselleştirme',
    'Personalization',
    'Персонализация',
  ),
  'premium.unlock.3': L10nTriple(
    'Keşifler baskısız kalır',
    'Discoveries stay without pressure',
    'Открытия остаются без давления',
  ),
  'premium.unlock.4': L10nTriple(
    'Premium isteğe bağlıdır',
    'Premium stays optional',
    'Премиум остаётся по желанию',
  ),
  'premium.unlock.5': L10nTriple('Premium deneyimler', 'Premium experiences', 'Премиум-опыты'),
  'premium.cta_join': L10nTriple(
    "Premium'a Geç",
    'Go Premium',
    'Перейти на Премиум',
  ),
  'premium.cta_explore': L10nTriple(
    "Premium'a Geç",
    'Go Premium',
    'Перейти на Премиум',
  ),
  'premium.home_banner_title': L10nTriple(
    'Premium ile',
    'With Premium',
    'С Премиумом',
  ),
  'premium.home_banner_body': L10nTriple(
    'Daha derin sohbetler, sınırsız yorumlar ve tüm özelliklere sınırsız erişim.',
    'Deeper conversations, unlimited readings, and full access to every feature.',
    'Более глубокие разговоры, безлимитные толкования и полный доступ.',
  ),
  'premium.cta_active': L10nTriple('Premium üyesin', 'You are Premium', 'Ты в Премиуме'),
  'premium.cta_unavailable': L10nTriple(
    'Mağaza satın alması henüz açılmadı.',
    'Store purchase is not open yet.',
    'Покупка в магазине пока не открыта.',
  ),
  'premium.cta_retry_store': L10nTriple(
    'Mağazayı yeniden dene',
    'Try the store again',
    'Попробовать магазин снова',
  ),
  'premium.loading_body': L10nTriple(
    'Mağaza durumu kontrol ediliyor…',
    'Checking store status…',
    'Проверяем статус магазина…',
  ),
  'premium.error_retry': L10nTriple(
    'Yeniden dene',
    'Try again',
    'Попробовать снова',
  ),
  'premium.cta_hint': L10nTriple(
    'Hazır olduğunda buradan sakinçe devam edebilirsin.',
    'When it is ready, you can continue calmly from here.',
    'Когда будет готово, можно спокойно продолжить здесь.',
  ),
  'premium.gem_section_title': L10nTriple(
    'Mücevher',
    'Gem',
    'Кристалл',
  ),
  'premium.cta_hint_configured': L10nTriple(
    'Hazır olduğunda mağazadan sakinçe devam edebilirsin.',
    'When you are ready, you can continue calmly through the store.',
    'Когда будешь готов, можно спокойно продолжить через магазин.',
  ),
  'premium.plan_price_pending': L10nTriple('Mağaza fiyatı', 'Store price', 'Цена магазина'),
  'premium.cta_restore':
      L10nTriple('Satın Almaları Geri Yükle', 'Restore purchases', 'Восстановить покупки'),
  'premium.cta_busy': L10nTriple('Hazırlanıyor…', 'Preparing…', 'Готовится…'),
  'premium.activated':
      L10nTriple('Premium üyeliğin doğrulandı.', 'Your Premium membership was confirmed.', 'Премиум-подписка подтверждена.'),
  'premium.purchase_failed':
      L10nTriple('Satın alma işlemi tamamlanamadı.', 'The purchase could not be completed.', 'Покупку не удалось завершить.'),
  'premium.purchase_cancelled':
      L10nTriple('Satın alma iptal edildi.', 'The purchase was cancelled.', 'Покупка отменена.'),
  'premium.purchase_pending': L10nTriple(
    'Satın alma onay bekliyor. Biraz sonra durumu kontrol edebilirsin.',
    'The purchase is pending confirmation. You can check again shortly.',
    'Покупка ожидает подтверждения. Можно проверить чуть позже.',
  ),
  'premium.restore_unavailable': L10nTriple(
    'Geri yükleme şu anda kullanılamıyor.',
    'Restore is not available right now.',
    'Восстановление сейчас недоступно.',
  ),
  'premium.restore_failed':
      L10nTriple('Satın almalar geri yüklenemedi.', 'Purchases could not be restored.', 'Покупки не удалось восстановить.'),
  'premium.restore_none': L10nTriple(
    'Geri yüklenecek bir satın alma bulunamadı.',
    'No purchases were found to restore.',
    'Покупок для восстановления не найдено.',
  ),
  'premium.restore_success':
      L10nTriple('Satın almalar geri yüklendi.', 'Purchases were restored.', 'Покупки восстановлены.'),
  'premium.access_required': L10nTriple(
    'Bu içerik Premium üyelik gerektirir.',
    'This content requires Premium membership.',
    'Этот материал требует Премиум-подписку.',
  ),
  'premium.plan_monthly': L10nTriple('Esnek başlangıç', 'Flexible start', 'Гибкое начало'),
  'premium.plan_yearly':
      L10nTriple('Yıllık plan', 'Yearly plan', 'Годовой план'),
  'premium.plan_lifetime': L10nTriple(
    'Tek seferlik ödeme · kalıcı erişim',
    'One-time payment · lasting access',
    'Разовый платёж · постоянный доступ',
  ),
};
