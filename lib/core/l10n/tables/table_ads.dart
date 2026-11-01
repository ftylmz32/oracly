/// Ad consent / privacy options — TR / EN / RU. Shown only when the ads
/// rollout is on AND UMP requires a privacy-options entry point.
library;

import '../l10n_triple.dart';

const kL10nAds = <String, L10nTriple>{
  'ads.privacy_options.title': L10nTriple(
    'Reklam gizlilik seçenekleri',
    'Ad privacy options',
    'Настройки конфиденциальности рекламы',
  ),
  'ads.privacy_options.subtitle': L10nTriple(
    'Reklam iznini gözden geçir veya değiştir.',
    'Review or change your ad consent.',
    'Просмотреть или изменить согласие на рекламу.',
  ),
  'ads.privacy_options.failed': L10nTriple(
    'Seçenekler şu an açılamadı. Biraz sonra yeniden dene.',
    'The options could not open right now. Try again in a moment.',
    'Сейчас не удалось открыть настройки. Попробуй чуть позже.',
  ),
};
