/// Shared format chrome — today / yesterday / day+time glue.
library;

import '../l10n_triple.dart';

const kL10nFormat = <String, L10nTriple>{
  'format.today': L10nTriple('Bugün', 'Today', 'Сегодня'),
  'format.yesterday': L10nTriple('Dün', 'Yesterday', 'Вчера'),
  'format.day_time': L10nTriple('{day}, {time}', '{day}, {time}', '{day}, {time}'),
  'format.char_count': L10nTriple(
    '{count} karakter',
    '{count} characters',
    '{count} символов',
  ),
};
