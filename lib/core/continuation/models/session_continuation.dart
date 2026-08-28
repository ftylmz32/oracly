/// One contextual next step after a feature session — never a menu.
library;

enum SessionContinuationSource {
  coffee,
  tarot,
  dream,
  palm,
  starMap,
  astrology,
  soulMate,
}

enum SessionContinuationTarget {
  tarot,
  discoveryJournal,
  companion,
}

class SessionContinuation {
  const SessionContinuation({
    required this.target,
    required this.line,
    this.theme,
  });

  final SessionContinuationTarget target;
  final String line;
  final String? theme;
}
