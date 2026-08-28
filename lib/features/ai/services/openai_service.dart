/// Local mock oracle replies — no network, no API keys.
library;

import 'dart:async';

import '../domain/models/oracle_response.dart';
import 'prompt_builder.dart';
import 'response_parser.dart';

/// Abstract local mock contract — not a live OpenAI client.
abstract class OpenAIService {
  Future<OracleResponse> complete(BuiltPrompt prompt);
  Stream<String> stream(BuiltPrompt prompt);
  Future<int> estimateTokens(String text);
}

/// In-memory mock — never reads secrets, never calls a provider.
class MockOpenAIService implements OpenAIService {
  MockOpenAIService({this.simulatedLatencyMs = 800});

  final int simulatedLatencyMs;

  static const _mockReplies = {
    PromptTemplate.general:
        'Sezgilerin güçlü bir frekansta. Bugün kalbine güven ve evrenin '
        'rehberliğine açık ol.\n\n> OR seninle.',
    PromptTemplate.tarot:
        '**Kart mesajı** derin bir dönüşüm enerjisi taşıyor. '
        'Sabırlı kal; evren senin niyetini duyuyor.',
    PromptTemplate.dream:
        'Rüyanın sembolleri bilinçaltının sana fısıldadığı mesajları taşır. '
        'Su elementi duygusal arınmayı simgeliyor.',
    PromptTemplate.astrology:
        'Gezegen hizalanmaları netlik getiriyor. '
        'Acele kararlar yerine sezgisel adımlar tercih et.',
    PromptTemplate.dailyEnergy:
        'Bugünkü kozmik titreşimin yüksek. '
        'Sabah niyetini belirle, akşam minnettarlık pratiği yap.',
  };

  @override
  Future<OracleResponse> complete(BuiltPrompt prompt) async {
    await Future<void>.delayed(Duration(milliseconds: simulatedLatencyMs));
    final raw =
        _mockReplies[prompt.template] ?? _mockReplies[PromptTemplate.general]!;
    return ResponseParser.parse(
      rawText: raw,
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      tokenUsage: raw.length ~/ 4,
      latencyMs: simulatedLatencyMs,
    );
  }

  @override
  Stream<String> stream(BuiltPrompt prompt) async* {
    final raw =
        _mockReplies[prompt.template] ?? _mockReplies[PromptTemplate.general]!;
    final words = raw.split(RegExp(r'(?<=\s)'));
    for (final word in words) {
      await Future<void>.delayed(const Duration(milliseconds: 48));
      yield word;
    }
  }

  @override
  Future<int> estimateTokens(String text) async => text.length ~/ 4;
}
