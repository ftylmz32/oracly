/// Shared helpers for OR response quality regression — behavior, not prose.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/personality/or_core.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';

/// Local OR reply path used by quality suite tests.
class OrQualityHarness {
  OrQualityHarness({this.personality = 'direct'});

  final String personality;
  final CompanionResponder _or = const CompanionResponder();

  CompanionResponse say(
    String text, {
    List<ConversationTurn> turns = const [],
    ReflectionContext context = const ReflectionContext(),
  }) {
    return _or.respond(
      request: InsightRequest(text: text),
      context: context,
      turns: turns,
      personality: personality,
    );
  }

  List<ConversationTurn> append(
    List<ConversationTurn> prior,
    String user,
    String assistant,
  ) =>
      [
        ...prior,
        ConversationTurn(role: ConversationTurn.userRole, text: user),
        ConversationTurn(
          role: ConversationTurn.assistantRole,
          text: assistant,
        ),
      ];

  /// Soft behavioral floor — never exact prose.
  void expectHumanChamber(String body, {int? maxLen}) {
    final t = body.trim();
    expect(t, isNotEmpty);
    if (maxLen != null) expect(t.length, lessThan(maxLen));
    expect(OrCore.soundsAlive(t), isTrue);
    expect(OrCore.looksTherapistScript(t), isFalse);
    expect(OrCore.looksMetaAi(t), isFalse);
    expect(OrCore.looksCustomerService(t), isFalse);
    expect(OrCore.looksForcedPositivity(t), isFalse);
  }

  void expectKeepsThread(String body, List<String> tokens) {
    final lower = body.toLowerCase();
    for (final token in tokens) {
      expect(lower, contains(token.toLowerCase()));
    }
  }

  void expectAvoids(String body, List<String> banned) {
    final lower = body.toLowerCase();
    for (final b in banned) {
      expect(lower, isNot(contains(b.toLowerCase())));
    }
  }
}
