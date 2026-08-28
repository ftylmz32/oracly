/// Remaining dream chrome — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nDreamMore = <String, L10nTriple>{
  'dream.helper': L10nTriple(
    'Hatırladığın kişiler, yerler, duygular ve dikkatini çeken detaylar yorumu derinleştirebilir.',
    'People, places, feelings, and details you remember can deepen the reading.',
    'Люди, места, чувства и детали, которые помнишь, могут углубить толкование.',
  ),
  'dream.emotions_label': L10nTriple('Hissettiklerin', 'What you felt', 'Что ты чувствовал'),
  'dream.tags': L10nTriple('Etiketler (isteğe bağlı)', 'Tags (optional)', 'Метки (необязательно)'),
  'dream.tag_hint': L10nTriple('Etiket ekle', 'Add a tag', 'Добавить метку'),
  'dream.voice': L10nTriple('Sesle kaydet', 'Record by voice', 'Записать голосом'),
  'dream.voice_soon': L10nTriple(
    'Sesle anlatım henüz hazır değil. Rüyanı yazarak devam edebilirsin.',
    'Spoken telling is not ready yet. You can continue in writing.',
    'Голосовой рассказ пока не готов. Можно продолжить письмом.',
  ),
  'dream.voice_failed': L10nTriple(
    'Ses kaydı alınamadı. Rüyanı yazarak devam edebilirsin.',
    'The recording could not be taken. You can continue in writing.',
    'Запись не получилась. Можно продолжить письмом.',
  ),
  'dream.voice_listen': L10nTriple('Dinliyorum...', 'I am listening...', 'Я слушаю...'),
  'dream.voice_stop': L10nTriple('Durdur', 'Stop', 'Стоп'),
  'dream.voice_review': L10nTriple('Rüyanı kontrol et', 'Check your dream', 'Проверь сон'),
  'dream.voice_again': L10nTriple('Tekrar Dinle', 'Listen again', 'Слушать снова'),
  'dream.voice_permanent': L10nTriple(
    'Mikrofon izni kapalı. Ayarlardan açabilirsin.',
    'Microphone permission is off. You can turn it on in Settings.',
    'Доступ к микрофону выключен. Можно включить в Настройках.',
  ),
  'dream.voice_mic': L10nTriple(
    'Mikrofon bu cihazda kullanılamıyor.',
    'The microphone is not available on this device.',
    'Микрофон на этом устройстве недоступен.',
  ),
  'dream.voice_speech': L10nTriple(
    'Türkçe ses tanıma şu anda kullanılamıyor. Rüyanı yazarak devam edebilirsin.',
    'Speech recognition is not available right now. You can continue in writing.',
    'Распознавание речи сейчас недоступно. Можно продолжить письмом.',
  ),
  'dream.voice_error': L10nTriple(
    'Ses tanıma sırasında bir sorun oluştu. Tekrar dene.',
    'I could not hear that clearly. You can continue in writing.',
    'При распознавании речи произошла ошибка. Попробуй снова.',
  ),
  'dream.voice_empty': L10nTriple(
    'Seni duyamadım. Biraz daha net anlatmayı dene.',
    'I could not hear you. Try telling it a little more clearly.',
    'Я тебя не услышал. Попробуй рассказать чуть яснее.',
  ),
  'dream.phase_sum_sub': L10nTriple(
    'Rüyanın kısa özeti — ardından yorum gelir.',
    'A short summary of the dream — then the reading.',
    'Краткое содержание сна — затем толкование.',
  ),
  'dream.phase_int_sub': L10nTriple('Bu rüyanın ana okuması.', 'The main reading of this dream.', 'Основное чтение этого сна.'),
  'dream.phase_conn': L10nTriple('Önceki rüyalarla bağ', 'Link with earlier dreams', 'Связь с прежними снами'),
  'dream.phase_conn_sub': L10nTriple(
    'Yalnızca gerçek tekrarlar varsa gösterilir.',
    'Shown only when real repeats exist.',
    'Показывается только при настоящих повторах.',
  ),
  'dream.symbols_title': L10nTriple('Semboller', 'Symbols', 'Символы'),
  'dream.emotions_title': L10nTriple('Duygular', 'Feelings', 'Чувства'),
  'dream.locations': L10nTriple('Mekânlar', 'Places', 'Места'),
  'dream.relationships': L10nTriple('İlişkiler', 'Relationships', 'Отношения'),
  'dream.recurring': L10nTriple('Tekrarlayan imgeler', 'Recurring images', 'Повторяющиеся образы'),
  'dream.no_symbols': L10nTriple('Belirgin sembol tespit edilmedi.', 'No standing-out symbol was noticed.', 'Яркий символ не замечен.'),
  'dream.no_locations': L10nTriple('Belirgin mekân tespit edilmedi.', 'No standing-out place was noticed.', 'Яркое место не замечено.'),
  'dream.no_rel': L10nTriple('Belirgin ilişki tespit edilmedi.', 'No standing-out relationship was noticed.', 'Яркая связь не замечена.'),
  'dream.no_recurring': L10nTriple('Bu rüyada belirgin tekrar yok.', 'No standing-out repeat in this dream.', 'В этом сне нет яркого повтора.'),
  'dream.previous': L10nTriple('Önceki rüyalar', 'Earlier dreams', 'Прежние сны'),
  'dream.no_previous': L10nTriple(
    'İlk rüyan burada yerini bulacak.',
    'Your first dream will find its place here.',
    'Твой первый сон найдёт здесь своё место.',
  ),
};
