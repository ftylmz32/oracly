from pathlib import Path

def w(path, text):
    Path(path).write_text(text.replace("\r\n", "\n"), encoding="utf-8", newline="\n")
    print(path, len(text.splitlines()))

w("lib/features/companion/services/or_context_selection_sources.dart", '''/// Source pickers for OR context selection — never dumps archives.
library;

import '../../../core/intelligence/services/personal_memory_relevance.dart';
import '../../../core/personality/or_explanation_mode.dart';
import '../../ai/production/models/conversation_turn.dart';
import '../models/reflection_context.dart';
import 'or_context_bucket_helpers.dart';
import 'or_long_term_memory_boundaries.dart';

abstract final class OrContextSelectionSources {
  OrContextSelectionSources._();

  static String? discovery(
    String? raw,
    String current,
    List<ConversationTurn> recent,
  ) {
    final base = (raw ?? '').trim();
    if (base.isEmpty) return null;
    final merged = OrExplanationMode.mergeHint(
      base,
      message: current,
      turns: recent,
    );
    if (merged == null || merged.trim().isEmpty) return null;
    return OrLongTermMemoryBoundaries.tag(
      OrMemoryKind.observation,
      merged,
    );
  }

  static String? feature(String? raw) {
    final body = (raw ?? '').trim();
    if (body.isEmpty || !OrContextBucketHelpers.looksFeature(body)) {
      return null;
    }
    final capped = OrContextBucketHelpers.cap(
      body,
      OrContextBucketHelpers.featureCap,
    );
    return OrLongTermMemoryBoundaries.tag(
      OrMemoryKind.interpretation,
      capped,
    );
  }

  static String? memory({
    required ReflectionContext? reflection,
    required String current,
    required bool discoveryTaken,
    required bool featureTaken,
  }) {
    if (discoveryTaken || featureTaken) return null;
    final obs = PersonalMemoryRelevance.filterObservation(
      reflection?.proactiveAcknowledgment,
      current,
    );
    if (obs != null && !OrContextBucketHelpers.looksFeature(obs)) {
      return OrLongTermMemoryBoundaries.tag(
        OrMemoryKind.observation,
        OrContextBucketHelpers.cap(obs, OrContextBucketHelpers.memoryCap),
      );
    }
    final saved = OrContextBucketHelpers.relevantSaved(
      reflection?.savedMemories ?? const [],
      current,
    );
    if (saved == null) return null;
    return OrLongTermMemoryBoundaries.tag(OrMemoryKind.fact, saved);
  }
}
''')

w("lib/features/companion/services/or_context_selection_engine.dart", '''/// Context Selection Engine — pick relevant buckets only.
library;

import '../../../core/personality/or_emotional_intelligence.dart';
import '../../../core/personality/or_natural_humor.dart';
import '../../ai/production/models/conversation_turn.dart';
import '../models/reflection_context.dart';
import 'companion_thread_digest.dart';
import 'companion_thread_memory.dart';
import 'or_adaptive_conversation.dart';
import 'or_context_bucket_helpers.dart';
import 'or_context_selection_sources.dart';
import 'or_selected_context.dart';

/// Assembles [OrSelectedContext] from sources without dumping archives.
abstract final class OrContextSelectionEngine {
  OrContextSelectionEngine._();

  static OrSelectedContext select({
    required String currentMessage,
    required List<ConversationTurn> recentMessages,
    List<ConversationTurn>? fullHistory,
    ReflectionContext? reflection,
    String? discoveryHint,
    String? featureHandoff,
  }) {
    final current = currentMessage.trim();
    final recent = ConversationTurn.takeRecent(recentMessages);
    final digest = CompanionThreadDigest.fromOlder(
      fullHistory ?? recentMessages,
    );
    final discovery =
        OrContextSelectionSources.discovery(discoveryHint, current, recent);
    final featureRaw =
        featureHandoff ?? reflection?.proactiveAcknowledgment;
    final feature = OrContextSelectionSources.feature(featureRaw);
    final memory = OrContextSelectionSources.memory(
      reflection: reflection,
      current: current,
      discoveryTaken: discovery != null,
      featureTaken: feature != null,
    );
    final facts = OrContextBucketHelpers.stableNameFact(
      reflection?.userName,
      current,
    );
    final preference =
        OrContextBucketHelpers.preferenceWhenAsked(current);
    final omitRecap = recent.any((t) => t.isUser);
    final thread = CompanionThreadMemory.read(recent, current).instructionFor(
      current,
      omitRecap: omitRecap,
    );
    final threadWithDigest = [
      if (digest != null) digest,
      thread,
    ].join(' ').trim();
    return OrSelectedContext(
      currentMessage: current,
      recentMessages: recent,
      stableUserFacts: facts,
      recentDiscovery: discovery,
      relevantMemory: memory,
      featureSpecific: feature,
      preferenceHint: preference,
      emotionalGuidance: OrEmotionalIntelligence.styleHintFor(current),
      humorGuidance: OrNaturalHumor.styleHintFor(current),
      adaptiveGuidance: OrAdaptiveConversation.styleHintFor(
        current,
        turns: recent,
      ),
      threadGuidance: threadWithDigest,
    );
  }

  static String styleHint({
    required String currentMessage,
    required List<ConversationTurn> recentMessages,
    List<ConversationTurn>? fullHistory,
    ReflectionContext? reflection,
    String? discoveryHint,
    String? featureHandoff,
  }) =>
      select(
        currentMessage: currentMessage,
        recentMessages: recentMessages,
        fullHistory: fullHistory,
        reflection: reflection,
        discoveryHint: discoveryHint,
        featureHandoff: featureHandoff,
      ).toStyleHint();
}
''')

# Write master scenario test
w("test/features/companion/or_master_intelligence_scenarios_test.dart", r'''/// OR master intelligence scenarios — continuity, digest, short follow-ups.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/openai/chat_prompt_builder.dart';
import 'package:oracly_new/features/companion/data/companion_intent.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';
import 'package:oracly_new/features/companion/services/companion_thread_digest.dart';
import 'package:oracly_new/features/companion/services/companion_thread_memory.dart';
import 'package:oracly_new/features/companion/services/contextual_followup_policy.dart';
import 'package:oracly_new/features/companion/services/or_adaptive_conversation.dart';
import 'package:oracly_new/features/companion/services/or_context_selection_engine.dart';
import 'package:oracly_new/features/companion/services/or_discovery_handoff_quality.dart';

void main() {
  const or = CompanionResponder();
  setUp(() => OraclyL10n.bind('tr'));

  String say(String text, {List<ConversationTurn> turns = const []}) => or
      .respond(
        request: InsightRequest(text: text),
        context: const ReflectionContext(),
        turns: turns,
        personality: 'direct',
      )
      .body;

  test('scenario A greeting is short and not helpdesk', () {
    final body = say('Selam');
    expect(body.length, lessThan(120));
    expect(body.toLowerCase(), isNot(contains('nasıl yardımcı')));
    expect(body.toLowerCase(), isNot(contains('how can i help')));
  });

  test('scenario C job fear continues across follow-ups', () {
    expect(
      CompanionIntent.isJobChange(
        'İşimden ayrılmayı düşünüyorum ama korkuyorum.',
      ),
      isTrue,
    );

    final turns = [
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'İşimden ayrılmayı düşünüyorum ama korkuyorum.',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Asıl zorlayan işi istememek mi, yanlış karar korkusu mu?',
      ),
    ];

    final fear = CompanionThreadMemory.read(
      turns,
      'Yanlış karar vermekten korkuyorum.',
    );
    expect(fear.topic, 'iş');
    expect(fear.answeringPrompt || fear.continuing, isTrue);

    final why = CompanionThreadMemory.read(
      [
        ...turns,
        const ConversationTurn(
          role: ConversationTurn.userRole,
          text: 'Yanlış karar vermekten korkuyorum.',
        ),
        const ConversationTurn(
          role: ConversationTurn.assistantRole,
          text: 'Yanlış karar korkusu seni yerinde tutuyor gibi.',
        ),
      ],
      'Neden korktuğumu bilmiyorum.',
    );
    expect(why.topic, 'iş');
    final decision = ContextualFollowUpPolicy.evaluate(
      userMessage: 'Neden korktuğumu bilmiyorum.',
      thread: why,
    );
    expect(decision.mode, isNot(FollowUpMode.ask));

    final body = say(
      'Peki şimdi ne yapayım?',
      turns: [
        ...turns,
        const ConversationTurn(
          role: ConversationTurn.userRole,
          text: 'Yanlış karar vermekten korkuyorum.',
        ),
        const ConversationTurn(
          role: ConversationTurn.assistantRole,
          text: 'Yanlış karar korkusu seni yerinde tutuyor gibi.',
        ),
      ],
    );
    expect(body.toLowerCase(), contains('iş'));
    expect(body.toLowerCase(), isNot(contains('nasıl yardımcı')));
    expect(body.toLowerCase(), isNot(contains('anlıyorum. bazen')));
  });

  test('short follow-ups do not reset topic', () {
    final turns = [
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'İş konusunda ne yapacağımı bilmiyorum.',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'İşi istememek mi, yanlış karar korkusu mu?',
      ),
    ];
    for (final cue in ['peki?', 'neden?', 'devam', 'emin misin?']) {
      expect(CompanionIntent.isShortFollowUp(cue), isTrue, reason: cue);
      final thread = CompanionThreadMemory.read(turns, cue);
      expect(thread.topic, 'iş', reason: cue);
      final body = say(cue, turns: turns);
      expect(body.toLowerCase(), contains('iş'), reason: cue);
      expect(body.toLowerCase(), isNot(contains('nasıl yardımcı')), reason: cue);
    }
  });

  test('long conversation digest preserves older topic without dump', () {
    final long = <ConversationTurn>[
      for (var i = 0; i < 6)
        ConversationTurn(
          role: ConversationTurn.userRole,
          text: 'İşimi değiştirmeyi düşünüyorum $i aydır.',
        ),
      for (var i = 0; i < 6)
        ConversationTurn(
          role: ConversationTurn.assistantRole,
          text: 'iş üzerine kısa gözlem $i.',
        ),
      const ConversationTurn(
        role: ConversationTurn.userRole,
        text: 'Bugün hava güzel.',
      ),
      const ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Güzel bir ara.',
      ),
    ];
    final digest = CompanionThreadDigest.fromOlder(long);
    expect(digest, isNotNull);
    expect(digest!.toLowerCase(), contains('iş'));
    expect(digest.toLowerCase(), contains('invent nothing'));
    expect(digest.length, lessThanOrEqualTo(CompanionThreadDigest.maxChars));
    expect(digest.contains('İşimi değiştirmeyi düşünüyorum 0'), isFalse);

    final hint = OrContextSelectionEngine.styleHint(
      currentMessage: 'Peki?',
      recentMessages: ConversationTurn.takeRecent(long),
      fullHistory: long,
    );
    expect(hint.toLowerCase(), contains('earlier'));
    expect(hint.toLowerCase(), isNot(contains('memory id')));
  });

  test('tarot handoff stays compact and id-free', () {
    final compact = OrDiscoveryHandoffQuality.compact(
      const OracleReadingContext(
        sourceLabel: 'Tarot',
        question: 'Ne yapmalıyım?',
        cards: ['The Fool', 'id:abc-123'],
        summary: 'Yeni bir başlangıç teması.',
      ),
    );
    expect(compact.length, lessThanOrEqualTo(400));
    expect(compact.toLowerCase(), contains('tarot'));
    expect(compact, isNot(contains('abc-123')));
  });

  test('adaptive length: short follow-up is concise; long fear can go deep', () {
    final short = OrAdaptiveConversation.sense('peki?');
    expect(short.registers, contains(OrConversationRegister.concise));
    final deep = OrAdaptiveConversation.sense(
      'İşimden ayrılmayı düşünüyorum ama yanlış karar vermekten çok korkuyorum '
      've bu korkunun nedenini gerçekten bilmiyorum.',
      turns: const [
        ConversationTurn(
          role: ConversationTurn.userRole,
          text: 'İş konusunda uzun zamandır kararsızım.',
        ),
      ],
    );
    expect(
      deep.registers.contains(OrConversationRegister.deep) ||
          deep.registers.contains(OrConversationRegister.emotional),
      isTrue,
    );
  });

  test('prompt forbids fake memory and stock empathy restart', () {
    final s = ChatPromptBuilder.system.toLowerCase();
    expect(s, contains('anı uydurma'));
    expect(s, contains('kısa takip'));
    expect(s, contains('seni anlıyorum'));
  });
}
''')
