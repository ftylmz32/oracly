/// Transparency, session end, AI source, Auth already in resilience.
library;

import '../l10n_triple.dart';

const kL10nTrust = <String, L10nTriple>{
  'trust.footnote': L10nTriple(
    'Bu, sembolik bir yorumdur.',
    'This is a symbolic reading.',
    'Это символическое толкование.',
  ),
  'trust.brief': L10nTriple(
    'Bu, sembolik bir yorumdur.',
    'This is a symbolic reading.',
    'Это символическое толкование.',
  ),
  'trust.conversation': L10nTriple(
    'OR yanıtları rehberlik içindir; kararların senin.',
    'OR replies are for guidance; the choices are yours.',
    'Ответы OR для опоры; решения твои.',
  ),
  'trust.journal_privacy': L10nTriple(
    'Kişisel notların sana aittir — istediğin zaman düzenleyebilir veya silebilirsin.',
    'Personal notes belong to you — edit or delete them anytime.',
    'Личные заметки принадлежат тебе — правь или удаляй когда захочешь.',
  ),
  'trust.journal_empty': L10nTriple(
    'Bu okumaya kısa bir not ekleyebilirsin — sadece sana ait, istediğin zaman düzenleyebilir veya silebilirsin.',
    'You can add a short note to this reading — yours alone, edit or delete anytime.',
    'Можно добавить короткую заметку к этому чтению — только твоя; правь или удаляй когда захочешь.',
  ),
  'trust.journey': L10nTriple(
    'Sessiz bir arşiv — yalnızca senin cihazında, senin ritminle.',
    'A quiet archive — only on your device, in your rhythm.',
    'Тихий архив — только на твоём устройстве, в твоём ритме.',
  ),
  'trust.insight': L10nTriple(
    'Bunlar kehanet değil — sadece kendi ritminin yansımaları.',
    'These are not predictions — only reflections of your own rhythm.',
    'Это не предсказания — лишь отражения твоего ритма.',
  ),
  'trust.privacy_intro': L10nTriple(
    'Keşiflerin kişiselleştirme için kullanılır. Dilediğin an silebilirsin.',
    'Your discoveries are used to personalize. You can delete them anytime.',
    'Открытия используются для персонализации. Их можно удалить в любой момент.',
  ),
  'trust.about_boundary': L10nTriple(
    'OR, yansıtma ve içgörü için tasarlandı — geleceği bildirmek için değil.',
    'OR was designed for reflection and insight — not to announce the future.',
    'OR создан для размышления и понимания — не чтобы объявлять будущее.',
  ),
  'trust.delete_title': L10nTriple('Bu yansımayı sil?', 'Delete this reflection?', 'Удалить это отражение?'),
  'trust.delete_body': L10nTriple(
    'Okuma ve kişisel notun kalıcı olarak silinir. Geri alınamaz.',
    'The reading and personal note are deleted permanently. This cannot be undone.',
    'Чтение и личная заметка удаляются навсегда. Это нельзя отменить.',
  ),
  'trust.delete_confirm': L10nTriple('Sil', 'Delete', 'Удалить'),
  'trust.delete_cancel': L10nTriple('Vazgeç', 'Dismiss', 'Отменить'),
  'trust.memory_title': L10nTriple('Bu hafızayı sil?', 'Delete this memory?', 'Удалить эту память?'),
  'trust.memory_body': L10nTriple(
    'OR bu bilgiyi unutur. Geri alınamaz.',
    'OR will forget this. This cannot be undone.',
    'OR забудет это. Это нельзя отменить.',
  ),
  'trust.journal_cleared': L10nTriple('Tarot günlüğü temizlendi.', 'The tarot journal was cleared.', 'Дневник Таро очищен.'),
  'trust.memory_cleared': L10nTriple('Hafıza temizlendi.', 'Memory was cleared.', 'Память очищена.'),
  'trust.chat_cleared': L10nTriple('Sohbet geçmişi temizlendi.', 'Conversation history was cleared.', 'История разговоров очищена.'),
  'trust.all_reset': L10nTriple('Tüm veriler sıfırlandı.', 'All data was reset.', 'Все данные сброшены.'),
  'trust.analytics_title': L10nTriple(
    'Anonim kullanım ölçümü',
    'Anonymous usage measurement',
    'Анонимный замер использования',
  ),
  'trust.analytics_subtitle': L10nTriple(
    'Hangi özelliklerin kullanıldığını ve güvenli çökme özetlerini anlamak için — mesaj, okuma veya görsel gönderilmez.',
    'Helps us see which features are used and safe crash summaries — never messages, readings, or images.',
    'Показывает, какие функции используют и безопасные сводки сбоев — без сообщений, чтений и изображений.',
  ),
  'session.title': L10nTriple('Son Yansıma', 'Lasting reflection', 'Последнее отражение'),
  'session.footer': L10nTriple(
    'Bu an seninle kalabilir. Acele etme — huzurla ayrılabilirsin.',
    'This moment can stay with you. There is no hurry — you may leave in peace.',
    'Этот миг может остаться с тобой. Не спеши — можно уйти в покое.',
  ),
  'session.saved': L10nTriple(
    'Bu yansıma günlüğünde — istediğin zaman geri bakabilirsin.',
    'This reflection is in your journal — you can look back anytime.',
    'Это отражение в твоём дневнике — можно вернуться в любой момент.',
  ),
  'session.closing': L10nTriple(
    'Bu birkaç dakika kendi iç sesine alan açtıysa, yeterli. Ne hissediyorsan, o değerlidir.',
    'If these few minutes made room for your inner voice, that is enough. Whatever you feel is of value.',
    'Если эти минуты дали место внутреннему голосу — достаточно. Что чувствуешь, то ценно.',
  ),
  'session.affirm': L10nTriple(
    'Bir an durup ne hissettiğine bakmak, bazen en net cevaptır.',
    'Pausing to notice what you feel is sometimes the clearest answer.',
    'Остановиться и заметить чувство — иногда самый ясный ответ.',
  ),
  'session.note_dismiss': L10nTriple('Şimdilik geç', 'Skip for now', 'Пока пропустить'),
  'session.note_hint': L10nTriple(
    'Örn. "Bugün bu doğru hissettirdi." — istediğin zaman geri dönebilirsin.',
    'E.g. "This felt true today." — you can return anytime.',
    'Напр. «Сегодня это отозвалось правдой». — можно вернуться в любой момент.',
  ),
};
