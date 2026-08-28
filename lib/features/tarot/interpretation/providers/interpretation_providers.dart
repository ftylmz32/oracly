/// OR-1180 — Interpretation pipeline Riverpod providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../features/premium/models/personalization_models.dart';
import '../cache/interpretation_cache.dart';
import '../executors/local_interpretation_executor.dart';
import '../formatters/interpretation_formatter.dart';
import '../services/interpretation_engine.dart';
import '../services/interpretation_prompt_adapter.dart';

final interpretationCacheProvider = Provider<InterpretationCache>((ref) {
  return LocalInterpretationCache(ref.watch(localStorageProvider));
});

final interpretationFormatterProvider = Provider<InterpretationFormatter>((ref) {
  return const InterpretationFormatter();
});

final interpretationPromptAdapterProvider =
    Provider<InterpretationPromptAdapter>((ref) {
  return InterpretationPromptAdapter();
});

final interpretationEngineProvider = Provider<InterpretationEngine>((ref) {
  final personality =
      ref.watch(settingsProvider).value?.aiPersonality ?? AiPersonality.mystical;
  return InterpretationEngine(
    executor: LocalInterpretationExecutor(
      formatter: ref.watch(interpretationFormatterProvider),
    ),
    cache: ref.watch(interpretationCacheProvider),
    aiPersonality: personality,
  );
});
