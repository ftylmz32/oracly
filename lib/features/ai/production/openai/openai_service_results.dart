/// Map proxy data maps onto typed models — parse only, never polish.
library;

import '../ai_failure.dart';
import '../ai_outcome.dart';
import '../models/chat_ai_reply.dart';
import '../models/coffee_ai_analysis.dart';
import '../models/dream_ai_analysis.dart';
import '../models/palm_ai_analysis.dart';
import '../models/soul_mate_ai_portrait.dart';
import 'coffee_vision_parser.dart';
import 'dream_analysis_parser.dart';
import 'palm_vision_parser.dart';

abstract final class OpenAiServiceResults {
  OpenAiServiceResults._();

  /// Transport parse for chat/oracle. Feature polish is upstream
  /// ([OrResponseFinalize] / [ConversationResponseGuard]) — not here.
  static AiOutcome<ChatAiReply> chat(
    AiOutcome<Map<String, dynamic>> outcome,
    String model,
  ) {
    return outcome.when(
      success: (data) {
        final text = data['text'];
        if (text is! String || text.trim().isEmpty) {
          return AiOutcome.failure(AiFailure.invalidResponse());
        }
        final raw = text.trim();
        if (_envelopeBroken(raw)) {
          return AiOutcome.failure(AiFailure.invalidResponse());
        }
        return AiOutcome.success(
          ChatAiReply(
            text: raw,
            modelId: model,
          ),
        );
      },
      error: AiOutcome.failure,
    );
  }

  static bool _envelopeBroken(String text) {
    if (RegExp(r'^[\s\.\,\!\?\-–—]+$').hasMatch(text)) return true;
    if (text.contains('```') || text.contains('{"') || text.contains('":')) {
      return true;
    }
    return RegExp(r'\{\{|\}\}|<<|>>').hasMatch(text);
  }

  static AiOutcome<DreamAiAnalysis> dream(
    AiOutcome<Map<String, dynamic>> outcome,
  ) {
    return outcome.when(
      success: (data) {
        final parsed = DreamAnalysisParser.fromMap(data);
        if (parsed == null) {
          return AiOutcome.failure(AiFailure.invalidResponse());
        }
        return AiOutcome.success(parsed);
      },
      error: AiOutcome.failure,
    );
  }

  static AiOutcome<SoulMateAiPortrait> soulMate(
    AiOutcome<Map<String, dynamic>> outcome,
  ) {
    return outcome.when(
      success: (data) {
        final raw = data['imageBase64'];
        if (raw is! String || raw.trim().isEmpty) {
          return AiOutcome.failure(AiFailure.invalidResponse());
        }
        final mime = data['mimeType'];
        final portrait = SoulMateAiPortrait.tryFromBase64(
          raw,
          mimeType: mime is String ? mime : null,
        );
        if (portrait == null) {
          return AiOutcome.failure(AiFailure.invalidResponse());
        }
        return AiOutcome.success(portrait);
      },
      error: AiOutcome.failure,
    );
  }

  static AiOutcome<PalmAiAnalysis> palm(
    AiOutcome<Map<String, dynamic>> outcome,
  ) {
    return outcome.when(
      success: (data) {
        final parsed = PalmVisionParser.fromMap(data);
        if (parsed == null) {
          return AiOutcome.failure(AiFailure.invalidResponse());
        }
        return AiOutcome.success(
          PalmAiAnalysis(
            overall: parsed['overall'] as String? ?? '',
            lifeLine: parsed['lifeLine'] as String? ?? '',
            headLine: parsed['headLine'] as String? ?? '',
            heartLine: parsed['heartLine'] as String? ?? '',
            fateLine: parsed['fateLine'] as String? ?? '',
            takeaway: parsed['takeaway'] as String? ?? '',
            symbols: _strings(parsed['symbols']),
            themes: _strings(parsed['themes']),
          ),
        );
      },
      error: AiOutcome.failure,
    );
  }

  static List<String> _strings(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }

  static AiOutcome<CoffeeAiAnalysis> coffee(
    AiOutcome<Map<String, dynamic>> outcome,
  ) {
    return outcome.when(
      success: (data) {
        final parsed = CoffeeVisionParser.fromMap(data);
        if (parsed == null) {
          return AiOutcome.failure(AiFailure.invalidResponse());
        }
        return AiOutcome.success(parsed);
      },
      error: AiOutcome.failure,
    );
  }
}
