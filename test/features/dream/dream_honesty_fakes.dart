/// Test doubles for Dream release honesty — never used in product code.
library;

import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/core/domain/repositories/dream_repository.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/chat_ai_reply.dart';
import 'package:oracly_new/features/ai/production/models/coffee_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/palm_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';

class LiveDreamAiStub implements OraclyAiService {
  const LiveDreamAiStub();

  static const interpretation =
      'Açık pencere, sessiz evin kenarında duruyor; bir cevap değil, içeriye doğru bir nefes gibi düşünülebilir.';

  @override
  bool get isConfigured => true;

  @override
  bool get allowsLocalFallback => false;

  @override
  bool get visionAvailable => false;

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext context) async {
    return AiOutcome.success(
      const DreamAiAnalysis(
        summary: 'Sakin bir ev imgesi.',
        symbols: ['Ev', 'Pencere'],
        emotionalTheme: 'Dinginlik.',
        interpretation: interpretation,
        dailyLifeReflection: 'Bir pencereye yaklaşmak yeterli olabilir.',
        conclusion: 'Bugün bir nefes ara.',
      ),
    );
  }

  @override
  Future<AiOutcome<ChatAiReply>> chat({
    required String userMessage,
    List<String> priorUser = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) async =>
      AiOutcome.success(const ChatAiReply(text: 'OR'));

  @override
  Future<AiOutcome<ChatAiReply>> askOracle({
    required ReadingAiContext context,
    required String userMessage,
    List<String> priorUser = const [],
    List<String> observedThemes = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) async =>
      AiOutcome.success(const ChatAiReply(text: 'OR'));

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
  }) async =>
      throw UnsupportedError('coffee');

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
  }) async =>
      throw UnsupportedError('palm');
}

class MemDreamRepository implements DreamRepository {
  final _items = <DreamRecord>[];

  @override
  Future<List<DreamRecord>> getAll() async => List.of(_items);

  @override
  Future<DreamRecord?> getById(String id) async {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<void> save(DreamRecord record) async {
    _items.removeWhere((e) => e.id == record.id);
    _items.add(record);
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> sync() async {}
}
