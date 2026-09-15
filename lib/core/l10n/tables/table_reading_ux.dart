/// Long-form reading UX — expand, never shout.
library;

import '../l10n_triple.dart';

const kL10nReadingUx = <String, L10nTriple>{
  'read.ux.continue': L10nTriple(
    'Devamını oku',
    'Continue reading',
    'Читать дальше',
  ),
  'read.wait.title.coffee': L10nTriple(
    'Fincanın bekliyor',
    'Your cup is waiting',
    'Чашка ждёт',
  ),
  'read.wait.title.palm': L10nTriple(
    'Elin bekliyor',
    'Your hand is waiting',
    'Ладонь ждёт',
  ),
  'read.wait.title.soulmate': L10nTriple(
    'Portre bekliyor',
    'The portrait is waiting',
    'Портрет ждёт',
  ),
  'read.wait.processing': L10nTriple(
    'Hazırlanıyor',
    'Preparing',
    'Готовится',
  ),
  'read.wait.processing_detail': L10nTriple(
    'Yorumun oluşturuluyor…',
    'Your interpretation is being created…',
    'Толкование создаётся…',
  ),
  'read.wait.overdue_waiting': L10nTriple(
    'İşleme alınıyor…',
    'Getting picked up now…',
    'Скоро начнётся обработка…',
  ),
  'read.wait.accelerate': L10nTriple(
    'Hemen hazırla',
    'Prepare now',
    'Приготовить сейчас',
  ),
  'read.wait.leave': L10nTriple(
    'Ayrılabilirsin. Yerini tutarız.',
    'You can leave. We will keep your place.',
    'Можно уйти. Мы сохраним место.',
  ),
  'read.wait.insufficient': L10nTriple(
    'Bu hızlandırma için yeterli taş yok.',
    'There are not enough gems for this.',
    'Недостаточно камней для этого.',
  ),
  'read.wait.price_changed': L10nTriple(
    'Fiyat güncellendi, taşların harcanmadı. Yeni fiyatla tekrar dene.',
    'The price just updated -- no gems were spent. Please try again.',
    'Цена обновилась, кристаллы не списаны. Попробуй ещё раз.',
  ),
  'read.wait.refunded': L10nTriple(
    'Hazırlık tamamlanamadı. Taşlar hesabına döndü.',
    'This could not be finished. The gems were returned.',
    'Не удалось завершить. Камни вернулись.',
  ),
  'read.wait.failed': L10nTriple(
    'Bu hazırlık tamamlanamadı.',
    'This could not be finished.',
    'Это не удалось завершить.',
  ),
  'read.wait.headline': L10nTriple(
    'Falın hazırlanıyor',
    'Your reading is being prepared',
    'Твоё гадание готовится',
  ),
  'read.wait.subtitle': L10nTriple(
    'Yorumun özenle hazırlanıyor. Birazdan hazır olacak.',
    'Your reading is being carefully prepared. It will be ready shortly.',
    'Твоё толкование готовится с заботой. Скоро будет готово.',
  ),
  'read.wait.hours': L10nTriple('saat', 'hours', 'часов'),
  'read.wait.minutes': L10nTriple('dakika', 'minutes', 'минут'),
  'read.wait.seconds': L10nTriple('saniye', 'seconds', 'секунд'),
  'read.wait.accelerate_cta': L10nTriple(
    '💎 Mücevherle Hemen Aç',
    '💎 Unlock Now with Gems',
    '💎 Открыть сейчас за кристаллы',
  ),
  'read.wait.accelerate_cta_cost': L10nTriple(
    '{cost} 💎 ile Hemen Hazırla',
    'Unlock Now for {cost} 💎',
    'Открыть сейчас за {cost} 💎',
  ),
  'read.wait.background_info': L10nTriple(
    'Uygulamayı kapatsan da süre işlemeye devam eder. Dilediğin zaman geri dönebilirsin.',
    'Even if you close the app, the timer keeps running. You can come back anytime.',
    'Даже если закроешь приложение, время продолжает идти. Можешь вернуться в любой момент.',
  ),
};
