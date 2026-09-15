/// Coffee feature providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../ai/production/oracly_ai_providers.dart';
import '../../../core/reading_version/providers/reading_version_providers.dart';
import '../controllers/coffee_reading_controller.dart';
import '../data/coffee_reading_store.dart';
import '../services/coffee_analysis_port.dart';
import '../services/coffee_experience_service.dart';
import '../services/coffee_image_input_port.dart';
import '../services/image_picker_coffee_input.dart';
import '../services/openai_coffee_analysis.dart';
import '../../reading_operation/providers/reading_live_provider.dart';
import '../../../core/memory/oracly_memory.dart';
import '../../gems/providers/gem_providers.dart';

final coffeeReadingStoreProvider = Provider<CoffeeReadingStore>((ref) {
  return CoffeeReadingStore(
    ref.watch(localStorageProvider),
    memory: ref.watch(oraclyMemoryStoreProvider),
  );
});

final coffeeImageInputProvider = Provider<CoffeeImageInputPort>((ref) {
  return ImagePickerCoffeeInput();
});

/// Always the real vision adapter. CTA stays tappable with a photo; failures
/// surface as error/retry — never a permanent UnavailableSoulMate-style lock.
final coffeeAnalysisProvider = Provider<CoffeeAnalysisPort>((ref) {
  // firstName only. Recurring discovery labels are not proven relevant
  // to this cup, so they are not sent. A future caller may still pass
  // relevantThemes on OpenAiCoffeeAnalysis when relevance is real.
  return OpenAiCoffeeAnalysis(
    ai: ref.watch(oraclyAiServiceProvider),
    firstName: () => ref.read(userProfileProvider).valueOrNull?.name,
    memorySummary: (themes) => ref
        .read(oraclyMemoryRetrieverProvider)
        .forInterpretation(
          query: themes.join(' '),
          currentType: OraclyReadingType.coffee,
        ),
  );
});

final coffeeExperienceServiceProvider = Provider<CoffeeExperienceService>((ref) {
  return CoffeeExperienceService(
    store: ref.watch(coffeeReadingStoreProvider),
    analysis: ref.watch(coffeeAnalysisProvider),
    versions: ref.watch(readingVersionServiceProvider),
  );
});

/// Session controller must survive chamber camera push + long AI analyze.
/// autoDispose was dropping mid-flight success (phase never reached result).
final coffeeReadingControllerProvider =
    ChangeNotifierProvider<CoffeeReadingController>((ref) {
  final controller = CoffeeReadingController(
    experience: ref.watch(coffeeExperienceServiceProvider),
    images: ref.watch(coffeeImageInputProvider),
    live: ref.watch(readingFeatureRunnerProvider),
    pendingStore: ref.watch(readingPendingOperationStoreProvider),
    acceptAuthoritativeBalance: ref.read(gemWalletProvider).acceptAuthoritativeBalance,
  );
  controller.loadHistory();
  // BATCH 5F: recover any active operation on controller reconstruction
  // (fresh app process) — the wait/processing/ready/failed state must
  // survive an app kill even though this controller instance is new.
  controller.recoverActive();
  return controller;
});
