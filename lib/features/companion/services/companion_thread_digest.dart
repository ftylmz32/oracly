/// Compact earlier-thread meaning — never a transcript dump or invented memory.
library;

import '../../ai/production/models/conversation_turn.dart';
import '../data/companion_intent.dart';
import 'companion_thread_topics.dart';

/// Local compaction for turns older than the live model window.
abstract final class CompanionThreadDigest {
  CompanionThreadDigest._();

  static const maxChars = 220;
  static const maxAnchors = 4;

  /// Builds a short earlier-chat hint from [all] excluding the newest [keepRecent].
  static String? fromOlder(
    List<ConversationTurn> all, {
    int keepRecent = ConversationTurn.maxWindow,
  }) {
    if (all.length <= keepRecent) return null;
    final older = all.sublist(0, all.length - keepRecent);
    final users = [
      for (final t in older)
        if (t.isUser) t.text.trim(),
    ].where((t) => t.isNotEmpty).toList();
    if (users.isEmpty) return null;

    String? topic;
    final anchors = <String>[];
    for (final u in users) {
      if (CompanionIntent.isGreeting(u)) continue;
      final t = CompanionThreadTopics.of(u);
      if (t != null && !CompanionThreadTopics.isVague(t)) topic = t;
      if (_isAnchor(u)) {
        final clip = _clip(u, 56);
        if (!anchors.contains(clip)) anchors.add(clip);
      }
    }
    while (anchors.length > maxAnchors) {
      anchors.removeAt(0);
    }
    if (topic == null && anchors.isEmpty) return null;

    final topicBit = topic == null ? null : 'held topic=$topic.';
    final anchorBit =
        anchors.isEmpty ? null : 'user traces: ${anchors.join('; ')}.';
    final bits = <String>[
      'Earlier in this chat (compact, not a transcript):',
      ?topicBit,
      ?anchorBit,
      'Refer naturally if relevant. Invent nothing beyond these traces. '
          'Do not dump this block into the reply.',
    ];
    return _fit(bits.join(' '), maxChars);
  }

  static bool _isAnchor(String text) {
    final t = text.trim();
    if (t.length < 14 || t.length > 140) return false;
    if (CompanionIntent.isGreeting(t)) return false;
    if (CompanionIntent.isShortFollowUp(t)) return false;
    if (CompanionThreadTopics.isTimeSpan(t)) return true;
    return CompanionThreadTopics.of(t) != null || t.length <= 96;
  }

  static String _clip(String text, int max) {
    final t = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.length <= max) return t;
    final cut = t.substring(0, max);
    final space = cut.lastIndexOf(' ');
    final kept = space > max ~/ 2 ? cut.substring(0, space) : cut;
    return '$kept…';
  }

  static String _fit(String body, int max) {
    if (body.length <= max) return body;
    final cut = body.substring(0, max);
    final space = cut.lastIndexOf(' ');
    return space > max ~/ 2 ? cut.substring(0, space) : cut;
  }
}
