/// Remaining Yıldızname form and result chrome — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nBirthMore = <String, L10nTriple>{
  'birth.preview_badge': L10nTriple('Önizleme', 'Preview', 'Предпросмотр'),
  'birth.capability': L10nTriple(
    'Güneş burcuna göre sembolik bir yansıma.',
    'A symbolic reflection from the sun sign.',
    'Символическое отражение по солнечному знаку.',
  ),
  'birth.personalize_empty': L10nTriple(
    'Güneş burcuna göre kişisel yorum için doğum tarihini ekle.',
    'Add a birth date for a personal Sun-sign reading.',
    'Добавь дату рождения для личного чтения Солнца.',
  ),
  'birth.enter_info': L10nTriple('Doğum Bilgilerini Gir', 'Enter birth details', 'Введи данные рождения'),
  'birth.time_note': L10nTriple(
    'İsteğe bağlı. Şimdilik hesaba katılmaz; ileride Yükselen için saklanır.',
    'Optional. Not used yet; stored later for Rising.',
    'Необязательно. Пока не учитывается; позже сохранится для Асцендента.',
  ),
  'birth.place_note': L10nTriple(
    'İsteğe bağlı. Şimdilik hesaba katılmaz; ileride yerel gökyüzü için saklanır.',
    'Optional. Not used yet; stored later for a local sky.',
    'Необязательно. Пока не учитывается; позже сохранится для местного неба.',
  ),
  'birth.time_required': L10nTriple('Doğum saatini seç.', 'Choose a birth time.', 'Выбери время рождения.'),
  'birth.place_required': L10nTriple('Doğum şehrini seç.', 'Choose a birth city.', 'Выбери город рождения.'),
  'birth.time_known': L10nTriple(
    'Doğum saatimi biliyorum',
    'I know my birth time',
    'Я знаю время рождения',
  ),
  'birth.time_unknown': L10nTriple(
    'Doğum saatimi bilmiyorum',
    'I do not know my birth time',
    'Я не знаю время рождения',
  ),
  'birth.time_unknown_value': L10nTriple('Bilinmiyor', 'Unknown', 'Неизвестно'),
  'birth.time_unknown_note': L10nTriple(
    'Saat bilinmediğinde yorum yalnızca doğum tarihine dayanır; Yükselen hesaplanmaz.',
    'Without a birth time the reading stays date-only; Rising is not calculated.',
    'Без времени рождения чтение строится только на дате; Асцендент не считается.',
  ),
  'birth.time_choice_prompt': L10nTriple(
    'Doğum saatin hakkında',
    'About your birth time',
    'О времени рождения',
  ),
  'birth.time_choice_required': L10nTriple(
    'Lütfen doğum saatini biliyor musun, belirt.',
    'Please say whether you know your birth time.',
    'Укажи, знаешь ли ты время рождения.',
  ),
  'birth.trust_note': L10nTriple(
    'Bilgilerin yalnızca yorumunu oluşturmak için kullanılır.',
    'Your details are used only to shape your reading.',
    'Данные используются только для твоего толкования.',
  ),
  'birth.review_title': L10nTriple('Özet', 'Summary', 'Кратко'),
  'birth.review_date': L10nTriple('Tarih', 'Date', 'Дата'),
  'birth.review_time': L10nTriple('Saat', 'Time', 'Время'),
  'birth.review_place': L10nTriple('Yer', 'Place', 'Место'),
  'birth.preparing': L10nTriple(
    'Bir an, doğum tarihine bakıyorum…',
    'One moment, I am looking at the birth date…',
    'Мгновение, смотрю на дату рождения…',
  ),
  'birth.recover_failed': L10nTriple(
    'Yorum yüklenemedi. Tekrar deneyebilir veya yeni bir yorum oluşturabilirsin.',
    'The reading could not load. You can try again or create a new one.',
    'Толкование не загрузилось. Можно попробовать снова или создать новое.',
  ),
  'birth.incomplete_title': L10nTriple('Yorum henüz hazır değil', 'The reading is not ready yet', 'Толкование ещё не готово'),
  'birth.incomplete_body': L10nTriple(
    'Kayıtlı yorumun tamamlanmamış görünüyor. Yolculuğu yeniden hazırlayabiliriz veya sıfırdan başlayabilirsin.',
    'The saved reading looks unfinished. We can prepare the journey again, or you can start from the beginning.',
    'Сохранённое толкование выглядит незавершённым. Можно подготовить путь снова или начать сначала.',
  ),
  'birth.recover': L10nTriple('Yolculuğu hazırla', 'Prepare the journey', 'Подготовить путь'),
  'birth.start_over': L10nTriple('Baştan başla', 'Start over', 'Начать сначала'),
  'birth.new_chart': L10nTriple('Yeni yorum oluştur', 'Create a new reading', 'Создать новое толкование'),
  'birth.clear': L10nTriple('Kayıtlı yorumu sil', 'Delete saved reading', 'Удалить сохранённое толкование'),
  'birth.cleared': L10nTriple(
    'Kayıtlı yorum silindi. Doğum bilgilerini yeniden girebilirsin.',
    'The saved reading was deleted. You can enter birth details again.',
    'Сохранённое толкование удалено. Можно снова ввести данные рождения.',
  ),
  'birth.corrupt': L10nTriple(
    'Eski kayıt okunamadı ve temizlendi. Lütfen doğum bilgilerini yeniden gir.',
    'The old record could not be read and was cleared. Please enter birth details again.',
    'Старая запись не прочиталась и очищена. Пожалуйста, введи данные рождения снова.',
  ),
  'birth.error': L10nTriple(
    'Harita bu sefer açılamadı. Bir daha deneyelim.',
    'The chart could not open this time. Let us try again.',
    'Карта в этот раз не открылась. Давай попробуем ещё раз.',
  ),
  'birth.go_back': L10nTriple('Geri', 'Back', 'Назад'),
  'birth.step': L10nTriple('Adım', 'Step', 'Шаг'),
  'birth.placements': L10nTriple('Temel Yerleşimler', 'Core placements', 'Основные положения'),
  'birth.summary': L10nTriple('Yorumun özeti', 'Summary of the reading', 'Краткое толкование'),
  'birth.strong': L10nTriple('Güçlü Temaların', 'Strong themes', 'Сильные темы'),
  'birth.notable': L10nTriple('Dikkat Çeken Temalar', 'Standing-out themes', 'Заметные темы'),
  'birth.planets': L10nTriple('Gezegenler', 'Planets', 'Планеты'),
  'birth.houses': L10nTriple('Evler', 'Houses', 'Дома'),
  'birth.aspects': L10nTriple('Önemli Açılar', 'Notable aspects', 'Важные аспекты'),
  'birth.theme': L10nTriple('Ana tema', 'Main theme', 'Главная тема'),
  'birth.stored_note': L10nTriple(
    'Saat ve yer şimdilik saklanır; hesaba katılmaz.',
    'Time and place are stored for now; they are not used in the calculation.',
    'Время и место пока сохраняются; в расчёт не входят.',
  ),
  'birth.ephemeris': L10nTriple(
    'Önizleme · bu yorum sembolik bir astroloji yorumudur. Ay, Yükselen, gezegenler, evler ve açılar gerçek bir hesap kaynağı bağlandığında gösterilecek. Şu an Güneş burcun, doğum tarihinden tropikal takvime göre hesaplanır.',
    'Preview · this is a symbolic astrology reading. Moon, Rising, planets, houses, and aspects will show when a real calculation source is connected. The Sun sign is calculated from the birth date on the tropical calendar.',
    'Предпросмотр · это символическое астрологическое чтение. Луна, Асцендент, планеты, дома и аспекты появятся, когда подключится реальный расчёт. Солнце сейчас считается по дате рождения в тропическом календаре.',
  ),
  'birth.sun_gloss': L10nTriple(
    'Güneş burcu, özünü ve vitrini temsil eder — dışarıya nasıl parladığını anlatır.',
    'The Sun sign represents your core and how you shine outward.',
    'Солнечный знак представляет суть и то, как ты светишь вовне.',
  ),
  'birth.moon_gloss': L10nTriple(
    'Ay burcu, duygusal dünyanı ve içsel ihtiyaçlarını yansıtır.',
    'The Moon sign reflects your inner world and needs.',
    'Лунный знак отражает внутренний мир и потребности.',
  ),
  'birth.rising_gloss': L10nTriple(
    'Yükselen, tanışıldığında görünen yüzün — ilk izlenim ve yaşam yaklaşımınla ilişkilidir.',
    'Rising is the face others meet — first impression and how you approach life.',
    'Асцендент — лицо при встрече: первое впечатление и подход к жизни.',
  ),
  'birth.rising_na': L10nTriple(
    'Saat bilinmediği için Yükselen hesaplanamadı.',
    'Rising could not be calculated because the time is unknown.',
    'Асцендент не рассчитан: время неизвестно.',
  ),
  'birth.interp_title': L10nTriple('Ana yorum', 'Main reading', 'Основное толкование'),
  'birth.closing': L10nTriple(
    'Bu yorum bir etiket değil; kendini tanımak için bir ayna. En doğru yorumu zamanla sen yazarsın.',
    'This reading is not a label; it is a mirror for knowing yourself. The truest reading is the one you write over time.',
    'Это толкование не ярлык, а зеркало для себя. Самое верное ты напишешь со временем.',
  ),
  'birth.big_three': L10nTriple('Büyük Üçlü', 'The big three', 'Большая тройка'),
  'birth.core': L10nTriple('Temel kişilik', 'Core personality', 'Основной характер'),
  'birth.life': L10nTriple('Yaşam temaları', 'Life themes', 'Темы жизни'),
  'preview.astro_detail': L10nTriple(
    'Bu bir yansıma, hüküm değil. Yerel Güneş burcu kataloğundan okunuyor — canlı ephemeris değil.',
    'This is a reflection, not a verdict. It is read from a local sun-sign catalogue — not a live ephemeris.',
    'Это отражение, не приговор. Читается из локального каталога солнечного знака — не живой эфемериды.',
  ),
};
