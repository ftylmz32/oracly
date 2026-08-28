/// Errors, loading, empty, auth — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nResilience = <String, L10nTriple>{
  'resilience.error_title': L10nTriple(
    'Bir anlık aksaklık',
    'A momentary pause',
    'Короткая пауза',
  ),
  'resilience.retry': L10nTriple(
    'TEKRAR DENE',
    'TRY AGAIN',
    'ЕЩЁ РАЗ',
  ),
  'resilience.chat_loading': L10nTriple(
    'Seni dinliyorum…',
    'I am listening…',
    'Слушаю…',
  ),
  'resilience.memory_loading': L10nTriple(
    'Hafızana bakıyorum…',
    'Looking at what you saved…',
    'Смотрю на то, что ты сохранил…',
  ),
  'resilience.history_loading': L10nTriple(
    'Geçmişine bakıyorum…',
    'I am looking at what you left…',
    'Смотрю на то, что ты оставил…',
  ),
  'resilience.splash_loading': L10nTriple(
    'ORACLY açılıyor…',
    'ORACLY is opening…',
    'ORACLY открывается…',
  ),
  'resilience.generic_loading': L10nTriple(
    'Bir saniye…',
    'One second…',
    'Секунду…',
  ),
  'resilience.settings_loading': L10nTriple(
    'Ayarlar açılıyor…',
    'Settings are opening…',
    'Настройки открываются…',
  ),
  'resilience.achievements_loading': L10nTriple(
    'Hatırladıklarına bakıyorum…',
    'Looking back at what you have shared…',
    'Смотрю на то, что ты уже открыл…',
  ),
  'resilience.profile_loading': L10nTriple(
    'Profilin açılıyor…',
    'Your profile is opening…',
    'Профиль открывается…',
  ),
  'resilience.generic_failed': L10nTriple(
    'Şu an açılamadı. Biraz sonra tekrar deneyebilirsin.',
    'Could not open this right now. You can try again in a moment.',
    'Сейчас не открылось. Можно попробовать через мгновение.',
  ),
  'resilience.offline': L10nTriple(
    'Bağlantı kurulamadı. Biraz sonra tekrar deneyebilirsin.',
    'Connection could not be made. You can try again in a moment.',
    'Связь не установилась. Можно попробовать через мгновение.',
  ),
  'resilience.temporary': L10nTriple(
    'Geçici bir aksaklık oldu. Bir daha deneyelim.',
    'A temporary pause happened. Let us try again.',
    'Случилась короткая пауза. Давай попробуем ещё раз.',
  ),
  'resilience.invalid_input': L10nTriple(
    'Bu girdiyle ilerleyemedim. Biraz netleştirip tekrar dene.',
    'I could not continue with this input. Clarify a little and try again.',
    'С этим вводом не получилось. Уточни немного и попробуй снова.',
  ),
  'resilience.analysis_unavailable': L10nTriple(
    'Analiz şu an hazır değil. Biraz sonra tekrar deneyebilirsin.',
    'Analysis is not ready right now. You can try again in a moment.',
    'Анализ сейчас не готов. Можно попробовать через мгновение.',
  ),
  'resilience.history_failed': L10nTriple(
    'Geçmişe şu an ulaşılamıyor. Biraz sonra tekrar deneyebilirsin.',
    'History is unreachable right now. You can try again in a moment.',
    'История сейчас недоступна. Можно попробовать через мгновение.',
  ),
  'resilience.history_failed_title': L10nTriple(
    'Geçmiş açılamadı',
    'History could not open',
    'История не открылась',
  ),
  'resilience.slow': L10nTriple(
    'Yanıt beklenenden uzun sürüyor. Bir an bekle veya tekrar dene.',
    'The reply is taking longer than usual. Wait a moment or try again.',
    'Ответ идёт дольше обычного. Подожди немного или попробуй снова.',
  ),
  'resilience.ai_unavailable': L10nTriple(
    "OR'a ulaşamadım. Bir daha deneyelim.",
    "I couldn't reach OR. Let's try again.",
    'Не удалось связаться с OR. Давай попробуем ещё раз.',
  ),
  'resilience.ai_config': L10nTriple(
    'OR henüz hazır değil. Lütfen daha sonra tekrar dene.',
    'OR is not ready yet. Please try again later.',
    'OR ещё не готов. Пожалуйста, попробуй позже.',
  ),
  'resilience.ai_unauthorized': L10nTriple(
    'Oturum doğrulanamadı. Lütfen yeniden giriş yapıp dene.',
    'Session could not be verified. Please sign in again and try.',
    'Сессию не удалось подтвердить. Войди снова и попробуй.',
  ),
  'resilience.ai_empty': L10nTriple(
    'Yanıt bu sefer gelmedi. Tekrar denemek ister misin?',
    'No reply arrived this time. Would you like to try again?',
    'Ответ в этот раз не пришёл. Хочешь попробовать снова?',
  ),
  'resilience.ai_response': L10nTriple(
    'Yanıt alınamadı. Biraz sonra tekrar deneyebilirsin.',
    'No reply was received. You can try again in a moment.',
    'Ответ не получен. Можно попробовать через мгновение.',
  ),
  'resilience.ai_rate': L10nTriple(
    'OR şu anda yoğun. Lütfen biraz sonra tekrar dene.',
    'OR is busy right now. Please try again in a little while.',
    'OR сейчас занят. Пожалуйста, попробуй чуть позже.',
  ),
  'resilience.card_draw_failed': L10nTriple(
    'Kart seçilemedi. Lütfen tekrar dene.',
    'The card could not be drawn. Please try again.',
    'Карту не удалось выбрать. Пожалуйста, попробуй снова.',
  ),
  'resilience.session_init': L10nTriple(
    'Açılım başlatılamadı. Geri dönüp tekrar dene.',
    'The spread could not start. Go back and try again.',
    'Расклад не начался. Вернись и попробуй снова.',
  ),
  'resilience.interpretation_failed': L10nTriple(
    'Yorum şu an hazırlanamadı. Biraz sonra tekrar dene.',
    'The reading could not be prepared. Try again in a moment.',
    'Толкование сейчас не готово. Попробуй через мгновение.',
  ),
  'resilience.interpretation_timeout': L10nTriple(
    'Yorum beklenenden uzun sürdü. Tekrar deneyebilirsin.',
    'The reading took longer than expected. You can try again.',
    'Толкование заняло больше обычного. Можно попробовать снова.',
  ),
  'resilience.oracle_send': L10nTriple(
    'Bağlantı koptu.\nBir daha deneyelim.',
    "The connection dropped.\nLet's try again.",
    'Связь оборвалась.\nДавай попробуем ещё раз.',
  ),
  'resilience.oracle_regen': L10nTriple(
    'Yeniden oluşturulamadı. Tekrar dene.',
    'It could not be regenerated. Try again.',
    'Не удалось создать заново. Попробуй снова.',
  ),
  'resilience.memory_empty_title': L10nTriple(
    'İlk hafızan burada yerini bulacak.',
    'Your first memory will find its place here.',
    'Твоя первая память найдёт здесь своё место.',
  ),
  'resilience.memory_empty_body': L10nTriple(
    'OR, sohbetlerinden öğrendikçe burada nazikçe birikecek. İstediğin zaman silebilirsin.',
    'OR will gather here gently as it learns from your conversations. You can delete it anytime.',
    'OR будет мягко собираться здесь, учась из разговоров. Можно удалить в любой момент.',
  ),
  'resilience.chat_empty_title': L10nTriple(
    'İlk sohbetin burada yerini bulacak.',
    'Your first conversation will find its place here.',
    'Твой первый разговор найдёт здесь своё место.',
  ),
  'resilience.chat_empty_body': L10nTriple(
    'OR ile konuşmaya başladığında geçmişin burada görünecek.',
    'When you start speaking with OR, history will appear here.',
    'Когда начнёшь говорить с OR, история появится здесь.',
  ),
  'resilience.bootstrap_failed': L10nTriple(
    'Uygulama açılırken küçük bir aksaklık oldu. Tekrar dene.',
    'A small pause happened while opening. Try again.',
    'При открытии произошла короткая пауза. Попробуй снова.',
  ),
  'resilience.profile_failed': L10nTriple(
    'Profil şu an açılamadı. Biraz sonra tekrar deneyebilirsin.',
    'Profile could not open right now. You can try again in a moment.',
    'Профиль сейчас не открылся. Можно попробовать через мгновение.',
  ),
  'resilience.settings_save_failed': L10nTriple(
    'Bu ayarı şu anda uygulayamadım. Bir daha deneyelim.',
    'Could not apply this setting right now. Let us try again.',
    'Не удалось применить эту настройку. Давай попробуем ещё раз.',
  ),
  'auth.not_configured': L10nTriple(
    'Giriş henüz hazır değil. Lütfen daha sonra dene.',
    'Sign-in is not ready yet. Please try later.',
    'Вход ещё не готов. Пожалуйста, попробуй позже.',
  ),
  'auth.failed': L10nTriple(
    'Giriş tamamlanamadı. Bir daha deneyelim.',
    'Sign-in could not finish. Let us try again.',
    'Вход не завершился. Давай попробуем ещё раз.',
  ),
  'auth.invalid': L10nTriple(
    'Giriş bilgileri tutmadı. Kontrol edip tekrar dene.',
    'Sign-in details did not match. Check them and try again.',
    'Данные входа не совпали. Проверь и попробуй снова.',
  ),
  'auth.too_many': L10nTriple(
    'Çok fazla deneme. Biraz sonra dene.',
    'Too many attempts. Try again later.',
    'Слишком много попыток. Попробуй позже.',
  ),
  'auth.signed_out': L10nTriple(
    'Oturum kapatıldı.',
    'Signed out.',
    'Сеанс завершён.',
  ),
};
