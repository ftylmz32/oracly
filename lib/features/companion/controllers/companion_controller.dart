/// SPRINT-003 — Companion session controller.
library;

import 'package:flutter/foundation.dart';

import '../models/companion_state.dart';
import '../models/conversation.dart';
import '../models/insight_request.dart';
import '../services/companion_experience_service.dart';

class CompanionController extends ChangeNotifier {
  CompanionController(this._service);

  final CompanionExperienceService _service;

  CompanionState _state = const CompanionState();

  CompanionState get state => _state;

  Future<void> initialize() async {
    try {
      final result = await _service.loadOrCreateSession();
      _state = CompanionState(
        phase: CompanionPhase.conversing,
        conversation: result.conversation,
        context: result.context,
      );
    } catch (_) {
      _state = const CompanionState(
        phase: CompanionPhase.error,
        errorMessage: 'OR şu an hazırlanamıyor. Biraz sonra tekrar dene.',
      );
    }
    notifyListeners();
  }

  Future<void> send(String text) async {
    final conversation = _state.conversation;
    final context = _state.context;
    if (conversation == null || context == null || text.trim().isEmpty) {
      return;
    }

    _state = _state.copyWith(
      phase: CompanionPhase.thinking,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final result = await _service.send(
        conversation: conversation,
        context: context,
        request: _classifyRequest(text),
      );
      _state = _state.copyWith(
        phase: CompanionPhase.conversing,
        conversation: result.conversation,
      );
    } catch (_) {
      _state = _state.copyWith(
        phase: CompanionPhase.error,
        errorMessage: 'Mesaj gönderilemedi. Tekrar deneyebilirsin.',
      );
    }
    notifyListeners();
  }

  Future<void> saveToMemory(String content) async {
    await _service.saveUserMemory(content: content);
    final refreshed = await _service.loadOrCreateSession();
    _state = _state.copyWith(context: refreshed.context);
    notifyListeners();
  }

  InsightRequest _classifyRequest(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('rüya')) {
      return InsightRequest(
        text: text,
        kind: InsightRequestKind.dream,
        conversationTopic: ConversationTopic.dream,
      );
    }
    if (lower.contains('kart') ||
        lower.contains('tarot') ||
        lower.contains('açılım')) {
      return InsightRequest(
        text: text,
        kind: InsightRequestKind.tarot,
        conversationTopic: ConversationTopic.tarot,
      );
    }
    if (lower.contains('harita') ||
        lower.contains('burç') ||
        lower.contains('yükselen')) {
      return InsightRequest(
        text: text,
        kind: InsightRequestKind.birthChart,
        conversationTopic: ConversationTopic.birthChart,
      );
    }
    if (lower.contains('hedef')) {
      return InsightRequest(
        text: text,
        kind: InsightRequestKind.goals,
        conversationTopic: ConversationTopic.goals,
      );
    }
    if (lower.contains('günlük') || lower.contains('yazdım')) {
      return InsightRequest(
        text: text,
        kind: InsightRequestKind.journal,
        conversationTopic: ConversationTopic.journal,
      );
    }
    if (lower.contains('ritüel')) {
      return InsightRequest(
        text: text,
        kind: InsightRequestKind.ritual,
        conversationTopic: ConversationTopic.ritual,
      );
    }
    if (lower.contains('duygu') || lower.contains('hissed')) {
      return InsightRequest(
        text: text,
        kind: InsightRequestKind.emotionalPattern,
        conversationTopic: ConversationTopic.reflection,
      );
    }
    return InsightRequest(text: text);
  }
}
