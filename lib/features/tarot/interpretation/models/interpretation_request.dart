/// OR-1180 — Structured interpretation request envelope.
library;

import 'package:flutter/foundation.dart';

import '../../../prompt_engine/models/prompt_request.dart';
import 'reading_context.dart';

enum InterpretationMode { standard, regenerate, streaming }

@immutable
class InterpretationRequest {
  const InterpretationRequest({
    required this.context,
    required this.requestId,
    required this.createdAt,
    this.mode = InterpretationMode.standard,
    this.promptRequest,
    this.forceRefresh = false,
    this.timeout = const Duration(seconds: 45),
    this.maxRetries = 2,
  });

  final ReadingContext context;
  final String requestId;
  final DateTime createdAt;
  final InterpretationMode mode;
  final PromptRequest? promptRequest;
  final bool forceRefresh;
  final Duration timeout;
  final int maxRetries;

  InterpretationRequest copyWith({
    PromptRequest? promptRequest,
    InterpretationMode? mode,
    bool? forceRefresh,
  }) {
    return InterpretationRequest(
      context: context,
      requestId: requestId,
      createdAt: createdAt,
      mode: mode ?? this.mode,
      promptRequest: promptRequest ?? this.promptRequest,
      forceRefresh: forceRefresh ?? this.forceRefresh,
      timeout: timeout,
      maxRetries: maxRetries,
    );
  }
}
