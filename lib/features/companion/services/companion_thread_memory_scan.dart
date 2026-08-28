/// Scan helpers for companion thread memory.
library;

import '../../ai/production/models/conversation_turn.dart';
import '../data/companion_intent.dart';
import 'companion_thread_topics.dart';

abstract final class CompanionThreadMemoryScan {
  CompanionThreadMemoryScan._();

  static List<ConversationTurn> span(List<ConversationTurn> turns) {
    final clean = [
      for (final turn in turns)
        if (turn.text.trim().isNotEmpty) turn,
    ];
    if (clean.length <= CompanionThreadTopics.scan) return clean;
    return clean.sublist(clean.length - CompanionThreadTopics.scan);
  }

  static String? last(List<ConversationTurn> turns, {required bool user}) {
    for (var i = turns.length - 1; i >= 0; i--) {
      if (turns[i].isUser != user) continue;
      return turns[i].text;
    }
    return null;
  }

  static String? heldTopic(List<ConversationTurn> turns) {
    String? vague;
    for (var i = turns.length - 1; i >= 0; i--) {
      if (!turns[i].isUser) continue;
      if (CompanionIntent.isGreeting(turns[i].text)) continue;
      final topic = CompanionThreadTopics.of(turns[i].text);
      if (topic == null) continue;
      if (!CompanionThreadTopics.isVague(topic)) return topic;
      vague ??= topic;
    }
    return vague;
  }

  static String? recap(List<ConversationTurn> turns, String current) {
    final users = [
      for (final turn in turns)
        if (turn.isUser) turn.text.trim(),
      current.trim(),
    ].where((text) => text.isNotEmpty).toList();
    if (users.isEmpty) return null;
    final slice = users.length <= 3 ? users : users.sublist(users.length - 3);
    final joined = slice.join(' → ');
    return joined.length <= 140 ? joined : joined.substring(0, 140);
  }

  static bool isResume(
    String current,
    String? previous,
    String? lastAssistant,
    bool interrupted,
  ) {
    if (interrupted || previous == null) return false;
    final now = CompanionThreadTopics.of(current);
    if (now == null || now != previous) return false;
    final last = (lastAssistant ?? '').toLowerCase();
    return last.contains('selam') ||
        last.contains('hey') ||
        last.contains('yer açık') ||
        last.contains('dinliyorum') ||
        last.contains('kaldığımız') ||
        last.contains('ipi duruyor');
  }

  static bool isAnswer(
    String current,
    String? lastAssistant,
    String? previous,
  ) {
    final q = current.trim();
    if (q.isEmpty || lastAssistant == null || q.length > 56) return false;
    if (CompanionIntent.isGreeting(q)) return false;
    if (CompanionIntent.isShortFollowUp(q) && previous != null) return true;
    if (CompanionThreadTopics.isTimeSpan(q)) return true;
    if (CompanionThreadTopics.isPin(q)) {
      final now = CompanionThreadTopics.of(q);
      if (previous == null ||
          CompanionThreadTopics.isVague(previous) ||
          previous == now) {
        return true;
      }
    }
    if (!lastAssistant.contains('?')) return false;
    if (CompanionThreadTopics.isElaboration(q)) {
      // Fear-of-change on a held thread needs fearClarify — not "answered".
      if (_isFearOfChange(q)) return false;
      if (q.length > 56) return false;
      return previous != null;
    }
    final now = CompanionThreadTopics.of(q);
    if (now != null &&
        previous != null &&
        now != previous &&
        !CompanionThreadTopics.isVague(previous)) {
      return false;
    }
    if (previous == null) return false;
    if (now != null) return true;
    return q.length <= 28;
  }

  static bool _isFearOfChange(String text) {
    final lower = text.toLowerCase();
    if (!lower.contains('kork') &&
        !lower.contains('afraid') &&
        !lower.contains('страх')) {
      return false;
    }
    return lower.contains('değiş') ||
        lower.contains('chang') ||
        lower.contains('перемен');
  }
}
