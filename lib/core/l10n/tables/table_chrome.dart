/// Nav, settings, and shared chrome — TR / EN / RU.
library;

import '../l10n_keys.dart';
import '../l10n_triple.dart';

const kL10nChrome = <String, L10nTriple>{
  L10nKeys.home: L10nTriple('Ana Sayfa', 'Home', 'Главная'),
  L10nKeys.tarot: L10nTriple('Tarot', 'Tarot', 'Таро'),
  L10nKeys.chat: L10nTriple('Sohbet', 'Chat', 'Чат'),
  L10nKeys.profile: L10nTriple('Profil', 'Profile', 'Профиль'),
  L10nKeys.coffee: L10nTriple('Kahve', 'Coffee', 'Кофе'),
  L10nKeys.astrology: L10nTriple('Astroloji', 'Astrology', 'Астрология'),
  L10nKeys.starMap: L10nTriple('Yıldızname', 'Yıldızname', 'Йылдызнаме'),
  'nav.or': L10nTriple('OR', 'OR', 'OR'),
  'nav.explore': L10nTriple('Keşfet', 'Explore', 'Обзор'),
  'nav.journal': L10nTriple('Günlük', 'Journal', 'Дневник'),
  L10nKeys.tarotReading: L10nTriple('Tarot', 'Tarot', 'Таро'),
  L10nKeys.aiChat: L10nTriple('OR', 'OR', 'OR'),
  L10nKeys.dream: L10nTriple('Rüya', 'Dream', 'Сон'),
  L10nKeys.numerology: L10nTriple('Numeroloji', 'Numerology', 'Нумерология'),
  L10nKeys.moonCalendar: L10nTriple('Ay Takvimi', 'Moon Calendar', 'Лунный календарь'),
  L10nKeys.manifestation:
      L10nTriple('Manifestasyon', 'Manifestation', 'Манифестация'),
  L10nKeys.settingsTitle: L10nTriple('AYARLAR', 'SETTINGS', 'НАСТРОЙКИ'),
  L10nKeys.language: L10nTriple('Dil', 'Language', 'Язык'),
  L10nKeys.languageSubtitle:
      L10nTriple('Uygulama dili', 'App language', 'Язык приложения'),
  L10nKeys.theme: L10nTriple('Tema', 'Theme', 'Тема'),
  L10nKeys.themeSubtitle: L10nTriple(
    'Koyu, açık veya sistem',
    'Dark, light, or system',
    'Тёмная, светлая или системная',
  ),
  L10nKeys.themeDark: L10nTriple('Koyu', 'Dark', 'Тёмная'),
  L10nKeys.themeLight: L10nTriple('Açık', 'Light', 'Светлая'),
  L10nKeys.themeSystem: L10nTriple('Sistem', 'System', 'Системная'),
  L10nKeys.sectionAppearance: L10nTriple('GÖRÜNÜM', 'APPEARANCE', 'ВНЕШНИЙ ВИД'),
  L10nKeys.sectionNotifications:
      L10nTriple('BİLDİRİMLER', 'NOTIFICATIONS', 'УВЕДОМЛЕНИЯ'),
  L10nKeys.sectionLanguage: L10nTriple('DİL', 'LANGUAGE', 'ЯЗЫК'),
  L10nKeys.sectionPrivacy: L10nTriple('GİZLİLİK', 'PRIVACY', 'КОНФИДЕНЦИАЛЬНОСТЬ'),
  L10nKeys.sectionOrStyle: L10nTriple('OR TARZI', 'OR STYLE', 'СТИЛЬ OR'),
  L10nKeys.sectionSound:
      L10nTriple('SES & DOKUNUŞ', 'SOUND & HAPTICS', 'ЗВУК И ОТКЛИК'),
  L10nKeys.sectionAnimation: L10nTriple('ANİMASYONLAR', 'ANIMATION', 'АНИМАЦИЯ'),
  L10nKeys.sectionAbout: L10nTriple('HAKKINDA', 'ABOUT', 'О ПРИЛОЖЕНИИ'),
  L10nKeys.privacy: L10nTriple('Gizlilik', 'Privacy', 'Конфиденциальность'),
  L10nKeys.privacySubtitle: L10nTriple(
    'Keşiflerin kişiselleştirme için kullanılır.',
    'Your discoveries are used to personalize.',
    'Открытия используются для персонализации.',
  ),
  L10nKeys.about: L10nTriple('Hakkında', 'About', 'О приложении'),
  L10nKeys.aboutSubtitle:
      L10nTriple('Sürüm ve misyon', 'Version and mission', 'Версия и миссия'),
  L10nKeys.back: L10nTriple('Geri', 'Back', 'Назад'),
  L10nKeys.save: L10nTriple('Kaydet', 'Save', 'Сохранить'),
  L10nKeys.cancel: L10nTriple('İptal', 'Cancel', 'Отмена'),
  L10nKeys.confirm: L10nTriple('Onayla', 'Confirm', 'Подтвердить'),
  L10nKeys.ok: L10nTriple('Tamam', 'OK', 'Готово'),
  L10nKeys.dismiss: L10nTriple('Vazgeç', 'Dismiss', 'Отмена'),
  L10nKeys.comingSoon: L10nTriple('Yakında', 'Soon', 'Скоро'),
  L10nKeys.soundTitle: L10nTriple('Ses efektleri', 'Sound effects', 'Звуковые эффекты'),
  L10nKeys.soundSubtitle: L10nTriple(
    'Dokunuş ve ritüel sesleri',
    'Touch and ritual sounds',
    'Звуки касания и ритуала',
  ),
  L10nKeys.ambientMusicTitle:
      L10nTriple('Atmosferik müzik', 'Atmospheric music', 'Атмосферная музыка'),
  L10nKeys.ambientMusicSubtitle: L10nTriple(
    'Sessiz döngüsel yatak sesi — açınca duyulur',
    'Quiet looping bed — audible when turned on',
    'Тихий циклический фон — слышен при включении',
  ),
  L10nKeys.hapticTitle:
      L10nTriple('Dokunsal geri bildirim', 'Haptic feedback', 'Тактильный отклик'),
  L10nKeys.hapticSubtitle: L10nTriple('Hafif titreşim', 'Light vibration', 'Лёгкая вибрация'),
  L10nKeys.voiceRepliesTitle: L10nTriple('Sesli yanıtlar', 'Voice replies', 'Голосовые ответы'),
  L10nKeys.voiceRepliesSubtitle: L10nTriple(
    'Okuma sonrası OR yanıtını seslendir.',
    "Speak OR's reply after a reading.",
    'Озвучивать ответ OR после чтения.',
  ),
  L10nKeys.orStyleTitle: L10nTriple('Konuşma tarzı', 'Speaking style', 'Манера речи'),
  L10nKeys.orStyleSubtitle:
      L10nTriple('OR\'ın sohbet üslubu', "OR's conversation tone", 'Тон разговора OR'),
  L10nKeys.orStyleSheetTitle:
      L10nTriple('OR konuşma tarzı', 'OR speaking style', 'Стиль речи OR'),
  L10nKeys.notificationsTitle: L10nTriple('Bildirimler', 'Notifications', 'Уведомления'),
  L10nKeys.notificationsSubtitle: L10nTriple(
    'İsteğe bağlı hatırlatmalar',
    'Optional reminders',
    'Необязательные напоминания',
  ),
  L10nKeys.notificationsUnavailable: L10nTriple(
    'Bildirimler yakında kullanılabilir.',
    'Notifications are not available yet.',
    'Уведомления пока недоступны.',
  ),
  L10nKeys.musicUnavailable: L10nTriple(
    'Atmosferik müzik şu anda kullanılamıyor.',
    'Atmospheric music is not available right now.',
    'Атмосферная музыка сейчас недоступна.',
  ),
  L10nKeys.animationTitle: L10nTriple('Animasyon Hızı', 'Motion speed', 'Скорость движения'),
  L10nKeys.animationSubtitle: L10nTriple(
    'Geçiş ve hareket ritmi',
    'Transition and movement rhythm',
    'Ритм переходов и движения',
  ),
  L10nKeys.animationUnavailable: L10nTriple(
    'Animasyon hızı ayarı henüz uygulanmıyor.',
    'Motion speed is not available yet.',
    'Настройка скорости движения пока недоступна.',
  ),
  L10nKeys.atmosphereTitle: L10nTriple('Atmosfer', 'Atmosphere', 'Атмосфера'),
  L10nKeys.atmosphereSubtitle: L10nTriple(
    'Atmosferik müzik açıkken hangi yatağın çalacağını seçer',
    'Chooses which bed plays when atmospheric music is on',
    'Выбирает фон, когда атмосферная музыка включена',
  ),
  L10nKeys.profilePremiumActive: L10nTriple(
    'Premium üyeliğin aktif.',
    'Your Premium membership is active.',
    'Премиум-подписка активна.',
  ),
  L10nKeys.profileManage: L10nTriple(
    'Profilini yönet.',
    'Manage your profile.',
    'Управляй профилем.',
  ),
  L10nKeys.guestName: L10nTriple('Yolcu', 'Traveler', 'Путник'),
  L10nKeys.membershipPremium:
      L10nTriple('PREMIUM', 'PREMIUM', 'ПРЕМИУМ'),
  L10nKeys.membershipStandard:
      L10nTriple('STANDART', 'STANDARD', 'СТАНДАРТ'),
  'nav.menu': L10nTriple('Menü', 'Menu', 'Меню'),
  'a11y.close': L10nTriple('Kapat', 'Close', 'Закрыть'),
  'a11y.capture': L10nTriple('Çek', 'Capture', 'Снять'),
  L10nKeys.premiumTitle: L10nTriple('Premium', 'Premium', 'Премиум'),
  L10nKeys.premiumSubtitle: L10nTriple(
    'Premium erişimini incele',
    'Explore Premium access',
    'Посмотри доступ Premium',
  ),
  L10nKeys.gemsTitle: L10nTriple('Mücevherler', 'Gems', 'Кристаллы'),
  L10nKeys.gemsSubtitle:
      L10nTriple('Kristal bakiyen', 'Your crystal balance', 'Твой баланс кристаллов'),
  L10nKeys.dailyRewardsTitle:
      L10nTriple('Günlük Ödüller', 'Daily rewards', 'Ежедневные награды'),
  L10nKeys.dailyRewardsSubtitle:
      L10nTriple('Bugünün ödülü', "Today's reward", 'Награда за сегодня'),
};
