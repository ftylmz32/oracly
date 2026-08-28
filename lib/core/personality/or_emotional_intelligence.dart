/// OR emotional intelligence — notice signals, respond in proportion.
library;

import '../l10n/l10n.dart';
import 'or_emotional_cues.dart';

/// Conversational affect cues — never clinical labels.
enum OrEmotionalSignal {
  frustration,
  excitement,
  uncertainty,
  humor,
  sadness,
  anger,
  curiosity,
  indecision,
}

/// Compact read of the current user turn.
class OrEmotionalRead {
  const OrEmotionalRead(this.signals);

  final List<OrEmotionalSignal> signals;

  bool get isEmpty => signals.isEmpty;
  bool get isPresent => signals.isNotEmpty;
}

/// Recognize conversational emotion; never diagnose or overreact.
abstract final class OrEmotionalIntelligence {
  OrEmotionalIntelligence._();

  static String get promptRule => switch (OraclyL10n.code) {
        'en' => promptEn,
        'ru' => promptRu,
        _ => promptTr,
      };

  static const promptTr =
      'Konuşmadaki duygusal sinyalleri fark et (hayal kırıklığı, heyecan, belirsizlik, '
      'mizah, üzüntü, öfke, merak, kararsızlık) — doğal ve orantılı yanıt ver. '
      'Sıradan duyguyu büyütme; terapist senaryosu yok. '
      'Ruh sağlığı teşhisi koyma; klinik etiket kullanma.';

  static const promptEn =
      'Notice conversational emotional signals (frustration, excitement, '
      'uncertainty, humor, sadness, anger, curiosity, indecision) — respond '
      'naturally and in proportion. Do not dramatize ordinary emotion; no '
      'therapist scripts. Never diagnose mental health conditions; no clinical labels.';

  static const promptRu =
      'Замечай эмоциональные сигналы в разговоре (раздражение, воодушевление, '
      'неуверенность, юмор, грусть, гнев, любопытство, нерешительность) — '
      'отвечай естественно и соразмерно. Не драматизируй обычную эмоцию; '
      'без терапевтических скриптов. Не ставь психиатрических диагнозов; '
      'без клинических ярлыков.';

  /// Per-turn styleHint when a signal is present — guidance, not a script.
  static String? styleHintFor(String text) {
    final sensed = sense(text);
    if (sensed.isEmpty) return null;
    final names = sensed.signals.map(_label).join(', ');
    return switch (OraclyL10n.code) {
      'en' =>
        'Signal(s): $names. Acknowledge lightly; stay conversational; '
            'no diagnosis, no overreaction.',
      'ru' =>
        'Сигнал(ы): $names. Легко отметь; оставайся в разговоре; '
            'без диагноза и переигрывания.',
      _ =>
        'Sinyal(ler): $names. Hafif fark et; sohbette kal; '
            'teşhis yok, aşırı tepki yok.',
    };
  }

  static OrEmotionalRead sense(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty || t.length < 3) return const OrEmotionalRead([]);
    final hits = <OrEmotionalSignal>[];
    void add(OrEmotionalSignal s) {
      if (!hits.contains(s) && hits.length < 2) hits.add(s);
    }

    if (_has(t, OrEmotionalCues.anger)) add(OrEmotionalSignal.anger);
    if (_has(t, OrEmotionalCues.frustration)) {
      add(OrEmotionalSignal.frustration);
    }
    if (_has(t, OrEmotionalCues.sadness)) add(OrEmotionalSignal.sadness);
    if (_has(t, OrEmotionalCues.excitement)) {
      add(OrEmotionalSignal.excitement);
    }
    if (_has(t, OrEmotionalCues.humor)) add(OrEmotionalSignal.humor);
    if (_has(t, OrEmotionalCues.curiosity)) add(OrEmotionalSignal.curiosity);
    if (_has(t, OrEmotionalCues.indecision)) {
      add(OrEmotionalSignal.indecision);
    }
    if (_has(t, OrEmotionalCues.uncertainty)) {
      add(OrEmotionalSignal.uncertainty);
    }
    return OrEmotionalRead(List.unmodifiable(hits));
  }

  /// Output that asserts a mental-health diagnosis — reject.
  static bool claimsDiagnosis(String text) {
    final lower = text.toLowerCase();
    return OrEmotionalCues.diagnosis.any(lower.contains);
  }

  static bool _has(String text, List<String> cues) {
    for (final cue in cues) {
      // Ultra-short tokens need boundaries ("sad"≠"sadece"); stems may embed.
      if (cue.length <= 2) {
        if (RegExp('\\b${RegExp.escape(cue)}\\b').hasMatch(text)) return true;
      } else if (text.contains(cue)) {
        return true;
      }
    }
    return false;
  }

  static String _label(OrEmotionalSignal s) => switch (s) {
        OrEmotionalSignal.frustration => 'frustration',
        OrEmotionalSignal.excitement => 'excitement',
        OrEmotionalSignal.uncertainty => 'uncertainty',
        OrEmotionalSignal.humor => 'humor',
        OrEmotionalSignal.sadness => 'sadness',
        OrEmotionalSignal.anger => 'anger',
        OrEmotionalSignal.curiosity => 'curiosity',
        OrEmotionalSignal.indecision => 'indecision',
      };
}
