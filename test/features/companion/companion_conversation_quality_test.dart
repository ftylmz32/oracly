/// Compact rolling context, empty turns, provider error, output labels.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_request_exception.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_requests.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/ai/services/conversation_response_guard.dart';
import 'package:oracly_new/features/ai/services/followup_question_resolve.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/models/or_chat_output_mode.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_output_mode.dart';
import 'package:oracly_new/features/companion/services/companion_ai_bridge.dart';
import 'package:oracly_new/features/companion/services/companion_thread_memory.dart';

void main() {
  test('rolling window stays compact and keeps the live thread', () {
    final all = [
      for (var i = 0; i < 20; i++)
        ConversationTurn(
          role: i.isEven
              ? ConversationTurn.userRole
              : ConversationTurn.assistantRole,
          text: i.isEven ? 'Kullanıcı $i iş' : 'Yanıt $i',
        ),
    ];
    final window = ConversationTurn.takeRecent(all);
    expect(window, hasLength(ConversationTurn.maxWindow));
    expect(window.length, 8);
    expect(window.last.text, 'Yanıt 19');
    expect(window.first.text, isNot(contains('Kullanıcı 0')));
  });

  test('chat payload omits priorUser when turns already carry the thread', () {
    final request = OpenAiServiceRequests.chat(
      model: 'gpt-4.1-mini',
      userMessage: 'Değişmekten korkuyorum.',
      priorUser: const ['eski1', 'eski2', 'eski3', 'eski4', 'eski5'],
      turns: const [
        ConversationTurn(role: ConversationTurn.userRole, text: 'Kararsızım.'),
        ConversationTurn(
          role: ConversationTurn.assistantRole,
          text: 'En çok hangi konuda?',
        ),
        ConversationTurn(role: ConversationTurn.userRole, text: 'İş.'),
        ConversationTurn(
          role: ConversationTurn.assistantRole,
          text: 'Orada ne sıkışıyor?',
        ),
      ],
    );
    expect(request.payload.containsKey('priorUser'), isFalse);
    expect((request.payload['turns'] as List).length, 4);
    expect(request.payload['userMessage'], contains('korkuyorum'));
  });

  test('switching from iş to rüya is a topic change', () {
    final thread = CompanionThreadMemory.read(const [
      ConversationTurn(role: ConversationTurn.userRole, text: 'İş duruyor.'),
      ConversationTurn(
        role: ConversationTurn.assistantRole,
        text: 'Asıl sıkışma ne?',
      ),
    ], 'Dün gece durmayan bir rüya gördüm, yılan evin içinden geçti.');
    expect(thread.switched, isTrue);
    expect(thread.topic, 'rüya');
  });

  test('guard strips corporate filler', () {
    final cleaned = ConversationResponseGuard.polish(
      'Elbette, size yardımcı olabilirim. Buradayım.',
      userMessage: 'Selam',
    );
    expect(cleaned.toLowerCase(), isNot(contains('elbette')));
    expect(cleaned.toLowerCase(), isNot(contains('yardımcı olabilirim')));
  });

  test('empty send is ignored and missing AI stays fail-closed', () async {
    expect(
      FollowupQuestionResolve.expand(current: '  ', priorUser: const ['İş.']),
      '',
    );
    const bridge = CompanionAiBridge(UnconfiguredOraclyAiService());
    expect(
      () => bridge.tryLiveOrFailClosed(userMessage: 'selam'),
      throwsA(isA<AiRequestException>()),
    );
    expect(CompanionCopy.connectionError, contains('ulaşamadım'));
  });

  testWidgets('Yazılı is default; Sesli and DURDUR are visible when speaking',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionReferenceOutputMode(
            mode: OrChatOutputMode.voice,
            speaking: true,
            onChanged: (_) {},
            onStop: () {},
          ),
        ),
      ),
    );
    expect(find.text(CompanionCopy.outputText), findsOneWidget);
    expect(find.text(CompanionCopy.outputVoice), findsOneWidget);
    expect(find.text(CompanionCopy.stopSpeaking), findsOneWidget);
    expect(CompanionCopy.voiceOutputUnavailable.toLowerCase(), isNot(contains('premium')));
    expect(CompanionCopy.voiceOutputUnavailable.toLowerCase(), isNot(contains('stüdyo')));
  });
}
