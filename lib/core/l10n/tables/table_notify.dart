/// Daily return invitations — TR / EN / RU. Never private content.
library;

import '../l10n_triple.dart';

const kL10nNotify = <String, L10nTriple>{
  'notif.title': L10nTriple('ORACLY', 'ORACLY', 'ORACLY'),
  'notif.daily': L10nTriple(
    'Bugünün mesajı hazır.',
    "Today's message is ready.",
    'Послание дня готово.',
  ),
  'notif.discovery': L10nTriple(
    'Son keşiflerinde bir iz yeniden karşına çıkıyor.',
    'A mark from recent discoveries is meeting you again.',
    'След из недавних открытий снова встречается тебе.',
  ),
  'notif.discovery_theme': L10nTriple(
    'Son günlerde {theme} teması birkaç kez karşına çıktı.',
    'The theme of {theme} has appeared a few times lately.',
    'В последнее время тема {theme} встречалась несколько раз.',
  ),
  'notif.companion': L10nTriple(
    'OR ile konuşmaya devam edebilirsin.',
    'You can continue talking with OR.',
    'Можно продолжить разговор с OR.',
  ),
  'notif.permission': L10nTriple(
    'Bugünün mesajını ve keşiflerini hatırlatmamı ister misin? Gizlilik: Bildirim içeriği yalnızca cihazında görüntülenir. Detaylar Gizlilik ekranında. İstediğin an kapatabilirsin.',
    'Do you want me to remind you of today’s message and discoveries? You can turn it off anytime.',
    'Хочешь, чтобы я напоминал(а) тебе о сообщении и открытиях дня? Ты можешь отключить это в любой момент.',
  ),
  'notif.permission_denied_body': L10nTriple(
    'Bunu hatırlatabilmem için bildirim izni gerekiyor.',
    'I need notification permission to remind you.',
    'Мне нужен доступ к уведомлениям, чтобы напоминать тебе.',
  ),
  'notif.permission_permanent_body': L10nTriple(
    'Bildirim izni kalıcı olarak kapalı. Ayarlardan açabilirsin.',
    'Notification permission is permanently turned off. You can enable it in Settings.',
    'Уведомления навсегда отключены. Включи в Настройках.',
  ),
  'notif.permission_settings_label': L10nTriple(
    'Ayarlara git',
    'Go to Settings',
    'Перейти в настройки',
  ),
  'notif.permission_yes': L10nTriple('İzin Ver', 'Allow', 'Разрешить'),
  'notif.permission_later': L10nTriple('Şimdi değil', 'Not now', 'Не сейчас'),
};
