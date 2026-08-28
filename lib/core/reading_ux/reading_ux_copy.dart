/// Long-form reading labels.
library;

import '../l10n/l10n.dart';

abstract final class ReadingUxCopy {
  ReadingUxCopy._();

  static String get continueReading => OraclyL10n.t('read.ux.continue');
}
