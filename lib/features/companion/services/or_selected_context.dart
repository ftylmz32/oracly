/// Selected OR context buckets — never a memory/database dump.
library;

import '../../../core/honesty/or_response_grounding.dart';
import '../../ai/production/models/conversation_turn.dart';
import 'or_long_term_memory_boundaries.dart';

/// Separated layers. Only non-empty, relevant fields reach the model.
class OrSelectedContext {
  const OrSelectedContext({
    required this.currentMessage,
    this.recentMessages = const [],
    this.stableUserFacts,
    this.recentDiscovery,
    this.relevantMemory,
    this.featureSpecific,
    this.preferenceHint,
    this.threadGuidance,
    this.emotionalGuidance,
    this.humorGuidance,
    this.adaptiveGuidance,
  });

  final String currentMessage;
  final List<ConversationTurn> recentMessages;

  /// FACT — explicit user-given (e.g. name), only when relevant.
  final String? stableUserFacts;

  /// OBSERVATION — recurring discovery marks, relevance-gated.
  final String? recentDiscovery;

  /// FACT (saved note) or OBSERVATION line — never an archive dump.
  final String? relevantMemory;

  /// INTERPRETATION — feature/reading handoff (symbolic), never as FACT.
  final String? featureSpecific;

  /// PREFERENCE — tone/style when relevant; never a command.
  final String? preferenceHint;

  final String? threadGuidance;

  /// Affect cue for this turn — proportional, never a diagnosis script.
  final String? emotionalGuidance;

  /// Humor stance for this turn — welcome or serious; never a comedy set.
  final String? humorGuidance;

  /// Adaptive register — depth/tone follow the user; identity stays fixed.
  final String? adaptiveGuidance;

  static const hintLimit = 480;

  String toStyleHint({int limit = hintLimit}) {
    final longTerm = OrLongTermMemoryBoundaries.usesLongTerm(
          fact: stableUserFacts,
          observation: recentDiscovery,
          interpretation: featureSpecific,
          preference: preferenceHint,
        ) ||
        _ok(relevantMemory);
    final parts = <String>[
      OrResponseGrounding.styleHintRule,
      if (longTerm) OrLongTermMemoryBoundaries.promptTr,
      if (_ok(stableUserFacts)) stableUserFacts!.trim(),
      if (_ok(recentDiscovery)) recentDiscovery!.trim(),
      if (_ok(featureSpecific)) featureSpecific!.trim(),
      if (_ok(relevantMemory) && !_ok(recentDiscovery))
        relevantMemory!.trim(),
      if (_ok(preferenceHint)) preferenceHint!.trim(),
      if (_ok(emotionalGuidance)) emotionalGuidance!.trim(),
      if (_ok(humorGuidance)) humorGuidance!.trim(),
      if (_ok(adaptiveGuidance)) adaptiveGuidance!.trim(),
      if (_ok(threadGuidance)) threadGuidance!.trim(),
    ];
    var body = parts.join(' ').trim();
    body = OrContextLeakStrip.apply(body);
    if (body.length <= limit) return body;
    final cut = body.substring(0, limit);
    final space = cut.lastIndexOf(' ');
    return space > 280 ? cut.substring(0, space) : cut;
  }

  static bool _ok(String? s) => s != null && s.trim().isNotEmpty;
}

/// Removes internal context vocabulary from anything sent toward the model.
abstract final class OrContextLeakStrip {
  OrContextLeakStrip._();

  static final _leaks = RegExp(
    r'\b(styleHint|retrieval|embedding|embeddings|database|memory system|'
    r'record system|context selection|context engine|intelligence layer)\b|'
    r'veritaban[ıi]|haf[ıi]za yap[ıi]s[ıi]|haf[ıi]za sistemi',
    caseSensitive: false,
  );

  static String apply(String text) {
    var out = text.replaceAll(_leaks, '');
    out = out.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return out;
  }
}
