/// Seeded fortune-reader openings — coherent, not random garnish.
library;

import '../l10n/l10n.dart';

abstract final class FortuneReaderOpenings {
  FortuneReaderOpenings._();

  static String cup(int seed) => OraclyL10n.t('fortune.open.cup.${seed % 5}');

  static String palm(int seed) => OraclyL10n.t('fortune.open.palm.${seed % 5}');
}
