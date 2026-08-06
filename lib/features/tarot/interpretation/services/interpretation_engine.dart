/// OR-1180 — Central tarot interpretation orchestrator.
library;

import 'package:flutter/foundation.dart';

import '../../../../core/copy/resilience_copy.dart';
import '../cache/interpretation_cache.dart';
import '../executors/interpretation_executor.dart';
import '../executors/local_interpretation_executor.dart';
import '../formatters/interpretation_formatter.dart';
import '../models/interpretation_error.dart';
import '../models/interpretation_request.dart';
import '../models/interpretation_result.dart';
import '../models/interpretation_stream_event.dart';
import '../models/reading_context.dart';
import 'interpretation_prompt_adapter.dart';

class InterpretationEngine {
  InterpretationEngine({
    required this.executor,
    required this.cache,
    InterpretationPromptAdapter? promptAdapter,
    InterpretationFormatter? formatter,
    InterpretationRetryPolicy? retryPolicy,
  })  : _promptAdapter = promptAdapter ?? InterpretationPromptAdapter(),
        _formatter = formatter ?? const InterpretationFormatter(),
        _retryPolicy = retryPolicy ?? const InterpretationRetryPolicy();

  final InterpretationExecutor executor;
  final InterpretationCache cache;
  final InterpretationPromptAdapter _promptAdapter;
  final InterpretationFormatter _formatter;
  final InterpretationRetryPolicy _retryPolicy;

  Future<InterpretationResult> interpret({
    required ReadingContext context,
    bool forceRefresh = false,
    InterpretationMode mode = InterpretationMode.standard,
  }) async {
    final request = _buildRequest(
      context: context,
      mode: mode,
      forceRefresh: forceRefresh,
    );

    if (!forceRefresh && mode != InterpretationMode.regenerate) {
      final cached = await cache.get(context.cacheKey);
      if (cached != null) return cached;
    }

    return _executeWithRetry(request);
  }

  Future<InterpretationResult> regenerate(ReadingContext context) {
    return interpret(
      context: context,
      forceRefresh: true,
      mode: InterpretationMode.regenerate,
    );
  }

  Stream<InterpretationStreamEvent> interpretStream({
    required ReadingContext context,
    bool forceRefresh = false,
  }) async* {
    final request = _buildRequest(
      context: context,
      mode: InterpretationMode.streaming,
      forceRefresh: forceRefresh,
    );

    if (!forceRefresh) {
      final cached = await cache.get(context.cacheKey);
      if (cached != null) {
        yield InterpretationStreamEvent(
          phase: InterpretationStreamPhase.completed,
          result: cached,
          progress: 1,
        );
        return;
      }
    }

    yield* executor.executeStream(request).map((event) {
      if (event.phase == InterpretationStreamPhase.completed &&
          event.result != null) {
        final validated = _validateResult(event.result!);
        cache.set(context.cacheKey, validated);
        return event.copyWith(result: validated);
      }
      return event;
    });
  }

  Future<void> invalidateCache(ReadingContext context) =>
      cache.invalidate(context.cacheKey);

  InterpretationRequest buildRequest(ReadingContext context) =>
      _buildRequest(
        context: context,
        mode: InterpretationMode.standard,
      );

  Future<InterpretationResult> _executeWithRetry(
    InterpretationRequest request,
  ) async {
    Object? lastError;
    for (var attempt = 1; attempt <= _retryPolicy.maxAttempts; attempt++) {
      try {
        final result = await executor
            .execute(request)
            .timeout(
              request.timeout,
              onTimeout: () => throw const InterpretationException(
                type: InterpretationFailureType.timeout,
                message: ResilienceCopy.interpretationTimeout,
              ),
            );

        final validated = _validateResult(result);
        await cache.set(request.context.cacheKey, validated);
        return validated;
      } on InterpretationException catch (e) {
        lastError = e;
        debugPrint('[InterpretationEngine] Attempt $attempt failed: $e');
        if (!e.retryable || attempt >= _retryPolicy.maxAttempts) rethrow;
        await Future<void>.delayed(_retryPolicy.delayForAttempt(attempt));
      } catch (e, stackTrace) {
        lastError = e;
        debugPrint(
          '[InterpretationEngine] Attempt $attempt unexpected error: $e\n$stackTrace',
        );
        if (!executor.isOnline) {
          throw InterpretationException(
            type: InterpretationFailureType.offline,
            message: ResilienceCopy.offline,
            cause: e,
          );
        }
        if (attempt >= _retryPolicy.maxAttempts) {
          throw InterpretationException(
            type: InterpretationFailureType.retry,
            message: ResilienceCopy.interpretationFailed,
            cause: e,
          );
        }
        await Future<void>.delayed(_retryPolicy.delayForAttempt(attempt));
      }
    }

    throw InterpretationException(
      type: InterpretationFailureType.retry,
      message: ResilienceCopy.interpretationFailed,
      cause: lastError,
    );
  }

  InterpretationResult _validateResult(InterpretationResult result) {
    if (result.summary.trim().isEmpty) {
      throw const InterpretationException(
        type: InterpretationFailureType.emptyResponse,
        message: 'Yorum özeti boş.',
      );
    }
    if (!_formatter.validate(result)) {
      throw const InterpretationException(
        type: InterpretationFailureType.invalidResponse,
        message: 'Yorum yapısı geçersiz.',
      );
    }
    return result.copyWith(
      rawText: result.rawText ?? _formatter.toMarkdown(result),
    );
  }

  InterpretationRequest _buildRequest({
    required ReadingContext context,
    required InterpretationMode mode,
    bool forceRefresh = false,
  }) {
    final base = InterpretationRequest(
      context: context,
      requestId: 'interp_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      mode: mode,
      forceRefresh: forceRefresh,
    );
    return _promptAdapter.attachPrompt(base);
  }
}

extension on InterpretationStreamEvent {
  InterpretationStreamEvent copyWith({
    InterpretationResult? result,
    double? progress,
  }) {
    return InterpretationStreamEvent(
      phase: phase,
      sectionKey: sectionKey,
      partialText: partialText,
      result: result ?? this.result,
      error: error,
      progress: progress ?? this.progress,
    );
  }
}

/// Factory for default engine wiring.
class InterpretationEngineFactory {
  InterpretationEngineFactory._();

  static InterpretationEngine create({
    required InterpretationCache cache,
    InterpretationExecutor? executor,
  }) {
    return InterpretationEngine(
      executor: executor ?? LocalInterpretationExecutor(),
      cache: cache,
    );
  }
}
