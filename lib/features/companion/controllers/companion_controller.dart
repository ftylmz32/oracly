/// SPRINT-003 — Companion session controller.
library;

import 'package:flutter/foundation.dart';

import '../../ai/production/ai_failure.dart';
import '../../ai/production/ai_request_exception.dart';
import '../../ai/domain/models/ai_message.dart';
import '../../ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../../core/copy/resilience_copy.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/telemetry/crash_telemetry_service.dart';
import '../copy/companion_copy.dart';
import '../models/companion_state.dart';
import '../models/conversation.dart';
import '../models/reflection_context.dart';
import '../services/companion_ephemeral_session.dart';
import '../services/companion_experience_service.dart';
import '../services/companion_insight_classify.dart';
import '../services/or_chat_handoff.dart';
import 'companion_output_controller.dart';

class CompanionController extends ChangeNotifier {
  CompanionController(
    this._service,
    this._output, {
    AnalyticsService? analytics,
    CrashTelemetryService? crashTelemetry,
  })  : _analytics = analytics,
        _crashTelemetry = crashTelemetry;

  final CompanionExperienceService _service;
  final CompanionOutputController _output;
  final AnalyticsService? _analytics;
  final CrashTelemetryService? _crashTelemetry;

  CompanionState _state = const CompanionState(
    phase: CompanionPhase.initializing,
    linkStatus: CompanionLinkStatus.connecting,
  );
  bool _disposed = false;
  bool _networkRetry = false;
  OracleReadingContext? _pendingHandoff;
  OracleReadingContext? _readingContext;
  int _sendGeneration = 0;

  CompanionState get state => _state;

  /// Active feature reading for askOracle handoff turns.
  OracleReadingContext? get readingContext => _readingContext;

  /// True while [retryLast] is driving a real recovery attempt.
  bool get isNetworkRetrying => _networkRetry;

  @override
  void dispose() {
    _disposed = true;
    _sendGeneration++;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> reloadFromStorage() async {
    _state = const CompanionState(
      phase: CompanionPhase.initializing,
      linkStatus: CompanionLinkStatus.connecting,
    );
    _safeNotify();
    await initialize();
  }

  /// Starts a fresh OR session without feature handoff context.
  Future<void> startFreshConversation() async {
    _pendingHandoff = null;
    _readingContext = null;
    _sendGeneration++;
    _state = CompanionState(
      phase: CompanionPhase.welcome,
      linkStatus: CompanionLinkStatus.online,
      conversation: CompanionEphemeralSession.welcome(),
      context: const ReflectionContext(),
    );
    _safeNotify();
  }

  /// Drops active feature reading context; keeps the thread.
  void clearReadingContext() {
    _pendingHandoff = null;
    _readingContext = null;
    final prev = _state.context;
    if (prev == null) {
      _safeNotify();
      return;
    }
    _state = _state.copyWith(
      context: ReflectionContext(
        userName: prev.userName,
        savedMemories: prev.savedMemories,
        recentReflectionTexts: prev.recentReflectionTexts,
        recurringThemes: prev.recurringThemes,
        readingCount: prev.readingCount,
        dreamCount: prev.dreamCount,
        hasBirthChart: prev.hasBirthChart,
        ritualDaysCount: prev.ritualDaysCount,
        unfinishedJournalHint: prev.unfinishedJournalHint,
      ),
    );
    _safeNotify();
  }

  /// Merges a typed feature handoff into the live OR context.
  void applyReadingHandoff(OracleReadingContext context) {
    _pendingHandoff = context;
    _readingContext = context;
    _mergeHandoff(context);
  }

  void _mergeHandoff(OracleReadingContext context) {
    final text = OrChatHandoff.compact(context);
    if (text.trim().isEmpty) return;
    final prev = _state.context ?? const ReflectionContext();
    final arrival = OrChatHandoff.arrivalLine(context);
    var conversation = _state.conversation;
    if (conversation != null &&
        !conversation.messages.any((m) => m.isUser)) {
      conversation = conversation.copyWith(
        messages: [
          for (final m in conversation.messages)
            if (!m.isUser && m.id.startsWith('welcome_'))
              AIMessage(
                id: m.id,
                role: m.role,
                content: arrival,
                createdAt: m.createdAt,
              )
            else
              m,
        ],
        updatedAt: DateTime.now(),
      );
    }
    _state = _state.copyWith(
      conversation: conversation,
      context: ReflectionContext(
        userName: prev.userName,
        savedMemories: prev.savedMemories,
        recentReflectionTexts: prev.recentReflectionTexts,
        recurringThemes: prev.recurringThemes,
        readingCount: prev.readingCount,
        dreamCount: prev.dreamCount,
        hasBirthChart: prev.hasBirthChart,
        ritualDaysCount: prev.ritualDaysCount,
        unfinishedJournalHint: prev.unfinishedJournalHint,
        proactiveAcknowledgment: text,
      ),
    );
    _safeNotify();
  }

  Future<void> initialize() async {
    if (_state.conversation != null && _state.context != null) {
      final pending = _pendingHandoff;
      if (pending != null) _mergeHandoff(pending);
      _state = _state.copyWith(
        errorMessage: null,
        clearFailureKind: true,
        linkStatus: CompanionLinkStatus.online,
      );
      _safeNotify();
      return;
    }
    final heldHandoff = _pendingHandoff;
    _state = _state.copyWith(
      phase: CompanionPhase.initializing,
      errorMessage: null,
      lastFailedText: null,
      clearFailureKind: true,
      linkStatus: CompanionLinkStatus.connecting,
    );
    _safeNotify();
    try {
      final result = await _service.loadOrCreateSession();
      final hasUser = result.conversation.messages.any((m) => m.isUser);
      _state = CompanionState(
        phase: hasUser ? CompanionPhase.conversing : CompanionPhase.welcome,
        conversation: result.conversation,
        context: result.context,
        linkStatus: CompanionLinkStatus.online,
      );
    } catch (error) {
      // Bootstrap failed — keep chat mounted with an ephemeral session.
      // Do not claim the device is offline; send can still attempt the live path.
      assert(() {
        debugPrint(
          '[OR] sessionReady=no ephemeral=yes '
          'errorType=${error.runtimeType}',
        );
        return true;
      }());
      _state = CompanionState(
        phase: CompanionPhase.welcome,
        conversation: CompanionEphemeralSession.welcome(),
        context: const ReflectionContext(),
        linkStatus: CompanionLinkStatus.online,
        errorMessage: null,
      );
    }
    final restore = _pendingHandoff ?? heldHandoff;
    if (restore != null) {
      _readingContext = restore;
      _mergeHandoff(restore);
    }
    _safeNotify();
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (_state.conversation == null || _state.context == null) {
      await initialize();
    }
    final conversation = _state.conversation;
    final context = _state.context;
    if (conversation == null || context == null) {
      _state = _state.copyWith(
        phase: CompanionPhase.welcome,
        linkStatus: CompanionLinkStatus.online,
        errorMessage: CompanionCopy.connectionError,
        lastFailedText: trimmed,
      );
      _safeNotify();
      return;
    }
    // Duplicate send blocked while a turn is already in flight.
    if (_state.isBusy) return;

    // Lock before any await so rapid taps cannot enqueue duplicate sends.
    final token = ++_sendGeneration;
    final recovering = _networkRetry ||
        _state.linkStatus == CompanionLinkStatus.offline ||
        _state.linkStatus == CompanionLinkStatus.reconnecting ||
        _state.lastFailureKind == AiFailureKind.network;
    final keepFailure = recovering ? _state.lastFailureKind : null;
    final keepFailedText = recovering
        ? (_state.lastFailedText?.trim().isNotEmpty == true
            ? _state.lastFailedText
            : trimmed)
        : null;

    _state = _state.copyWith(phase: CompanionPhase.thinking);
    _safeNotify();

    await _output.onUserSend();
    if (_disposed || token != _sendGeneration) return;

    final already = conversation.messages.isNotEmpty &&
        conversation.messages.last.isUser &&
        conversation.messages.last.content.trim() == trimmed;
    final withUser = already
        ? conversation
        : conversation.copyWith(
            messages: [
              ...conversation.messages,
              AIMessage(
                id: 'msg_u_${DateTime.now().millisecondsSinceEpoch}',
                role: AIMessageRole.user,
                content: trimmed,
                createdAt: DateTime.now(),
              ),
            ],
          );

    _state = _state.copyWith(
      phase: CompanionPhase.thinking,
      conversation: withUser,
      errorMessage: null,
      lastFailedText: keepFailedText,
      lastFailureKind: keepFailure,
      clearFailureKind: !recovering,
      linkStatus: recovering
          ? CompanionLinkStatus.reconnecting
          : CompanionLinkStatus.online,
    );
    _safeNotify();

    final started = DateTime.now();
    _analytics?.logOrMessageSent(length: trimmed.length);

    try {
      final result = await _service.send(
        conversation: withUser,
        context: context,
        request: CompanionInsightClassify.fromText(trimmed),
        readingContext: _readingContext,
      );
      if (_disposed || token != _sendGeneration) return;
      _analytics?.logOrResponseReceived(
        fromAi: result.fromAi,
        latency: DateTime.now().difference(started),
      );
      _state = _state.copyWith(
        phase: CompanionPhase.conversing,
        conversation: result.conversation,
        clearFailureKind: true,
        linkStatus: CompanionLinkStatus.online,
      );
      _safeNotify();
      if (_disposed || token != _sendGeneration) return;
      try {
        await _output.speakIfVoice(result.response.body);
      } catch (_) {}
    } on AiRequestException catch (e) {
      if (_disposed || token != _sendGeneration) return;
      _analytics?.logOperation(
        operation: 'or_response',
        success: false,
        latency: DateTime.now().difference(started),
        errorCategory: e.failure.kind.name,
      );
      _crashTelemetry?.recordSevere(
        operation: 'or_response',
        errorCategory: e.failure.kind.name,
      );
      assert(() {
        debugPrint(
          '[OR] requestFailed kind=${e.failure.kind.name} '
          'keepChat=yes link=${_linkFor(e.failure.kind).name}',
        );
        return true;
      }());
      // Failures stay in-chat. Network → offline strip; others → online + typed copy.
      _state = _state.copyWith(
        phase: CompanionPhase.conversing,
        conversation: withUser,
        errorMessage: _surface(e),
        lastFailedText: trimmed,
        lastFailureKind: e.failure.kind,
        linkStatus: _linkFor(e.failure.kind),
      );
    } catch (error) {
      if (_disposed || token != _sendGeneration) return;
      _analytics?.logOperation(
        operation: 'or_response',
        success: false,
        latency: DateTime.now().difference(started),
        errorCategory: 'unknown',
      );
      assert(() {
        debugPrint('[OR] requestFailed kind=unknown errorType=${error.runtimeType}');
        return true;
      }());
      // Unknown ≠ offline. Keep chat usable; offer calm retry without a fake
      // connectivity claim.
      _state = _state.copyWith(
        phase: CompanionPhase.conversing,
        conversation: withUser,
        errorMessage: ResilienceCopy.temporaryFailure,
        lastFailedText: trimmed,
        lastFailureKind: AiFailureKind.providerError,
        linkStatus: CompanionLinkStatus.online,
      );
    }
    if (_disposed || token != _sendGeneration) return;
    _safeNotify();
  }

  @visibleForTesting
  void seedSessionForTest({
    required Conversation conversation,
    ReflectionContext context = const ReflectionContext(),
    CompanionPhase phase = CompanionPhase.welcome,
    OracleReadingContext? readingContext,
  }) {
    _readingContext = readingContext;
    _pendingHandoff = readingContext;
    _state = CompanionState(
      phase: phase,
      conversation: conversation,
      context: context,
      linkStatus: CompanionLinkStatus.online,
    );
  }

  @visibleForTesting
  void invalidateSendForTest() => _sendGeneration++;

  Future<void> retryLast() async {
    if (_disposed || _state.isBusy) return;
    final failed = _state.lastFailedText?.trim() ?? '';
    if (failed.isEmpty) {
      await _reconnectWithoutMessage();
      return;
    }
    // Real retry of the failed user turn — never invent a local success reply.
    _networkRetry = true;
    _state = _state.copyWith(
      linkStatus: CompanionLinkStatus.reconnecting,
      errorMessage: null,
    );
    _safeNotify();
    try {
      await send(failed);
    } finally {
      _networkRetry = false;
      if (!_disposed) _safeNotify();
    }
  }

  /// Soft reconnect with no user text — does not invent an assistant message.
  Future<void> _reconnectWithoutMessage() async {
    final wasNetwork = _state.lastFailureKind == AiFailureKind.network ||
        _state.linkStatus == CompanionLinkStatus.offline;
    _networkRetry = true;
    _state = _state.copyWith(
      linkStatus: CompanionLinkStatus.reconnecting,
      errorMessage: null,
    );
    _safeNotify();
    try {
      if (_state.conversation == null || _state.context == null) {
        await initialize();
        return;
      }
      // Honest: without a live probe, stay offline if the last failure was network.
      _state = _state.copyWith(
        linkStatus: wasNetwork
            ? CompanionLinkStatus.offline
            : CompanionLinkStatus.online,
      );
    } finally {
      _networkRetry = false;
      if (!_disposed) _safeNotify();
    }
  }

  Future<void> regenerateLast() async {
    final conversation = _state.conversation;
    if (conversation == null || _state.isBusy) return;
    final msgs = [
      for (final message in conversation.messages)
        if (message.content.trim().isNotEmpty) message,
    ];
    if (msgs.length < 2 || msgs.last.isUser) return;
    final lastUser = msgs.lastWhere((message) => message.isUser);
    _state = _state.copyWith(
      conversation: conversation.copyWith(
        messages: msgs.sublist(0, msgs.length - 1),
      ),
    );
    await send(lastUser.content);
  }

  Future<void> saveToMemory(String content) async {
    await _service.saveUserMemory(content: content);
    final refreshed = await _service.loadOrCreateSession();
    _state = _state.copyWith(context: refreshed.context);
    _safeNotify();
  }

  /// Map typed failures to calm in-chat copy — never invent offline as a wall.
  @visibleForTesting
  static String surfaceForTest(AiRequestException error) => _surface(error);

  @visibleForTesting
  static CompanionLinkStatus linkForTest(AiFailureKind kind) => _linkFor(kind);

  static String _surface(AiRequestException error) {
    return switch (error.failure.kind) {
      AiFailureKind.noConfiguration => error.userMessage,
      AiFailureKind.unauthorized => error.userMessage,
      AiFailureKind.network => CompanionCopy.connectionError,
      AiFailureKind.timeout => error.userMessage,
      AiFailureKind.rateLimit => error.userMessage,
      AiFailureKind.invalidResponse => error.userMessage,
      AiFailureKind.providerError => error.userMessage,
      AiFailureKind.imageAnalysisUnavailable =>
        ResilienceCopy.analysisUnavailable,
    };
  }

  /// Network reachability is an offline *status*; chat shell stays mounted.
  static CompanionLinkStatus _linkFor(AiFailureKind kind) {
    return switch (kind) {
      AiFailureKind.network => CompanionLinkStatus.offline,
      _ => CompanionLinkStatus.online,
    };
  }
}
