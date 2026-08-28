/// Reveal queue helpers — already-drawn cards waiting to be shown.
library;

import 'reading_session.dart';

extension ReadingSessionDraw on ReadingSession {
  bool get hasQueuedReveal =>
      drawnCards.isNotEmpty &&
      currentPositionIndex < drawnCards.length - 1;
}
