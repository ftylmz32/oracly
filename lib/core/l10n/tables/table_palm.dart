/// Palm reading chrome — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nPalm = <String, L10nTriple>{
  'palm.screen_title': L10nTriple('EL FALI', 'PALM READING', 'ХИРОМАНТИЯ'),
  'palm.landing_line': L10nTriple(
    'Elindeki çizgilerin anlattığı hikâyeyi keşfet.',
    'Discover the story told by the lines in your hand.',
    'Открой историю, которую рассказывают линии на твоей ладони.',
  ),
  'palm.ritual_title': L10nTriple(
    'Avucunu hazırla',
    'Prepare your palm',
    'Подготовь ладонь',
  ),
  'palm.ritual_body': L10nTriple(
    'Avucunun tamamını kadraja al.',
    'Fit the whole palm in the frame.',
    'Помести всю ладонь в кадр.',
  ),
  'palm.landing_steps': L10nTriple(
    'Elini seç · Fotoğrafı yükle · Çizgilerini keşfet',
    'Choose a hand · Upload · Discover the lines',
    'Выбери руку · Загрузи · Открой линии',
  ),
  'palm.step.select': L10nTriple('Elini seç', 'Choose a hand', 'Выбери руку'),
  'palm.step.upload': L10nTriple(
    'Fotoğrafı yükle',
    'Upload the photo',
    'Загрузи фото',
  ),
  'palm.step.discover': L10nTriple(
    'Çizgilerini keşfet',
    'Discover the lines',
    'Открой линии',
  ),
  'palm.capability_note': L10nTriple(
    'El yorumu için OR bağlantısı gerekir.',
    'A palm reading needs an OR connection.',
    'Для чтения ладони нужно соединение с OR.',
  ),
  'palm.analyze_cta': L10nTriple(
    'YORUMU AÇ',
    'OPEN THE READING',
    'ОТКРОЙ ТОЛКОВАНИЕ',
  ),
  'palm.camera': L10nTriple('FOTOĞRAF ÇEK', 'TAKE PHOTO', 'СФОТОГРАФИРОВАТЬ'),
  'palm.gallery': L10nTriple(
    'GALERİDEN SEÇ',
    'CHOOSE FROM GALLERY',
    'ВЫБРАТЬ ИЗ ГАЛЕРЕИ',
  ),
  'palm.preview_label': L10nTriple(
    'Eli incele',
    'Review the hand',
    'Рассмотри руку',
  ),
  'palm.add_photo_title': L10nTriple(
    'El fotoğrafı seç',
    'Choose a hand photo',
    'Выбери фото руки',
  ),
  'palm.capture_guide': L10nTriple(
    'Avucunun tamamını kadraja al.',
    'Fit the whole palm in the frame.',
    'Помести всю ладонь в кадр.',
  ),
  'palm.capture_tips': L10nTriple(
    'Tam el · Parmaklar açık · Avuç görünür · Yumuşak ışık',
    'Full hand · Fingers open · Palm visible · Soft light',
    'Вся рука · Пальцы открыты · Ладонь видна · Мягкий свет',
  ),
  'palm.use_photo': L10nTriple(
    'Bu fotoğrafı kullan',
    'Use this photo',
    'Использовать это фото',
  ),
  'palm.retake': L10nTriple('Yeniden çek', 'Retake', 'Снять заново'),
  'palm.preview_cta_hint': L10nTriple(
    'Avuç içi net görünsün.',
    'Keep the palm clearly visible.',
    'Ладонь должна быть чётко видна.',
  ),
  'palm.add_photo_hint': L10nTriple(
    'Avuç içinin tamamı görünsün. Net, iyi ışıkta ve yakından çek.',
    'Show the whole palm. Photograph closely, in good light.',
    'Должна быть видна вся ладонь. Сними крупно, при хорошем свете.',
  ),
  'palm.right_hand': L10nTriple('SAĞ EL', 'RIGHT HAND', 'ПРАВАЯ РУКА'),
  'palm.left_hand': L10nTriple('SOL EL', 'LEFT HAND', 'ЛЕВАЯ РУКА'),
  'palm.hand_hint': L10nTriple(
    'Mümkünse hangi eli çektiğini seç.',
    'If you can, choose which hand you photographed.',
    'Если можешь, выбери, какую руку снял.',
  ),
  'palm.image_required': L10nTriple(
    'Önce bir el fotoğrafı ekle.',
    'Add a hand photo first.',
    'Сначала добавь фото руки.',
  ),
  'palm.image_missing': L10nTriple(
    'Fotoğraf bulunamadı. Yeni bir kare seç.',
    'Photo not found. Choose another frame.',
    'Фото не найдено. Выбери другой кадр.',
  ),
  'palm.image_unreadable': L10nTriple(
    'Bu dosya bir fotoğraf olarak açılamadı. Başka bir kare dene.',
    'This file could not be opened as a photo. Try another frame.',
    'Этот файл не открылся как фото. Попробуй другой кадр.',
  ),
  'palm.image_too_small': L10nTriple(
    'Avuç içi daha net görünecek şekilde yeni bir fotoğraf çek.',
    'Take a new photo so the palm is clearer.',
    'Сделай новое фото, чтобы ладонь была яснее.',
  ),
  'palm.image_too_large': L10nTriple(
    'Fotoğraf çok ağır. Daha küçük veya daha sade bir kare seç.',
    'The photo is too heavy. Choose a smaller or simpler frame.',
    'Фото слишком тяжёлое. Выбери меньший или проще кадр.',
  ),
  'palm.quality.brighten': L10nTriple(
    'Avucunu biraz daha aydınlık çek.',
    'Photograph the palm with a little more light.',
    'Сними ладонь чуть светлее.',
  ),
  'palm.quality.frame': L10nTriple(
    'Parmaklar ve avuç içi birlikte görünsün.',
    'Keep the fingers and the palm together in the frame.',
    'Пусть пальцы и ладонь будут в кадре вместе.',
  ),
  'palm.quality.blur': L10nTriple(
    'Avuç içi daha net görünsün.',
    'Keep the palm a little sharper.',
    'Пусть ладонь будет чуть чётче.',
  ),
  'palm.quality.missing': L10nTriple(
    'Avucunun içi kadrajda net görünsün.',
    'Keep the inside of the palm clearly in the frame.',
    'Пусть внутренняя сторона ладони будет ясно в кадре.',
  ),
  'palm.quality.closer': L10nTriple(
    'Avucunu kadraja biraz daha yaklaştır.',
    'Bring the palm a little closer in the frame.',
    'Приблизь ладонь в кадре.',
  ),
  'palm.quality.one_hand': L10nTriple(
    'Kadroda tek bir el olsun.',
    'Keep a single hand in the frame.',
    'Пусть в кадре будет одна рука.',
  ),
  'palm.camera_unavailable': L10nTriple(
    'Kamera bu cihazda açılamadı. Galeriden seç.',
    'The camera could not open on this device. Choose from the gallery.',
    'Камера на этом устройстве не открылась. Выбери из галереи.',
  ),
  'palm.camera_permission_rationale': L10nTriple(
    'Avuç içini fotoğraflamak için kameraya ihtiyacımız var. Gizlilik: Fotoğraf sadece bu işlem için kullanılır. Detaylar Gizlilik ekranında.',
    'We need the camera to photograph your palm. Privacy: the photo is used only for this reading. Details in the Privacy screen.',
    'Нужна камера, чтобы сфотографировать вашу ладонь. Конфиденциальность: фото используется только для чтения. Детали — в экране «Приватность».',
  ),
  'palm.gallery_unavailable': L10nTriple(
    'Galeri bu cihazda açılamadı.',
    'The gallery could not open on this device.',
    'Галерея на этом устройстве не открылась.',
  ),
  'palm.analyzing': L10nTriple(
    'Çizgilerin arasındaki örüntüye bakıyorum...',
    'I am looking at the pattern between the lines...',
    'Смотрю на узор между линиями...',
  ),
  'palm.analyzing_hint': L10nTriple(
    'Gerçek el fotoğrafına bakıyorum — tıbbi tarama değil.',
    'Looking at your real hand photo — not a medical scan.',
    'Смотрю на реальное фото руки — не медицинское сканирование.',
  ),
  'palm.analysis_unavailable': L10nTriple(
    'El falı şu an hazırlanamadı. Biraz sonra tekrar deneyebilirsin.',
    'Palm reading could not be prepared. You can try again in a moment.',
    'Чтение ладони сейчас не готово. Можно попробовать через мгновение.',
  ),
  'palm.analysis_failed': L10nTriple(
    'Yorum bu sefer tutmadı. Bir daha deneyelim.',
    "The reading did not land this time. Let's try again.",
    'Толкование в этот раз не сложилось. Давай попробуем ещё раз.',
  ),
  'palm.retry': L10nTriple('TEKRAR DENE', 'TRY AGAIN', 'ЕЩЁ РАЗ'),
  'palm.new_palm': L10nTriple('Yeni el', 'New hand', 'Новая рука'),
  'palm.overall_title': L10nTriple(
    'SENİN ELİNİN HİKÂYESİ',
    "YOUR HAND'S STORY",
    'ИСТОРИЯ ТВОЕЙ РУКИ',
  ),
  'palm.heart_title': L10nTriple('KALP', 'HEART', 'СЕРДЦЕ'),
  'palm.head_title': L10nTriple('ZİHİN', 'MIND', 'УМ'),
  'palm.life_title': L10nTriple('YAŞAM', 'LIFE', 'ЖИЗНЬ'),
  'palm.fate_title': L10nTriple('YÖN', 'PATH', 'ПУТЬ'),
  'palm.symbols_title': L10nTriple(
    'ÖNE ÇIKAN İŞARET',
    'A MARK THAT STANDS OUT',
    'ВЫДЕЛЯЮЩИЙСЯ ЗНАК',
  ),
  'palm.takeaway_title': L10nTriple(
    'EN ÖNEMLİ İŞARET',
    'THE CLEAREST SIGN',
    'ГЛАВНЫЙ ЗНАК',
  ),
  'palm.themes_title': L10nTriple(
    'GÜÇLÜ TEMALAR',
    'STRONG THEMES',
    'СИЛЬНЫЕ ТЕМЫ',
  ),
  'palm.image_unsupported': L10nTriple(
    'Bu fotoğraf formatı desteklenmiyor. JPEG veya PNG deneyin.',
    'This photo format is not supported. Try JPEG or PNG.',
    'Этот формат фото не поддерживается. Попробуйте JPEG или PNG.',
  ),
  'palm.image_normalize_failed': L10nTriple(
    'Fotoğraf hazırlanamadı. Başka bir kare deneyelim.',
    'The photo could not be prepared. Try another frame.',
    'Не удалось подготовить фото. Попробуйте другой кадр.',
  ),
  'palm.choose_another_photo': L10nTriple(
    'Başka fotoğraf seç',
    'Choose another photo',
    'Выбрать другое фото',
  ),
  'palm.retry_analysis': L10nTriple(
    'Aynı fotoğrafla dene',
    'Retry with same photo',
    'Повторить с тем же фото',
  ),
  'palm.disclaimer': L10nTriple(
    'Sembolik bir yorumdur. Tıbbi veya bilimsel teşhis değildir.',
    'A symbolic reading — not a medical or scientific diagnosis.',
    'Символическое толкование. Не медицинский и не научный диагноз.',
  ),
  'palm.source_note': L10nTriple(
    'Avuç fotoğrafına bakıldı; yorum yansıtıcı ve semboliktir — teşhis veya kehanet değil.',
    'Your palm photo was read; the reflection is symbolic — not diagnosis or prediction.',
    'Фото ладони просмотрено; толкование символическое — не диагноз и не предсказание.',
  ),
};
