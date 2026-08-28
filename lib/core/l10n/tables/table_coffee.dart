/// Coffee fortune chrome — TR / EN / RU.
library;

import '../l10n_triple.dart';

const kL10nCoffee = <String, L10nTriple>{
  'coffee.screen_title': L10nTriple(
    'KAHVE',
    'COFFEE',
    'КОФЕ',
  ),
  'coffee.landing_line': L10nTriple(
    'Masa hazır. Fincan hâlâ sıcak.',
    'The table is ready. The cup is still warm.',
    'Стол готов. Чашка ещё теплая.',
  ),
  'coffee.hub_lead': L10nTriple(
    'Fincanındaki izleri birlikte okuyalım.',
    'Let us read the marks in your cup together.',
    'Давай вместе прочитаем следы в твоей чашке.',
  ),
  'coffee.photo_cta': L10nTriple(
    'FOTOĞRAF ÇEK',
    'TAKE PHOTO',
    'СФОТОГРАФИРОВАТЬ',
  ),
  'coffee.ritual_tease': L10nTriple(
    'Fincanında ne var, bakalım...',
    'Let us see what is in your cup...',
    'Посмотрим, что в твоей чашке...',
  ),
  'coffee.ritual_title': L10nTriple(
    'Fincanı aç',
    'Open the cup',
    'Открой чашку',
  ),
  'coffee.ritual_body': L10nTriple(
    'Telvenin izi görünür olsun; acele etme.',
    'Let the grounds show. There is no hurry.',
    'Пусть видны следы гущи. Спешить не нужно.',
  ),
  'coffee.landing_steps': L10nTriple(
    'Fincanı çek · Fotoğrafı yükle · Sembollerini keşfet',
    'Photograph the cup · Upload · Discover the symbols',
    'Сфотографируй чашку · Загрузи · Открой символы',
  ),
  'coffee.step.capture': L10nTriple(
    'Fincanı çek',
    'Photograph the cup',
    'Сфотографируй чашку',
  ),
  'coffee.step.upload': L10nTriple(
    'Fotoğrafı yükle',
    'Upload the photo',
    'Загрузи фото',
  ),
  'coffee.step.discover': L10nTriple(
    'Sembollerini keşfet',
    'Discover the symbols',
    'Открой символы',
  ),
  'coffee.preview_badge': L10nTriple('Önizleme', 'Preview', 'Предпросмотр'),
  'coffee.capability_note': L10nTriple(
    'Fincan yorumu için OR bağlantısı gerekir.',
    'A cup reading needs an OR connection.',
    'Для чтения чашки нужно соединение с OR.',
  ),
  'coffee.landing_steps_unavailable': L10nTriple(
    'Kayıtlı fincanları açabilirsin',
    'You can open saved cups',
    'Можно открыть сохранённые чашки',
  ),
  'coffee.open_cup': L10nTriple(
    'Fincanı aç',
    'Open the cup',
    'Открой чашку',
  ),
  'coffee.interpret_cta': L10nTriple(
    'FALIMI YORUMLA',
    'READ MY CUP',
    'ПРОЧИТАЙ МОЮ ЧАШКУ',
  ),
  'coffee.interpret_unavailable': L10nTriple(
    'Yorum yok',
    'No reading',
    'Нет толкования',
  ),
  'coffee.analyze_cta': L10nTriple(
    'FALIMI YORUMLA',
    'READ MY CUP',
    'ПРОЧИТАЙ МОЮ ЧАШКУ',
  ),
  'coffee.history_link': L10nTriple(
    'Geçmiş Fincanlar ›',
    'Past cups ›',
    'Прошлые чашки ›',
  ),
  'coffee.history_title': L10nTriple(
    'Geçmiş Fincanlar',
    'Past cups',
    'Прошлые чашки',
  ),
  'coffee.empty_history': L10nTriple(
    'İlk fincanın burada yerini bulacak.',
    'Your first cup will find its place here.',
    'Твоя первая чашка найдёт здесь своё место.',
  ),
  'coffee.add_photo_title': L10nTriple(
    'Fotoğraf seç',
    'Choose a photo',
    'Выбери фото',
  ),
  'coffee.preview_label': L10nTriple(
    'Fincanı incele',
    'Review the cup',
    'Рассмотри чашку',
  ),
  'coffee.capture_guide': L10nTriple(
    'Fincanın içini altın çemberin içine al.',
    'Settle the cup interior inside the gold circle.',
    'Помести внутренность чашки внутрь золотого круга.',
  ),
  'coffee.capture_tips': L10nTriple(
    'İç yüzey · Ortada · Yumuşak ışık · Sabit el',
    'Interior · Centered · Soft light · Steady hand',
    'Внутри · По центру · Мягкий свет · Без дрожи',
  ),
  'coffee.use_photo': L10nTriple(
    'Bu fotoğrafı kullan',
    'Use this photo',
    'Использовать это фото',
  ),
  'coffee.preview_cta_hint': L10nTriple(
    'Fincanın içi net görünsün.',
    'Keep the inside of the cup clear.',
    'Внутренняя часть чашки должна быть чёткой.',
  ),
  'coffee.add_photo_hint': L10nTriple(
    'Fincanın içini net, iyi ışıkta ve yakından çek. Telvesi görünsün.',
    'Photograph the inside closely, in good light. The grounds should be visible.',
    'Сними внутренность крупно, при хорошем свете. Гуща должна быть видна.',
  ),
  'coffee.camera': L10nTriple('Fincanı çek', 'Photograph the cup', 'Сфотографируй чашку'),
  'coffee.gallery': L10nTriple(
    'GALERİDEN SEÇ',
    'CHOOSE FROM GALLERY',
    'ВЫБРАТЬ ИЗ ГАЛЕРЕИ',
  ),
  'coffee.retake': L10nTriple('Yeniden çek', 'Retake', 'Снять заново'),
  'coffee.remove': L10nTriple('Kaldır', 'Remove', 'Убрать'),
  'coffee.image_missing': L10nTriple(
    'Fotoğraf bulunamadı. Yeni bir kare seç.',
    'Photo not found. Choose another frame.',
    'Фото не найдено. Выбери другой кадр.',
  ),
  'coffee.image_unreadable': L10nTriple(
    'Bu dosya bir fotoğraf olarak açılamadı. Başka bir kare dene.',
    'This file could not be opened as a photo. Try another frame.',
    'Этот файл не открылся как фото. Попробуй другой кадр.',
  ),
  'coffee.image_unclear': L10nTriple(
    'Kahve fincanının içi daha net görünecek şekilde yeni bir fotoğraf çek.',
    'Take a new photo so the inside of the coffee cup is clearer.',
    'Сделай новое фото, чтобы внутренность чашки была яснее.',
  ),
  'coffee.image_too_large': L10nTriple(
    'Fotoğraf çok ağır. Daha küçük veya daha sade bir kare seç.',
    'The photo is too heavy. Choose a smaller or simpler frame.',
    'Фото слишком тяжёлое. Выбери меньший или проще кадр.',
  ),
  'coffee.image_required': L10nTriple(
    'Önce bir fincan fotoğrafı ekle.',
    'Add a cup photo first.',
    'Сначала добавь фото чашки.',
  ),
  'coffee.quality.brighten': L10nTriple(
    'Fincanın içini biraz daha aydınlık çek.',
    'Photograph the inside of the cup with a little more light.',
    'Сними внутренность чашки чуть светлее.',
  ),
  'coffee.quality.frame': L10nTriple(
    'Fincanın içi kadrajda, ortada ve net görünsün.',
    'Keep the cup interior visible, centered, and clear.',
    'Пусть внутренность чашки будет видна, по центру и чётко.',
  ),
  'coffee.quality.blur': L10nTriple(
    'Fincanın içi daha net görünsün.',
    'Keep the inside of the cup a little sharper.',
    'Пусть внутренность чашки будет чуть чётче.',
  ),
  'coffee.camera_unavailable': L10nTriple(
    'Kamera bu cihazda açılamadı. Galeriden seç.',
    'The camera could not open on this device. Choose from the gallery.',
    'Камера на этом устройстве не открылась. Выбери из галереи.',
  ),
  'coffee.camera_permission_rationale': L10nTriple(
    'Fincanını fotoğraflamak için kameraya ihtiyacımız var. Gizlilik: Fotoğraf sadece bu işlem için kullanılır. Detaylar Gizlilik ekranında.',
    'We need the camera to photograph your cup. Privacy: the photo is used only for this reading. Details in the Privacy screen.',
    'Нужна камера, чтобы сфотографировать вашу чашку. Конфиденциальность: фото используется только для чтения. Детали — в экране «Приватность».',
  ),
  'coffee.camera_permission_denied': L10nTriple(
    'Kamera izni reddedildi. Şimdi değilse galeriden seçebilirsin.',
    'Camera permission was denied. If not now, choose from the gallery.',
    'Доступ к камере отклонён. Если не сейчас — выбери из галереи.',
  ),
  'coffee.camera_permission_permanent': L10nTriple(
    'Kamera izni kalıcı olarak kapalı. Ayarlardan açabilirsin.',
    'Camera permission is permanently turned off. You can enable it in Settings.',
    'Доступ к камере навсегда отключён. Включи в Настройках.',
  ),
  'coffee.gallery_unavailable': L10nTriple(
    'Galeri bu cihazda açılamadı.',
    'The gallery could not open on this device.',
    'Галерея на этом устройстве не открылась.',
  ),
  'coffee.analyzing': L10nTriple(
    'Fincana biraz daha yakından bakıyorum...',
    'Looking a little closer at the cup...',
    'Смотрю на чашку чуть ближе...',
  ),
  'coffee.analyzing_subtitle': L10nTriple(
    'Gerçek fincan fotoğrafına bakıyorum — acele yok.',
    'Looking at your real cup photo — no hurry.',
    'Смотрю на реальное фото чашки — без спешки.',
  ),
  'coffee.analysis_unavailable': L10nTriple(
    'Kahve falı şu an hazırlanamadı. Biraz sonra tekrar deneyebilirsin.',
    'Coffee reading could not be prepared. You can try again in a moment.',
    'Кофейное чтение сейчас не готово. Можно попробовать через мгновение.',
  ),
  'coffee.analysis_failed': L10nTriple(
    'Fincanı şu an okuyamadım. Bir daha deneyelim.',
    'I could not read the cup right now. Let us try again.',
    'Сейчас не удалось прочитать чашку. Давай попробуем ещё раз.',
  ),
  'coffee.retry': L10nTriple('TEKRAR DENE', 'TRY AGAIN', 'ЕЩЁ РАЗ'),
  'coffee.visual_title': L10nTriple(
    'Görülen izler',
    'Visible traces',
    'Видимые следы',
  ),
  'coffee.overall_title': L10nTriple(
    'FİNCANIN SANA ANLATTIĞI',
    'WHAT YOUR CUP TOLD YOU',
    'ЧТО РАССКАЗАЛА ЧАШКА',
  ),
  'coffee.overall_subtitle': L10nTriple(
    'Küçük detaylar, büyük hikâyeler...',
    'Small traces, larger stories...',
    'Малые следы — большие истории...',
  ),
  'coffee.symbols_title': L10nTriple(
    'ÖNE ÇIKAN SEMBOLLER',
    'EMERGING SYMBOLS',
    'ЯРКИЕ СИМВОЛЫ',
  ),
  'coffee.love_title': L10nTriple('AŞK', 'LOVE', 'ЛЮБОВЬ'),
  'coffee.career_title': L10nTriple('İŞ', 'WORK', 'РАБОТА'),
  'coffee.money_title': L10nTriple(
    'Maddi Konular',
    'Material matters',
    'Материальные темы',
  ),
  'coffee.news_title': L10nTriple('HABER', 'NEWS', 'ВЕСТЬ'),
  'coffee.path_title': L10nTriple('YOL', 'PATH', 'ПУТЬ'),
  'coffee.caution_title': L10nTriple('DİKKAT', 'ATTENTION', 'ВНИМАНИЕ'),
  'coffee.disclaimer': L10nTriple(
    'Bu, sembolik bir yorumdur.',
    'This is a symbolic reading.',
    'Это символическое толкование.',
  ),
  'coffee.source_note': L10nTriple(
    'Fincan fotoğrafına bakıldı; yorum yansıtıcı ve semboliktir — kehanet değil.',
    'Your cup photo was read; the reflection is symbolic — not a prediction.',
    'Фото чашки просмотрено; толкование символическое — не предсказание.',
  ),
  'coffee.ask_or': L10nTriple("OR'a Sor", 'Ask OR', 'Спросить OR'),
  'coffee.new_cup': L10nTriple('Yeni fincan', 'New cup', 'Новая чашка'),
};
