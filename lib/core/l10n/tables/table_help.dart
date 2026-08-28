/// Help / support strings — TR · EN · RU.
library;

import '../l10n_triple.dart';

const kL10nHelp = <String, L10nTriple>{
  'help.title': L10nTriple('Yardım', 'Help', 'Помощь'),
  'help.subtitle': L10nTriple(
    'Sakin bir destek alanı — sorun bildir veya bize yaz.',
    'A quiet place to report a problem or reach us.',
    'Спокойное место, чтобы сообщить о проблеме или написать нам.',
  ),
  'help.report': L10nTriple('Sorun Bildir', 'Report a problem', 'Сообщить о проблеме'),
  'help.report_subtitle': L10nTriple(
    'Kategori seç — okuma metni gönderilmez.',
    'Pick a category — reading text is never sent.',
    'Выбери категорию — текст чтения не отправляется.',
  ),
  'help.contact': L10nTriple('Bize Ulaş', 'Contact us', 'Связаться с нами'),
  'help.contact_subtitle': L10nTriple(
    'destek@oracly.app',
    'destek@oracly.app',
    'destek@oracly.app',
  ),
  'help.privacy_note': L10nTriple(
    'Rapor yalnızca özellik, güvenli hata kategorisi ve uygulama sürümünü içerir. Fal metni, kartlar veya kişisel notlar eklenmez.',
    'A report includes only the feature, a safe error category, and the app version. Reading text, cards, or personal notes are never included.',
    'Отчёт содержит только функцию, безопасную категорию ошибки и версию приложения. Текст чтения, карты и личные заметки не включаются.',
  ),
  'help.report_title': L10nTriple(
    'Ne oldu?',
    'What happened?',
    'Что случилось?',
  ),
  'help.report_hint': L10nTriple(
    'Yalnızca bir kategori seç. İçerik otomatik eklenmez.',
    'Choose only a category. Content is not attached automatically.',
    'Выбери только категорию. Содержимое не прикрепляется.',
  ),
  'help.send': L10nTriple('Gönder', 'Send', 'Отправить'),
  'help.mail_opened': L10nTriple(
    'E-posta uygulaman açıldı.',
    'Your email app opened.',
    'Почтовое приложение открыто.',
  ),
  'help.mail_copied': L10nTriple(
    'Destek adresi ve güvenli özet panoya kopyalandı.',
    'Support address and a safe summary were copied.',
    'Адрес поддержки и безопасное резюме скопированы.',
  ),
  'help.diagnostics_title': L10nTriple(
    'Tanılama',
    'Diagnostics',
    'Диагностика',
  ),
  'help.diagnostics_version': L10nTriple(
    'Uygulama sürümü',
    'App version',
    'Версия приложения',
  ),
  'help.diagnostics_build': L10nTriple(
    'Yapı',
    'Build',
    'Сборка',
  ),
  'help.diagnostics_copy': L10nTriple(
    'Tanılama bilgisini kopyala',
    'Copy diagnostic info',
    'Скопировать диагностику',
  ),
  'help.diagnostics_copy_hint': L10nTriple(
    'Sürüm, yapı ve cihaz/OS — gizli anahtar yok.',
    'Version, build, and device/OS — no secret keys.',
    'Версия, сборка и устройство/ОС — без секретных ключей.',
  ),
  'help.diagnostics_copied': L10nTriple(
    'Güvenli tanılama bilgisi panoya kopyalandı.',
    'Safe diagnostic info was copied.',
    'Безопасная диагностика скопирована.',
  ),
  'help.diagnostics_privacy': L10nTriple(
    'Cihaz/OS yalnızca sen kopyaladığında eklenir. API adresi, jeton veya anahtar asla dahil edilmez.',
    'Device/OS is added only when you choose to copy. API URLs, tokens, or keys are never included.',
    'Устройство/ОС добавляется только при копировании. URL API, токены и ключи никогда не включаются.',
  ),
  'help.category.or_silent': L10nTriple(
    'OR cevap vermiyor',
    'OR is not responding',
    'OR не отвечает',
  ),
  'help.category.reading_failed': L10nTriple(
    'Fal sonucu yüklenmedi',
    'Reading result did not load',
    'Результат гадания не загрузился',
  ),
  'help.category.tarot': L10nTriple(
    'Tarot sorunu',
    'Tarot problem',
    'Проблема с таро',
  ),
  'help.category.image_failed': L10nTriple(
    'Görsel oluşmadı',
    'Image did not generate',
    'Изображение не создалось',
  ),
  'help.category.gems': L10nTriple(
    'Ödeme/Gem sorunu',
    'Payment / Gem problem',
    'Проблема с оплатой / Gem',
  ),
  'help.category.language': L10nTriple(
    'Dil sorunu',
    'Language problem',
    'Проблема с языком',
  ),
  'settings.help': L10nTriple('Yardım', 'Help', 'Помощь'),
  'settings.help_subtitle': L10nTriple(
    'Sorun bildir veya bize yaz',
    'Report a problem or contact us',
    'Сообщить о проблеме или написать нам',
  ),
};
