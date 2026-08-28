/// Traditional tendency — only when that line was actually seen.
library;

import '../../../core/l10n/l10n.dart';

abstract final class PalmLineLexicon {
  PalmLineLexicon._();

  static String heart(int seed) => OraclyL10n.t('palm.read.heart.${seed % 3}');

  static String head(int seed) => OraclyL10n.t('palm.read.head.${seed % 3}');

  static String life(int seed) => OraclyL10n.t('palm.read.life.${seed % 3}');

  static String fate(int seed) => OraclyL10n.t('palm.read.fate.${seed % 3}');
}
