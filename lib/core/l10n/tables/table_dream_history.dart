/// Dream Phase 4A recurring-thread copy — descriptive counts, no meaning.
library;

import '../l10n_triple.dart';

const kL10nDreamHistory = <String, L10nTriple>{
  'dream.history.title.recurring': L10nTriple(
    'Tekrar eden iz',
    'Recurring thread',
    'Повторяющаяся нить',
  ),
  'dream.history.title.seen': L10nTriple(
    'Tanıdık bir iz',
    'A familiar thread',
    'Знакомая нить',
  ),
  'dream.history.line.recurring': L10nTriple(
    '{label}: bu rüya dahil son rüyalarından {total} tanesinde var; en son {date}.',
    '{label}: in {total} of your recent dreams, this one included; last seen {date}.',
    '{label}: среди недавних снов таких {total}, включая этот; в последний раз — {date}.',
  ),
  'dream.history.line.seen': L10nTriple(
    '{label}: daha önce bir rüyanda da vardı ({date}).',
    '{label}: was in one earlier dream too ({date}).',
    '{label}: это уже было в одном прошлом сне ({date}).',
  ),
};
