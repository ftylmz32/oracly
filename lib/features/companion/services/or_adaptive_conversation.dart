/// Adaptive conversation depth — follow the user; never replace OR identity.
library;
import '../../../core/l10n/l10n.dart';
import '../../../core/personality/or_emotional_intelligence.dart';
import '../../../core/personality/or_natural_humor.dart';
import '../../../core/personality/or_response_depth.dart';
import '../../ai/production/models/conversation_turn.dart';
import '../data/companion_intent.dart';
import 'or_adaptive_cues.dart';
/// How this turn wants to be met — expression only, not a second persona.
enum OrConversationRegister {
  concise,
  deep,
  technical,
  casual,
  emotional,
  factual,
}
class OrAdaptiveRead {
  const OrAdaptiveRead({
    this.registers = const [],
    this.depthHint,
  });
  final List<OrConversationRegister> registers;
  final OrResponseDepth? depthHint;
  bool get isEmpty => registers.isEmpty && depthHint == null;
}
/// Adapts length and register over the thread without overriding core OR.
abstract final class OrAdaptiveConversation {
  OrAdaptiveConversation._();
  static String get promptRule => switch (OraclyL10n.code) {
        'en' => promptEn,
        'ru' => promptRu,
        _ => promptTr,
      };
  static const promptTr =
      'Konuşma derinliğini kullanıcıya göre uyarla: kısa isterse öz; derin '
      'tartışmada daha derin; teknikte net; gündelikte sohbet; duygusalda sakin; '
      'olgusalda kanıta dayalı. Zamanla ritmi öğren. Üslup modları yalnızca '
      'tonu boyar — OR kimliğini değiştirme. Tek kişilik, uyarlanan derinlik.';

  static const promptEn =
      'Adapt depth to the user: concise when short; deeper for deep discussion; '
      'precise when technical; conversational when casual; calm when emotional; '
      'evidence-oriented when factual. Learn rhythm over the thread. Expression '
      'modes only tint tone — never override OR identity. One identity, adaptive depth.';

  static const promptRu =
      'Подстраивай глубину: кратко / глубже / точно / разговорно / спокойно / '
      'по фактам — по запросу. Учи ритм по нити. Режимы выражения только '
      'окрашивают тон — не подменяй личность OR. Одна личность, адаптивная глубина.';

  static OrAdaptiveRead sense(
    String text, {
    List<ConversationTurn> turns = const [],
  }) {
    final t = text.trim();
    if (t.isEmpty) return const OrAdaptiveRead();
    final lower = t.toLowerCase();
    final regs = <OrConversationRegister>[];
    void add(OrConversationRegister r) {
      if (!regs.contains(r) && regs.length < 2) regs.add(r);
    }

    final emotions = OrEmotionalIntelligence.sense(t).signals;
    final humor = OrNaturalHumor.stanceFor(t);

    if (!CompanionIntent.isAdvice(t) &&
        (OrAdaptiveCues.wantsConcise(lower, t) ||
            (CompanionIntent.isGreeting(t) && t.length <= 24) ||
            (CompanionIntent.isShortFollowUp(t) &&
                !CompanionIntent.isCorrection(t)))) {
      add(OrConversationRegister.concise);
    }
    if (CompanionIntent.isAdvice(t)) add(OrConversationRegister.deep);
    if (CompanionIntent.isCorrection(t)) {
      add(OrConversationRegister.emotional);
    }
    if (OrAdaptiveCues.wantsDeep(lower, t, turns)) {
      add(OrConversationRegister.deep);
    }
    if (OrAdaptiveCues.technical(lower) || CompanionIntent.isKnowledge(t)) {
      add(OrConversationRegister.technical);
    }
    if (OrAdaptiveCues.factual(lower)) add(OrConversationRegister.factual);
    if (emotions.any((e) =>
            e == OrEmotionalSignal.sadness ||
            e == OrEmotionalSignal.anger ||
            e == OrEmotionalSignal.frustration ||
            e == OrEmotionalSignal.uncertainty) ||
        CompanionIntent.isLow(t)) {
      add(OrConversationRegister.emotional);
    }
    if (humor == OrHumorStance.welcome ||
        (t.length <= 48 &&
            !regs.contains(OrConversationRegister.emotional) &&
            !regs.contains(OrConversationRegister.technical))) {
      add(OrConversationRegister.casual);
    }

    OrResponseDepth? depth;
    if (regs.contains(OrConversationRegister.deep)) {
      depth = OrResponseDepth.deep;
    } else if (regs.contains(OrConversationRegister.concise)) {
      depth = OrResponseDepth.short;
    } else if (regs.contains(OrConversationRegister.technical) ||
        regs.contains(OrConversationRegister.factual)) {
      depth = OrResponseDepth.balanced;
    }

    return OrAdaptiveRead(
      registers: List.unmodifiable(regs),
      depthHint: depth,
    );
  }

  static String? styleHintFor(
    String text, {
    List<ConversationTurn> turns = const [],
  }) {
    final read = sense(text, turns: turns);
    if (read.isEmpty) return null;
    return [
      for (final r in read.registers) _guidance(r),
      'Core OR identity stays fixed; modes only tint expression.',
    ].join(' ');
  }

  /// Soft depth bias — settings preference remains the ceiling.
  static OrResponseDepth? depthBias(
    String text, {
    List<ConversationTurn> turns = const [],
  }) =>
      sense(text, turns: turns).depthHint;

  static String _guidance(OrConversationRegister r) => switch (r) {
        OrConversationRegister.concise =>
          'Register: concise — short, useful, no padding.',
        OrConversationRegister.deep =>
          'Register: deep — go further; still conversational, not an essay dump.',
        OrConversationRegister.technical =>
          'Register: technical — precise, clear; no mystical filler.',
        OrConversationRegister.casual =>
          'Register: casual — natural talk; light rhythm OK.',
        OrConversationRegister.emotional =>
          'Register: emotional — calm, present; no diagnosis, no pep talk.',
        OrConversationRegister.factual =>
          'Register: factual — evidence-oriented; say when unsure.',
      };
}
