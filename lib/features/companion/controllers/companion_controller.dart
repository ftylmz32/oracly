/// SPRINT-003 — Companion session controller.
library;

import 'package:flutter/foundation.dart';

import '../../ai/production/ai_failure.dart';
import '../../ai/production/ai_request_exception.dart';
import '../../ai/domain/models/ai_message.dart';
import '../../ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../../core/copy/resilience_copy.dart';
import '../../../core/data/datasources/local_storage.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/telemetry/crash_telemetry_service.dart';
import '../copy/companion_copy.dart';
import '../models/companion_state.dart';
import '../models/conversation.dart';
import '../models/reflection_context.dart';
import '../services/companion_ephemeral_session.dart';
import '../services/companion_experience_service.dart';
import '../services/companion_insight_classify.dart';
import '../services/companion_session_bootstrap.dart';
import '../services/first_reading_or_deepen.dart';
import '../services/or_chat_handoff.dart';
import '../services/or_operation_id.dart';
import '../../gems/services/paid_ai_operation_id.dart';
import 'companion_output_controller.dart';

/// What the CURRENT retryable failure (if any) is actually about — lets
/// [CompanionController.retryLast]/[CompanionController.retryPersist]
/// dispatch to the right recovery without a stale flag from an unrelated,
/// already-resolved failure hijacking a later, different one.
enum _FailureOrigin {
  /// No unresolved failure, or it was already resolved.
  none,

  /// The last unresolved failure was [CompanionController
  /// .startFreshConversation] failing to persist the new thread.
  freshStart,

  /// The last unresolved failure belongs to a normal message send/persist
  /// against the EXISTING conversation — never routes to New Chat.
  message,
}

class CompanionController extends ChangeNotifier {
  CompanionController(
    this._service,
    this._output, {
    this._storage,
    this._analytics,
    this._crashTelemetry,
    String Function(String feature)? operationIdFactory,
  }) : _operationIdFactory = operationIdFactory ?? PaidAiOperationId.create;

  final CompanionExperienceService _service;
  final CompanionOutputController _output;
  final LocalStorage? _storage;
  final AnalyticsService? _analytics;
  final CrashTelemetryService? _crashTelemetry;
  final String Function(String feature) _operationIdFactory;

  CompanionState _state = const CompanionState(
    phase: CompanionPhase.initializing,
    linkStatus: CompanionLinkStatus.connecting,
  );
  bool _disposed = false;
  bool _networkRetry = false;
  bool _regenLocked = false;
  _FailureOrigin _failureOrigin = _FailureOrigin.none;
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
  ///
  /// Full atomicity: the durable [CompanionSessionBootstrap.sessionId]
  /// overwrite is attempted first, and EVERY live-session mutation —
  /// clearing the pending handoff/reading context, bumping the send
  /// generation, and swapping in the new conversation/context — happens
  /// only after that save succeeds. On failure, the old conversation, old
  /// readingContext, and old pending handoff all remain exactly as they
  /// were; only the retryable save-failure state changes. Never claim a
  /// new chat while the old thread remains on disk, and never lose the
  /// user's live session to a failed attempt at replacing it.
  Future<void> startFreshConversation() async {
    if (_disposed || _state.isBusy) return;
    final now = DateTime.now();
    final fresh = Conversation(
      id: CompanionSessionBootstrap.sessionId,
      title: 'OR Companion',
      topic: ConversationTopic.general,
      messages: [
        AIMessage(
          id: 'welcome_${now.millisecondsSinceEpoch}',
          role: AIMessageRole.assistant,
          content: CompanionCopy.welcomeLine(),
          createdAt: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
    final keptContext = _state.context ?? const ReflectionContext();
    try {
      await _service.persistConversation(fresh);
    } catch (_) {
      _failureOrigin = _FailureOrigin.freshStart;
      _crashTelemetry?.recordSevere(
        operation: 'or_fresh_chat',
        errorCategory: 'local_persistence',
      );
      // Keep the existing thread AND its reading context/handoff intact;
      // surface a calm retryable save failure. Nothing about the live
      // session changes on this path.
      _state = _state.copyWith(
        errorMessage: CompanionCopy.saveFailed,
        lastFailedText: null,
        lastFailureKind: AiFailureKind.localPersistence,
        linkStatus: CompanionLinkStatus.online,
      );
      _safeNotify();
      return;
    }
    if (_disposed) return;
    // Durable commit point reached — only now may the live session move
    // on from the old conversation/handoff.
    _failureOrigin = _FailureOrigin.none;
    _pendingHandoff = null;
    _readingContext = null;
    _sendGeneration++;
    _state = CompanionState(
      phase: CompanionPhase.welcome,
      linkStatus: CompanionLinkStatus.online,
      conversation: fresh,
      // proactiveAcknowledgment is deliberately OMITTED: it is transient
      // feature-handoff text (e.g. "I see you just drew a card about...")
      // tied to the OLD reading context this fresh chat is explicitly
      // leaving behind. Everything else here is stable, long-term journey
      // memory and must survive a fresh start unchanged.
      context: ReflectionContext(
        userName: keptContext.userName,
        savedMemories: keptContext.savedMemories,
        recentReflectionTexts: keptContext.recentReflectionTexts,
        recurringThemes: keptContext.recurringThemes,
        readingCount: keptContext.readingCount,
        dreamCount: keptContext.dreamCount,
        hasBirthChart: keptContext.hasBirthChart,
        ritualDaysCount: keptContext.ritualDaysCount,
        unfinishedJournalHint: keptContext.unfinishedJournalHint,
      ),
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
    if (conversation != null && !conversation.messages.any((m) => m.isUser)) {
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
      _restorePendingOperation();
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

  Future<void> send(String text, {bool reusePendingOperation = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (_state.conversation == null || _state.context == null) {
      await initialize();
    }
    final conversation = _state.conversation;
    final context = _state.context;
    if (conversation == null || context == null) {
      _failureOrigin = _FailureOrigin.message;
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
    final recovering =
        _networkRetry ||
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

    final pendingId = OrOperationId.pendingId(conversation.lastMessage);
    final reuse = reusePendingOperation && pendingId != null;
    var baseMessages = [...conversation.messages];
    if (!reuse && pendingId != null) {
      baseMessages[baseMessages.length - 1] = OrOperationId.withState(
        baseMessages.last,
        OrOperationId.abandoned,
      );
    }
    final withUser = reuse
        ? conversation
        : conversation.copyWith(
            messages: [
              ...baseMessages,
              AIMessage(
                id: 'msg_u_${DateTime.now().millisecondsSinceEpoch}',
                role: AIMessageRole.user,
                content: trimmed,
                createdAt: DateTime.now(),
                metadata: {
                  OrOperationId.metadataKey: _operationIdFactory(
                    _readingContext == null ? 'chat' : 'oracle',
                  ),
                  OrOperationId.stateKey: OrOperationId.pending,
                },
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
      if (!result.persisted) {
        assert(() {
          debugPrint(
            '[OR] persistFailed keepReply=yes '
            'msgCount=${result.conversation.messages.length}',
          );
          return true;
        }());
        _crashTelemetry?.recordSevere(
          operation: 'or_persist',
          errorCategory: 'local_persistence',
        );
        _failureOrigin = _FailureOrigin.message;
        _state = _state.copyWith(
          phase: CompanionPhase.conversing,
          conversation: result.conversation,
          errorMessage: CompanionCopy.saveFailed,
          lastFailedText: null,
          lastFailureKind: AiFailureKind.localPersistence,
          linkStatus: CompanionLinkStatus.online,
        );
        _safeNotify();
        try {
          await _output.speakIfVoice(result.response.body);
        } catch (_) {}
        return;
      }
      _failureOrigin = _FailureOrigin.none;
      _state = _state.copyWith(
        phase: CompanionPhase.conversing,
        conversation: result.conversation,
        clearFailureKind: true,
        linkStatus: CompanionLinkStatus.online,
      );
      _safeNotify();
      // One-shot deepen: only after a real usable assistant reply.
      final storage = _storage;
      final body = result.response.body.trim();
      if (storage != null && result.fromAi && body.isNotEmpty) {
        final consumed = await FirstReadingOrDeepen.consumeIfActive(
          storage,
          _readingContext,
        );
        if (consumed) _safeNotify();
      }
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
      _failureOrigin = _FailureOrigin.message;
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
        debugPrint(
          '[OR] requestFailed kind=unknown errorType=${error.runtimeType}',
        );
        return true;
      }());
      // Unknown ≠ offline. Keep chat usable; offer calm retry without a fake
      // connectivity claim.
      _failureOrigin = _FailureOrigin.message;
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

  @visibleForTesting
  void markOfflineForTest() {
    _state = _state.copyWith(
      linkStatus: CompanionLinkStatus.offline,
      lastFailureKind: AiFailureKind.network,
    );
  }

  Future<void> retryLast() async {
    if (_disposed || _state.isBusy) return;
    if (_failureOrigin == _FailureOrigin.freshStart) {
      await startFreshConversation();
      return;
    }
    if (_state.lastFailureKind == AiFailureKind.localPersistence &&
        OrOperationId.pendingId(_state.conversation?.lastMessage) == null) {
      await retryPersist();
      return;
    }
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
      await send(failed, reusePendingOperation: true);
    } finally {
      _networkRetry = false;
      if (!_disposed) _safeNotify();
    }
  }

  /// Saves the in-memory conversation only — zero provider calls.
  Future<void> retryPersist() async {
    if (_disposed || _state.isBusy) return;
    if (_failureOrigin == _FailureOrigin.freshStart) {
      await startFreshConversation();
      return;
    }
    if (_state.lastFailureKind != AiFailureKind.localPersistence) return;
    final conversation = _state.conversation;
    if (conversation == null) return;
    final token = ++_sendGeneration;
    _state = _state.copyWith(
      phase: CompanionPhase.thinking,
      errorMessage: null,
      linkStatus: CompanionLinkStatus.online,
    );
    _safeNotify();
    try {
      await _service.persistConversation(conversation);
      if (_disposed || token != _sendGeneration) return;
      _failureOrigin = _FailureOrigin.none;
      _state = _state.copyWith(
        phase: CompanionPhase.conversing,
        conversation: conversation,
        clearFailureKind: true,
        errorMessage: null,
        lastFailedText: null,
        linkStatus: CompanionLinkStatus.online,
      );
    } catch (error) {
      if (_disposed || token != _sendGeneration) return;
      assert(() {
        debugPrint('[OR] persistRetryFailed errorType=${error.runtimeType}');
        return true;
      }());
      _crashTelemetry?.recordSevere(
        operation: 'or_persist_retry',
        errorCategory: 'local_persistence',
      );
      _failureOrigin = _FailureOrigin.message;
      _state = _state.copyWith(
        phase: CompanionPhase.conversing,
        conversation: conversation,
        errorMessage: CompanionCopy.saveFailed,
        lastFailureKind: AiFailureKind.localPersistence,
        linkStatus: CompanionLinkStatus.online,
      );
    }
    if (_disposed || token != _sendGeneration) return;
    _safeNotify();
  }

  /// Soft reconnect with no user text — does not invent an assistant message.
  Future<void> _reconnectWithoutMessage() async {
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
      // Clear the offline banner so the user can send again. The next send is
      // the real network probe — do not force offline without a new failure.
      _state = _state.copyWith(
        linkStatus: CompanionLinkStatus.online,
        clearFailureKind: true,
        lastFailedText: null,
      );
    } finally {
      _networkRetry = false;
      if (!_disposed) _safeNotify();
    }
  }

  /// Replaces the last assistant answer with a fresh provider generation.
  ///
  /// Removes the completed user turn and its assistant reply, then [send]s the
  /// same text so exactly one user turn remains with a **new** operation id.
  Future<void> regenerateLast() async {
    if (_disposed || _state.isBusy || _regenLocked) return;
    final conversation = _state.conversation;
    if (conversation == null) return;
    final msgs = [
      for (final message in conversation.messages)
        if (message.content.trim().isNotEmpty) message,
    ];
    if (msgs.length < 2 || msgs.last.isUser) return;
    final lastUserIndex = msgs.lastIndexWhere((message) => message.isUser);
    if (lastUserIndex < 0) return;
    final text = msgs[lastUserIndex].content;
    // Sync lock before any await — rapid double taps share one generation.
    _regenLocked = true;
    try {
      _state = _state.copyWith(
        conversation: conversation.copyWith(
          messages: msgs.sublist(0, lastUserIndex),
          updatedAt: DateTime.now(),
        ),
        errorMessage: null,
        lastFailedText: null,
        clearFailureKind: true,
      );
      _safeNotify();
      await send(text);
    } finally {
      _regenLocked = false;
    }
  }

  /// Makes an unresolved turn terminal without issuing a provider request.
  Future<void> abandonPendingOperation() async {
    if (_disposed || _state.isBusy) return;
    final conversation = _state.conversation;
    if (conversation == null ||
        OrOperationId.pendingId(conversation.lastMessage) == null) {
      return;
    }
    final messages = [...conversation.messages];
    messages[messages.length - 1] = OrOperationId.withState(
      messages.last,
      OrOperationId.abandoned,
    );
    final abandoned = conversation.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );
    _state = _state.copyWith(
      conversation: abandoned,
      errorMessage: null,
      lastFailedText: null,
      clearFailureKind: true,
      linkStatus: CompanionLinkStatus.online,
    );
    _safeNotify();
    try {
      await _service.persistConversation(abandoned);
    } catch (_) {
      // The in-memory terminal state still prevents accidental key reuse.
    }
  }

  void _restorePendingOperation() {
    final pending = _state.conversation?.lastMessage;
    if (OrOperationId.pendingId(pending) == null) return;
    _state = _state.copyWith(
      phase: CompanionPhase.conversing,
      errorMessage: ResilienceCopy.temporaryFailure,
      lastFailedText: pending!.content,
      lastFailureKind: AiFailureKind.providerError,
      linkStatus: CompanionLinkStatus.online,
    );
  }

  /// Persists [content] as a saved user memory. Never throws — a real
  /// persistence failure is caught and reported as `false` so the caller
  /// can show an honest error (never a false success) with no unhandled
  /// async error escaping into the global error zone. The underlying
  /// store (MemoryService.addAdvancedMemory) dedupes by normalized
  /// content, so calling this again with the same content — a retry — can
  /// never create a duplicate memory.
  Future<bool> saveToMemory(String content) async {
    try {
      await _service.saveUserMemory(content: content);
    } catch (e) {
      _crashTelemetry?.recordSevere(
        operation: 'or_save_memory',
        errorCategory: 'local_persistence',
      );
      return false;
    }
    // Best-effort only: the memory is already durably saved above: a
    // failure refreshing the in-memory context must not be reported as a
    // save failure.
    try {
      final refreshed = await _service.loadOrCreateSession();
      _state = _state.copyWith(context: refreshed.context);
      _safeNotify();
    } catch (_) {}
    return true;
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
      AiFailureKind.authPending => error.userMessage,
      AiFailureKind.appCheck => error.userMessage,
      AiFailureKind.network => CompanionCopy.connectionError,
      AiFailureKind.timeout => error.userMessage,
      AiFailureKind.rateLimit => error.userMessage,
      AiFailureKind.invalidResponse => error.userMessage,
      AiFailureKind.providerError => error.userMessage,
      AiFailureKind.localPersistence => CompanionCopy.saveFailed,
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
