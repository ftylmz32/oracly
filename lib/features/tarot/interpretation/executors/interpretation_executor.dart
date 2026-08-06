/// OR-1180 — Interpretation executor contract (AI-ready).
library;

import '../models/interpretation_request.dart';
import '../models/interpretation_result.dart';
import '../models/interpretation_stream_event.dart';

abstract class InterpretationExecutor {
  Future<InterpretationResult> execute(InterpretationRequest request);

  Stream<InterpretationStreamEvent> executeStream(InterpretationRequest request);

  bool get isOnline => true;
}
