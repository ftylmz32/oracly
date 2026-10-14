/// Reading feedback — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nReadingFeedback = <String, L10nTriple>{
  'feedback.action': L10nTriple(
    'Bu yorumu beğenmedim',
    'This reading missed the point',
    'Это толкование мимо',
  ),
  'feedback.title': L10nTriple(
    'Yorum nasıl kaçırdı?',
    'How did this miss?',
    'Что не так?',
  ),
  'feedback.hint': L10nTriple(
    'Yalnızca kategori ve deneyim bilgisi gönderilir. Yorumun, sorun ve fotoğrafın gönderilmez.',
    'Only the category and experience are sent. Your reading, question, and photos are not sent.',
    'Отправляются только категория и тип опыта. Текст, вопросы и фото не отправляются.',
  ),
  'feedback.cat.missed': L10nTriple(
    'Yanlış anladı',
    'Missed the point',
    'Неправильно поняло',
  ),
  'feedback.cat.generic': L10nTriple(
    'Çok genel',
    'Too generic',
    'Слишком общее',
  ),
  'feedback.cat.unanswered': L10nTriple(
    'Soruma cevap vermedi',
    "Didn't answer my question",
    'Не ответило на вопрос',
  ),
  'feedback.cat.repetitive': L10nTriple(
    'Tekrarlı',
    'Repetitive',
    'Повторяется',
  ),
  'feedback.cat.inappropriate': L10nTriple(
    'Uygunsuz',
    'Inappropriate',
    'Неуместно',
  ),
  'feedback.cat.harmful': L10nTriple(
    'Zararlı veya korkutucu',
    'Harmful or frightening',
    'Вредное или пугающее',
  ),
  'feedback.cat.misleading': L10nTriple(
    'Yanıltıcı veya gerçek dışı',
    'Misleading or false claim',
    'Вводит в заблуждение',
  ),
  'feedback.cat.other': L10nTriple('Diğer', 'Other', 'Другое'),
  'feedback.retry': L10nTriple(
    'Tekrar yorumla',
    'Try another reading',
    'Толковать снова',
  ),
  'feedback.retry.note': L10nTriple(
    'Aynı içerik yeniden yorumlanır. Ek mücevher alınmaz.',
    'The same content is interpreted again. No extra gems are charged.',
    'То же содержимое толкуется снова. Дополнительно камни не списываются.',
  ),
  'feedback.send': L10nTriple('Gönder', 'Send', 'Отправить'),
  'feedback.sending': L10nTriple(
    'Bildirim gönderiliyor…',
    'Sending report…',
    'Отправка жалобы…',
  ),
  'feedback.includeContent': L10nTriple(
    'Seçtiğim AI yanıtını da gönder',
    'Also send the selected AI response',
    'Также отправить выбранный ответ ИИ',
  ),
  'feedback.includeContent.note': L10nTriple(
    'İsteğe bağlıdır. Yalnız bu AI yanıtı, en fazla 2000 karakter olarak 30 gün saklanır; sorun, fotoğraflar ve konuşma geçmişi gönderilmez.',
    'Optional. Only this AI response is kept for 30 days, up to 2,000 characters; your question, photos, and conversation history are not sent.',
    'Необязательно. Только этот ответ ИИ (до 2000 символов) хранится 30 дней; вопрос, фото и история чата не отправляются.',
  ),
  'feedback.thanks': L10nTriple(
    'Bildirimin gönderildi. Teşekkürler.',
    'Your report was sent. Thank you.',
    'Жалоба отправлена. Спасибо.',
  ),
  'feedback.send.fail': L10nTriple(
    'Bildirim gönderilemedi. Bağlantını kontrol edip tekrar deneyebilirsin.',
    'The report could not be sent. Check your connection and try again.',
    'Не удалось отправить жалобу. Проверьте соединение и повторите попытку.',
  ),
  'feedback.retrying': L10nTriple(
    'Yeni yorum hazırlanıyor — mücevher alınmaz.',
    'Preparing another reading — no extra gems.',
    'Готовим новое толкование — без списания камней.',
  ),
  'feedback.retry.ok': L10nTriple(
    'Yeni yorum hazır. Mücevher alınmadı.',
    'A new reading is ready. No gems were charged.',
    'Новое толкование готово. Камни не списаны.',
  ),
  'feedback.retry.fail': L10nTriple(
    'Yeni yorum şimdi oluşmadı. Mücevher alınmadı.',
    'Another reading could not be made now. No gems were charged.',
    'Новое толкование сейчас не получилось. Камни не списаны.',
  ),
  'feedback.positive': L10nTriple(
    'Bu yorum yardımcı oldu',
    'This reading helped',
    'Это толкование помогло',
  ),
  'feedback.positive.thanks': L10nTriple(
    'Teşekkürler. Yalnızca kalite notu tutuldu.',
    'Thank you. Only a quality note was kept.',
    'Спасибо. Сохранена только заметка о качестве.',
  ),
};
