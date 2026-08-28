/// Non-tarot OR'a Sor — answer first, then optional calm close.
library;

import '../../../../core/copy/conversation_copy.dart';
import '../../services/conversation_response_guard.dart';
import '../../services/followup_question_resolve.dart';
import '../models/oracle_reading_context.dart';
import 'oracle_followup_slices.dart';

abstract final class OracleFollowupCopy {
  OracleFollowupCopy._();

  static String respond({
    required OracleReadingContext context,
    required String question,
    List<String> priorUser = const [],
  }) {
    final resolved = FollowupQuestionResolve.expand(
      current: question,
      priorUser: priorUser,
    );
    final q = resolved.toLowerCase();
    final source = context.sourceLabel.isEmpty
        ? context.readingTitle
        : context.sourceLabel;
    final summary = context.interpretationSummary.trim();
    final body = (context.fullInterpretation ?? '').trim().isNotEmpty
        ? context.fullInterpretation!.trim()
        : summary;

    if (context.kind == OracleReadingKind.dream) {
      return _dream(context, q, source, summary, body);
    }
    if (_matches(q, ['aşk', 'ilişki', 'sevgi', 'partner', 'karşı taraf'])) {
      final slice = OracleFollowupSlices.named(
            body,
            const ['Aşk', 'duygusal', 'ilişki', 'bağ'],
          ) ??
          summary;
      return _speak('Bu okumada aşk tarafında duran:\n$slice');
    }
    if (_matches(q, ['sembol', 'işaret', 'şekil', 'iz', 'temsil', 'dikkat çeken'])) {
      final hit = OracleFollowupSlices.symbolInQuestion(q, context.cardNames);
      final names = hit ??
          (context.cardNames.isEmpty
              ? 'görülen izler'
              : context.cardNames.join(', '));
      return _speak('Bu okumada duran: $names.\n\n$body');
    }
    if (_matches(q, ['kariyer', 'iş', 'para', 'maddi'])) {
      final slice = OracleFollowupSlices.named(
            body,
            const ['Kariyer', 'Maddi', 'iş'],
          ) ??
          summary;
      return _speak('Bu okumada kariyer tarafında duran:\n$slice');
    }
    if (_matches(q, ['yakın', 'gelecek', 'dikkat', 'uyarı', 'sakın', 'tema'])) {
      final slice = OracleFollowupSlices.named(
            body,
            const ['Yakın dönem', 'Dikkat', 'Genel', 'tema', 'Öneri'],
          ) ??
          summary;
      return _speak('Yakın eğilim olarak duran:\n$slice');
    }
    return _speak('$source içinde asıl hat:\n$summary\n\n$body');
  }

  static String _dream(
    OracleReadingContext context,
    String q,
    String source,
    String summary,
    String body,
  ) {
    final hit = OracleFollowupSlices.symbolInQuestion(q, context.cardNames);
    if (hit != null ||
        _matches(q, ['sembol', 'temsil', 'anlam', 'ne demek', 'önemli'])) {
      final label = hit ??
          (context.cardNames.isEmpty
              ? 'bu imge'
              : context.cardNames.join(', '));
      return _speak('Bu rüyada $label duruyor.\n\n$body');
    }
    if (_matches(q, ['duygu', 'tema', 'his'])) {
      final slice = OracleFollowupSlices.named(
            body,
            const ['Duygusal tema', 'duygu', 'tema'],
          ) ??
          summary;
      return _speak(slice);
    }
    if (_matches(q, ['çıkar', 'mesaj', 'sonuç', 'ne anlama'])) {
      return _speak(summary.isEmpty ? body : summary);
    }
    return _speak('$summary\n\n$body');
  }

  static bool _matches(String q, List<String> keys) =>
      OracleFollowupSlices.matches(q, keys);

  static String _speak(String observation) {
    return ConversationResponseGuard.polish(
      '$observation\n\n'
      '${ConversationCopy.closingWhisper().split('.').first.trim()}.',
    );
  }
}
