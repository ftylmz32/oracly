/// When OR may ask one clarifying question — never by default.
library;

import '../../../core/personality/or_explanation_mode.dart';
import '../data/companion_intent.dart';
import '../data/companion_mood_copy.dart';
import 'companion_thread_memory.dart';
import 'companion_thread_topics.dart';
import 'follow_up_decision.dart';

export 'follow_up_decision.dart';

abstract final class ContextualFollowUpPolicy {
  ContextualFollowUpPolicy._();

  /// Job-change opens longer than this already carry enough detail to reflect.
  static const detailedJobAskMax = 96;

  static FollowUpDecision evaluate({
    required String userMessage,
    required CompanionThreadMemory thread,
  }) {
    final text = userMessage.trim();
    final lower = text.toLowerCase();
    if (text.isEmpty) {
      return const FollowUpDecision(mode: FollowUpMode.answerOnly);
    }
    if (CompanionIntent.isGreeting(text)) {
      return const FollowUpDecision(mode: FollowUpMode.answerOnly);
    }
    if (CompanionIntent.isCorrection(text)) {
      return const FollowUpDecision(
        mode: FollowUpMode.reflect,
        localKind: FollowUpLocalKind.reflectOnly,
      );
    }
    if (_skipAsk(text, lower)) {
      return const FollowUpDecision(mode: FollowUpMode.answerOnly);
    }
    // Short follow-ups continue the thread — never restart with a quiz.
    if (CompanionIntent.isShortFollowUp(text) &&
        (thread.hadPriorTopic || thread.continuing || thread.answeringPrompt)) {
      return const FollowUpDecision(
        mode: FollowUpMode.reflect,
        localKind: FollowUpLocalKind.reflectOnly,
      );
    }
    if (thread.answeringPrompt) {
      return const FollowUpDecision(
        mode: FollowUpMode.reflect,
        localKind: FollowUpLocalKind.reflectOnly,
      );
    }
    if (_wantsExploration(lower) && text.length <= 96) {
      return const FollowUpDecision(
        mode: FollowUpMode.ask,
        localKind: FollowUpLocalKind.explore,
      );
    }
    if (CompanionMoodCopy.looksLow(text) &&
        thread.topic == null &&
        text.length <= 56) {
      return const FollowUpDecision(
        mode: FollowUpMode.ask,
        localKind: FollowUpLocalKind.moodOpen,
      );
    }
    if (CompanionIntent.isUndecided(text) && thread.topic != 'iş') {
      return const FollowUpDecision(
        mode: FollowUpMode.ask,
        localKind: FollowUpLocalKind.undecidedScope,
      );
    }
    if (CompanionIntent.isJobChange(text) &&
        !thread.continuing &&
        !thread.knownTimeSpan &&
        !CompanionThreadTopics.isTimeSpan(text) &&
        text.length <= detailedJobAskMax) {
      return const FollowUpDecision(
        mode: FollowUpMode.ask,
        localKind: FollowUpLocalKind.jobTimeline,
      );
    }
    if (thread.interrupted) {
      return const FollowUpDecision(mode: FollowUpMode.answerOnly);
    }
    if (thread.resuming) {
      return const FollowUpDecision(
        mode: FollowUpMode.reflect,
        localKind: FollowUpLocalKind.reflectOnly,
      );
    }
    if (thread.continuing && thread.topic != null && _fearNeedsClarify(lower)) {
      return const FollowUpDecision(
        mode: FollowUpMode.ask,
        localKind: FollowUpLocalKind.fearClarify,
      );
    }
    if (thread.continuing || text.length > 48) {
      return const FollowUpDecision(
        mode: FollowUpMode.reflect,
        localKind: FollowUpLocalKind.reflectOnly,
      );
    }
    return const FollowUpDecision(mode: FollowUpMode.answerOnly);
  }

  static bool _wantsExploration(String lower) {
    const cues = [
      'konuşmak istiyorum', 'anlatmak istiyorum', 'birlikte bak', 'keşfet',
      'anlamaya çalış', 'want to talk', 'want to explore', "let's look",
      'давай разбер',
    ];
    return cues.any(lower.contains);
  }

  static bool _skipAsk(String text, String lower) {
    if (CompanionIntent.isKnowledge(text)) return true;
    if (CompanionIntent.isPythonAsync(text)) return true;
    if (CompanionIntent.isAdvice(text)) return true;
    if (CompanionIntent.isCorrection(text)) return true;
    if (CompanionIntent.isPrediction(text)) return true;
    if (CompanionIntent.isFortune(lower)) return true;
    if (OrExplanationMode.parseShape(text) != null) return true;
    if (text.length > 160) return true;
    return false;
  }

  static bool _fearNeedsClarify(String lower) {
    if (!lower.contains('kork') &&
        !lower.contains('afraid') &&
        !lower.contains('страх')) {
      return false;
    }
    if (lower.contains('yanlış') ||
        lower.contains('hata') ||
        lower.contains('wrong decision') ||
        lower.contains('ошиб')) {
      return false;
    }
    return lower.contains('değiş') ||
        lower.contains('chang') ||
        lower.contains('перемен');
  }
}
