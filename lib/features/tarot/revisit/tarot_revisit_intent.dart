/// Pending revisit intent for the next tarot reading.
library;

import 'tarot_revisit_mode.dart';

class TarotRevisitIntent {
  const TarotRevisitIntent({
    required this.priorReadingId,
    required this.mode,
    required this.priorExcerpt,
  });

  final String priorReadingId;
  final TarotRevisitMode mode;
  final String priorExcerpt;
}
