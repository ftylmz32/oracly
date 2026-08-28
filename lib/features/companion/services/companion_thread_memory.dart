/// Rolling topic for one OR chat — never invents off-thread memory.
library;

import '../../ai/production/models/conversation_turn.dart';
import '../data/companion_intent.dart';
import 'companion_conversation_continuity.dart';
import 'companion_held_topic.dart';
import 'companion_thread_memory_scan.dart';
import 'companion_thread_topics.dart';
import 'contextual_followup_policy.dart';
import 'follow_up_prompt_hints.dart';

class CompanionThreadMemory {
  const CompanionThreadMemory({
    this.topic,
    this.switched = false,
    this.answeringPrompt = false,
    this.hadPriorTopic = false,
    this.lastAssistant,
    this.recap,
    this.knownTimeSpan = false,
    this.interrupted = false,
    this.resuming = false,
    this.continuityHint = '',
  });

  final String? topic;
  final bool switched;
  final bool answeringPrompt;
  final bool hadPriorTopic;
  final String? lastAssistant;
  final String? recap;
  final bool knownTimeSpan;
  final bool interrupted;
  final bool resuming;
  final String continuityHint;

  bool get continuing =>
      lastAssistant != null &&
      topic != null &&
      hadPriorTopic &&
      !switched &&
      !answeringPrompt &&
      !interrupted;

  String get instruction {
    final parts = <String>[
      if (topic != null) 'Şu anki konu: $topic.',
      if (answeringPrompt)
        'Kullanıcı az önce sorduğun netleştirmeye yanıt verdi. '
            'Bunu bu sohbetin konusu olarak tut; yeniden sorma.',
      if (continuing)
        'Bu devam eden bir sohbet. Yeni cümleyi önceki turlara bağla; '
            'her mesajı yeni konuşma sanma.',
      if (switched)
        'Konu değişti. Yeni konuya geç; eskisine dönme veya özetleme. '
            'Eski ve yeni konuyu tek hikâyede birleştirme.',
      if (recap != null) 'Son kullanıcı izi: $recap.',
      if (continuityHint.isNotEmpty) continuityHint,
      'Son asistan yanıtını tekrarlama. Anı uydurma. '
          'Çelişen izler varsa tek sonuca zorlama; uydurma çözüm yok. '
          'Kullanıcıya sistem, kayıt veya iç mekanik dilinden bahsetme.',
    ];
    return parts.join(' ');
  }

  static const hintLimit = 360;

  static CompanionThreadMemory read(
    List<ConversationTurn> turns,
    String current,
  ) {
    final span = CompanionThreadMemoryScan.span(turns);
    final lastAssistant = CompanionThreadMemoryScan.last(span, user: false);
    final previous = CompanionThreadMemoryScan.heldTopic(span);
    final now = CompanionThreadTopics.of(current);
    final answering =
        CompanionThreadMemoryScan.isAnswer(current, lastAssistant, previous);
    final heldNow = CompanionHeldTopic.resolve(
      interrupted: false,
      answering: answering,
      previous: previous,
      now: now,
    );
    final switched = !answering &&
        previous != null &&
        heldNow != null &&
        previous != heldNow;
    final interrupted =
        CompanionIntent.isGreeting(current) && previous != null;
    final resuming = CompanionThreadMemoryScan.isResume(
      current,
      previous,
      lastAssistant,
      interrupted,
    );
    final topic = CompanionHeldTopic.resolve(
      interrupted: interrupted,
      answering: answering,
      previous: previous,
      now: now,
    );
    final facts = CompanionConversationContinuity.facts(span, current);
    final draft = CompanionThreadMemory(
      topic: topic,
      switched: switched,
      answeringPrompt: answering,
      hadPriorTopic: previous != null,
      lastAssistant: lastAssistant,
      recap: CompanionThreadMemoryScan.recap(span, current),
      knownTimeSpan: facts.hasTimeSpan,
      interrupted: interrupted,
      resuming: resuming,
    );
    return CompanionThreadMemory(
      topic: draft.topic,
      switched: draft.switched,
      answeringPrompt: draft.answeringPrompt,
      hadPriorTopic: draft.hadPriorTopic,
      lastAssistant: draft.lastAssistant,
      recap: draft.recap,
      knownTimeSpan: draft.knownTimeSpan,
      interrupted: interrupted,
      resuming: resuming,
      continuityHint: CompanionConversationContinuity.guidance(
        thread: draft, facts: facts, current: current,
      ),
    );
  }

  String instructionFor(String current, {bool omitRecap = false}) {
    final followUp = ContextualFollowUpPolicy.evaluate(
      userMessage: current,
      thread: this,
    );
    final base = omitRecap
        ? CompanionThreadMemory(
            topic: topic,
            switched: switched,
            answeringPrompt: answeringPrompt,
            hadPriorTopic: hadPriorTopic,
            lastAssistant: lastAssistant,
            knownTimeSpan: knownTimeSpan,
            interrupted: interrupted,
            resuming: resuming,
            continuityHint: continuityHint,
          ).instruction
        : instruction;
    return '${base.trim()} ${FollowUpPromptHints.forDecision(followUp)}'.trim();
  }

  static String merge({
    String? discovery,
    required List<ConversationTurn> turns,
    required String current,
  }) {
    final extra = (discovery ?? '').trim();
    final omitRecap = turns.any((t) => t.isUser);
    final thread = read(turns, current).instructionFor(
      current,
      omitRecap: omitRecap,
    );
    final body = extra.isEmpty ? thread : '$extra $thread';
    if (body.length <= hintLimit) return body;
    final cut = body.substring(0, hintLimit);
    final space = cut.lastIndexOf(' ');
    return space > 280 ? cut.substring(0, space) : cut;
  }
}
