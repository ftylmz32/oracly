/// Same-conversation continuity — remember what was said, never invent.
library;

import '../../ai/production/models/conversation_turn.dart';
import '../data/companion_correction.dart';
import '../data/companion_intent.dart';
import 'companion_thread_memory.dart';
import 'companion_thread_topics.dart';

/// Compact facts already given in this chat (not a transcript dump).
class ContinuityFacts {
  const ContinuityFacts({
    this.timeSpan,
    this.pinnedTopic,
    this.anchors = const [],
  });

  final String? timeSpan;
  final String? pinnedTopic;
  final List<String> anchors;

  bool get hasTimeSpan => timeSpan != null && timeSpan!.trim().isNotEmpty;

  /// Prompt fragment — no full message paste, no fabricated memory.
  String get promptHint {
    final bits = <String>[
      if (hasTimeSpan) 'Süre zaten söylendi ($timeSpan) — yeniden sorma.',
      if (pinnedTopic != null && pinnedTopic!.trim().isNotEmpty)
        'Konu tutucu: $pinnedTopic.',
      if (anchors.isNotEmpty)
        'Bu sohbette verilen izler: ${anchors.join('; ')}. '
            'Doğal gönderme yap; tüm cümleyi tekrarlama; icat etme.',
    ];
    return bits.join(' ');
  }
}

abstract final class CompanionConversationContinuity {
  CompanionConversationContinuity._();

  static const _anchorLimit = 3;
  static const _anchorChars = 72;

  static ContinuityFacts facts(
    List<ConversationTurn> turns,
    String current,
  ) {
    final users = [
      for (final t in turns)
        if (t.isUser) t.text.trim(),
      current.trim(),
    ].where((t) => t.isNotEmpty).toList();

    String? timeSpan;
    String? pinned;
    final anchors = <String>[];
    for (final u in users) {
      if (CompanionThreadTopics.isTimeSpan(u)) {
        timeSpan = _clip(u, 40);
      }
      final topic = CompanionThreadTopics.of(u);
      if (topic != null && !CompanionThreadTopics.isVague(topic)) {
        pinned = topic;
      }
      if (_isAnchor(u)) {
        final clip = _clip(u, _anchorChars);
        if (!anchors.contains(clip)) anchors.add(clip);
      }
    }
    while (anchors.length > _anchorLimit) {
      anchors.removeAt(0);
    }
    return ContinuityFacts(
      timeSpan: timeSpan,
      pinnedTopic: pinned,
      anchors: List.unmodifiable(anchors),
    );
  }

  /// Extra guidance for live styleHint + local thread.
  static String guidance({
    required CompanionThreadMemory thread,
    required ContinuityFacts facts,
    required String current,
  }) {
    final parts = <String>[
      if (facts.promptHint.isNotEmpty) facts.promptHint,
      if (thread.interrupted)
        'Kısa kesinti (selam). Konuyu sıfırlama; önceki ipi uydurarak özetleme.',
      if (thread.resuming)
        'Kesinti sonrası aynı konuya dönülüyor. Doğal bağla; baştan sorma.',
      if (thread.continuing || thread.answeringPrompt)
        'Aynı sohbet: önceki söylenenlere doğal gönderme yap. '
            'Verilmiş bilgiyi yeniden sorma. Önceki yanıtı olduğu gibi yapıştırma. '
            'Anı uydurma.',
      if (CompanionIntent.isShortFollowUp(current) &&
          (thread.hadPriorTopic || thread.continuing))
        'Kısa takip ("peki / neden / devam / ama..."). Sohbeti sıfırlama; '
            'önceki bağlama devam et. Genel selam veya yeni konu açma yok.',
      if (CompanionIntent.isCorrection(current))
        CompanionCorrection.styleHintTr,
    ];
    return parts.join(' ').trim();
  }

  static bool _isAnchor(String text) {
    final t = text.trim();
    if (t.length < 12 || t.length > 160) return false;
    if (CompanionIntent.isGreeting(t)) return false;
    if (CompanionThreadTopics.isTimeSpan(t)) return false;
    if (CompanionIntent.isKnowledge(t)) return false;
    return CompanionThreadTopics.of(t) != null ||
        t.length <= 96;
  }

  static String _clip(String text, int max) {
    final t = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.length <= max) return t;
    final cut = t.substring(0, max);
    final space = cut.lastIndexOf(' ');
    return '${space > max ~/ 2 ? cut.substring(0, space) : cut}…';
  }
}
