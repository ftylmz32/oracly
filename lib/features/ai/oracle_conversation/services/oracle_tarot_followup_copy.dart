/// Tarot OR'a Sor — answers from full reading context, no extra questions.
library;

import '../../../../core/copy/conversation_copy.dart';
import '../../services/followup_question_resolve.dart';
import '../models/oracle_reading_context.dart';

abstract final class OracleTarotFollowupCopy {
  OracleTarotFollowupCopy._();

  static String respond({
    required OracleReadingContext context,
    required String question,
    List<String> priorUser = const [],
  }) {
    final q = FollowupQuestionResolve.expand(
      current: question,
      priorUser: priorUser,
    ).toLowerCase();
    if (_matches(q, ['ters', 'ikinci', '2.', 'üçüncü', '3.', 'birinci', '1.'])) {
      return _orientation(context, q);
    }
    if (_matches(q, [
      'en önemli kart',
      'ana kart',
      'hangisi',
      'omurga',
      'hangi karta',
    ])) {
      return _primary(context);
    }
    if (_matches(q, ['aşk', 'ilişki', 'sevgi', 'partner', 'karşı taraf'])) {
      return _slice(context, const ['Aşk', 'duygusal', 'bağ'], 'Aşk');
    }
    if (_matches(q, ['kariyer', 'iş', 'meslek'])) {
      return _slice(context, const ['Kariyer', 'iş enerjisi', 'emek'], 'Kariyer');
    }
    if (_matches(q, [
      'asıl mesaj',
      'ana mesaj',
      'en önemli mesaj',
      'ne söylüyor',
      'pratik',
    ])) {
      return _message(context);
    }
    return _direct(
      'Bu açılım',
      context.fullInterpretation?.trim().isNotEmpty == true
          ? context.fullInterpretation!.trim()
          : context.interpretationSummary,
    );
  }

  static String _orientation(OracleReadingContext context, String q) {
    final lines = context.cardsSummary
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    String? line;
    if (_matches(q, ['ikinci', '2.']) && lines.length >= 2) line = lines[1];
    if (_matches(q, ['üçüncü', '3.']) && lines.length >= 3) line = lines[2];
    if (_matches(q, ['birinci', 'ilk', '1.']) && lines.isNotEmpty) {
      line = lines.first;
    }
    line ??= lines.cast<String?>().firstWhere(
          (l) => l!.toLowerCase().contains('ters'),
          orElse: () => lines.isEmpty ? null : lines.first,
        );
    return _direct(
      'Kartın yönü',
      '${line ?? context.cardsSummary}\n\n'
      'Ters geldiğinde kartın teması içe dönük veya ertelenmiş duruyor '
      'olabilir. Enerji henüz dışarı akmamış; biraz daha netlik istiyor.\n\n'
      '${context.interpretationSummary}',
    );
  }

  static String _primary(OracleReadingContext context) {
    final name = context.cardNames.isNotEmpty
        ? context.cardNames.first
        : context.readingTitle;
    return _direct(
      'En önemli kart',
      'Bu açılımda omurga **$name**. '
      'Diğer kartlar onu çerçeveler; asıl vurgu burada toplanıyor.\n\n'
      '${context.interpretationSummary}',
    );
  }

  static String _message(OracleReadingContext context) {
    final slice = _namedSlice(context.fullInterpretation ?? '', const [
          'Bugün İçin Mesaj',
          'Açılımın Teması',
        ]) ??
        context.interpretationSummary;
    return _direct(
      'Asıl mesaj',
      slice,
    );
  }

  static String _slice(
    OracleReadingContext context,
    List<String> keys,
    String title,
  ) {
    final body = context.fullInterpretation?.trim() ?? '';
    final slice = _namedSlice(body, keys) ?? context.interpretationSummary;
    return _direct(title, slice);
  }

  static String? _namedSlice(String body, List<String> keys) {
    if (body.trim().isEmpty) return null;
    for (final key in keys) {
      final match = RegExp(
        '^$key\\s*:?\\s*\\n([\\s\\S]+?)(?=\\n\\n[A-ZÇĞİÖŞÜa-zçğıöşü]+:|\\n## |\$)',
        multiLine: true,
      ).firstMatch(body);
      if (match != null && match.group(1)!.trim().isNotEmpty) {
        return match.group(1)!.trim();
      }
      final idx = body.toLowerCase().indexOf(key.toLowerCase());
      if (idx >= 0) {
        final cut = body.substring(idx).trim();
        if (cut.length > 40) return cut;
      }
    }
    return null;
  }

  static String _direct(String title, String body) {
    final lead = switch (title) {
      'Aşk' => 'Bu açılımda aşk tarafında duran:\n',
      'Kariyer' => 'Bu açılımda kariyer tarafında duran:\n',
      _ => '',
    };
    return '$lead$body\n\n'
        '${ConversationCopy.closingWhisper().split('.').first.trim()}.';
  }

  static bool _matches(String q, List<String> keys) =>
      keys.any((k) => q.contains(k));
}
