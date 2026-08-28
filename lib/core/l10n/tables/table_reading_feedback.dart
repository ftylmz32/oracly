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
    'Seçimin yalnızca kalite için tutulur. Metin saklanmaz.',
    'Your choice is kept only as quality metadata. The text is not stored.',
    'Выбор хранится только как метаданные качества. Текст не сохраняется.',
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
  'feedback.retry': L10nTriple(
    'Tekrar yorumla',
    'Try another reading',
    'Толковать снова',
  ),
  'feedback.retry.note': L10nTriple(
    'Aynı açılım yeniden yorumlanır. Ek mücevher alınmaz.',
    'The same draw is read again. No extra gems are charged.',
    'То же раскрытие толкуется снова. Дополнительно камни не списываются.',
  ),
  'feedback.send': L10nTriple('Gönder', 'Send', 'Отправить'),
  'feedback.thanks': L10nTriple(
    'Notunu aldık. Teşekkürler.',
    'Noted. Thank you.',
    'Записали. Спасибо.',
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
