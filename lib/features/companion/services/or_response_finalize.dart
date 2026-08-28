/// Canonical OR body finalize — one polish site for live + local.
library;

import '../../../core/personality/or_response_depth.dart';
import '../../ai/services/conversation_response_guard.dart';
import 'or_selected_context.dart';

abstract final class OrResponseFinalize {
  OrResponseFinalize._();

  /// Live bridge + local responder share this entry. No other formatter.
  static String apply(
    String raw, {
    required String userMessage,
    bool hasMemoryEvidence = false,
    bool allowTrailingQuestion = true,
    OrResponseDepth? depth,
    bool spoken = false,
    String? priorAssistant,
  }) {
    return ConversationResponseGuard.polish(
      stripInternalLeak(raw),
      userMessage: userMessage,
      hasMemoryEvidence: hasMemoryEvidence,
      allowTrailingQuestion: allowTrailingQuestion,
      depth: depth,
      spoken: spoken,
      priorAssistant: priorAssistant,
    );
  }

  /// Last-line safety before [AIMessage.content] — never invents text.
  static String forMessage(String body) => stripInternalLeak(body).trim();

  /// Drops transport/source/debug lines that must never reach the bubble.
  static String stripInternalLeak(String text) {
    var out = text.trim();
    if (out.isEmpty) return out;
    final lines = out.split('\n');
    final kept = <String>[
      for (final line in lines)
        if (!_isLeakLine(line.trim())) line,
    ];
    out = kept.join('\n').trim();
    out = out.replaceAll(RegExp(r'\[OR\][^\n]*'), '');
    out = out.replaceAll(RegExp(r'<<[^>\n]{0,80}>>'), '');
    out = _stripToken(out, 'fromAi');
    out = _stripToken(out, 'metaLocal');
    out = _stripToken(out, 'metaLive');
    out = out.replaceAll(
      RegExp(r'source\s*[:=]\s*(ai|local)', caseSensitive: false),
      '',
    );
    out = OrContextLeakStrip.apply(out);
    return out.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  static String _stripToken(String text, String token) =>
      text.replaceAll(RegExp(RegExp.escape(token), caseSensitive: false), '');

  static bool _isLeakLine(String line) {
    if (line.isEmpty) return false;
    final lower = line.toLowerCase();
    if (lower.startsWith('[or]')) return true;
    if (lower.startsWith('[test]')) return true;
    if (lower.startsWith('debug:')) return true;
    if (lower.startsWith('stage=')) return true;
    if (lower.contains('yerel yansıma') && lower.contains('yapay zek')) {
      return true;
    }
    if (lower.contains('local reflection') && lower.contains('live model')) {
      return true;
    }
    if (lower.contains('canlı yapay zekâ bağlı değil')) return true;
    if (lower.contains('a live model is not connected')) return true;
    return false;
  }
}
