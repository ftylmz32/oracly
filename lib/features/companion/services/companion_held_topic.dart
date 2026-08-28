/// Held-topic resolution for OR thread continuity.
library;

import 'companion_thread_topics.dart';

abstract final class CompanionHeldTopic {
  CompanionHeldTopic._();

  static String? resolve({
    required bool interrupted,
    required bool answering,
    required String? previous,
    required String? now,
  }) {
    if (interrupted) return previous;
    if (answering && previous != null && !CompanionThreadTopics.isVague(previous)) {
      return previous;
    }
    if (now != null && CompanionThreadTopics.isVague(now) && previous != null && !CompanionThreadTopics.isVague(previous)) {
      return previous;
    }
    return now ?? previous;
  }
}
