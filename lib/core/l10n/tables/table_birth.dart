/// Birth chart form chrome — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nBirth = <String, L10nTriple>{
  'birth.screen_title': L10nTriple('Yıldızname', 'Star reading', 'Звёздная книга'),
  'birth.onboarding_headline': L10nTriple('Doğum tarihin', 'Your birth date', 'Дата рождения'),
  'birth.onboarding_body': L10nTriple(
    'Önizleme · Yıldızname, Güneş burcuna göre sembolik bir yorumdur. Güneş burcu yalnızca doğum tarihinden hesaplanır. Saat ve şehir isteğe bağlıdır; şimdilik hesaba katılmaz.',
    'Preview · Star reading is a symbolic Sun-sign reading. The Sun sign is calculated from the birth date only. Time and city are optional and not used yet.',
    'Предпросмотр · Звёздная книга — символическое чтение Солнца. Солнце считается только по дате рождения. Время и город необязательны и пока не используются.',
  ),
  'birth.date_label': L10nTriple('Doğum tarihi', 'Birth date', 'Дата рождения'),
  'birth.time_label': L10nTriple('Doğum saati (isteğe bağlı)', 'Birth time (optional)', 'Время рождения (необязательно)'),
  'birth.place_label': L10nTriple('Doğum yeri (isteğe bağlı)', 'Birth place (optional)', 'Место рождения (необязательно)'),
  'birth.place_hint': L10nTriple('Şehir seç', 'Choose a city', 'Выбери город'),
  'birth.search_city': L10nTriple('Şehir ara', 'Search city', 'Искать город'),
  'birth.select': L10nTriple('Seç', 'Choose', 'Выбрать'),
  'birth.date_required': L10nTriple('Doğum tarihini seç.', 'Choose a birth date.', 'Выбери дату рождения.'),
  'birth.generate': L10nTriple('Yorumu aç', 'Open the reading', 'Открыть толкование'),
  'birth.update': L10nTriple('Yorumu güncelle', 'Update the reading', 'Обновить толкование'),
  'birth.update_info': L10nTriple('Bilgileri güncelle', 'Update details', 'Обновить данные'),
  'birth.cancel': L10nTriple('Vazgeç', 'Dismiss', 'Отменить'),
  'birth.generating': L10nTriple(
    'Yıldızlarındaki izlere bakıyorum…',
    'I am looking at the marks in your stars…',
    'Смотрю на следы в твоих звёздах…',
  ),
  'birth.generate_failed': L10nTriple(
    'Yorum oluşturulamadı. Biraz sonra tekrar deneyebilirsin.',
    'The reading could not be created. You can try again in a moment.',
    'Толкование не создалось. Можно попробовать через мгновение.',
  ),
  'birth.retry': L10nTriple('TEKRAR DENE', 'TRY AGAIN', 'ЕЩЁ РАЗ'),
  'birth.sun': L10nTriple('Güneş', 'Sun', 'Солнце'),
  'birth.moon': L10nTriple('Ay', 'Moon', 'Луна'),
  'birth.rising': L10nTriple('Yükselen', 'Rising', 'Асцендент'),
  'birth.section_sun': L10nTriple('Güneş burcun', 'Your Sun sign', 'Твой солнечный знак'),
  'birth.result': L10nTriple('Yorum', 'Reading', 'Толкование'),
};
