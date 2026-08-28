/// OR real gate — live proxy+provider Selam + follow-up context (host evidence).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';

import '../../support/ai_e2e_probe.dart';

bool get _e2e => Platform.environment['ORACLY_E2E'] == '1';

String _fold(String raw) => raw
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('İ', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c');

void main() {
  final skip = _e2e ? false : 'Set ORACLY_E2E=1 with local Fastify running';

  test('REAL OR Selam + follow-up retains thread context via proxy', () async {
    await detectE2eProvider();
    if (e2eProviderBlocker != null) {
      markTestSkipped(e2eProviderBlocker!);
      return;
    }

    final probe = AiE2eProbe();
    final ai = e2eLiveAi(probe);

    final first = await ai.chat(userMessage: 'Selam.');
    expect(first.isSuccess, isTrue, reason: '${first.failure}');
    final reply1 = first.value!.text.trim();
    expect(reply1.length, greaterThan(5));
    assertProxyOnly(probe, forbidden: 'sk-');
    expect(probe.lastUrl.toString(), e2eProxyUrl);

    final second = await ai.chat(
      userMessage: 'Az once ne dedigimi hatirliyor musun?',
      turns: [
        ConversationTurn.user('Selam.'),
        ConversationTurn.assistant(reply1),
      ],
    );
    expect(second.isSuccess, isTrue, reason: '${second.failure}');
    final reply2 = second.value!.text.trim();
    expect(reply2.length, greaterThan(5));
    assertProxyOnly(probe, forbidden: 'sk-');

    final body = jsonDecode(probe.lastBody!) as Map<String, dynamic>;
    final payload = body['payload'] as Map<String, dynamic>?;
    final turns = payload?['turns'];
    expect(turns, isA<List>());
    expect((turns as List).length, greaterThanOrEqualTo(2));
    final encoded = jsonEncode(turns);
    expect(encoded.contains('Selam'), isTrue);

    // Evidence: prior turns reached the proxy. Reply must be a real string.
    expect(_fold(reply2), isNot(isEmpty));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}