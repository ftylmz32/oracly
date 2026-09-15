/// Palm feature providers — reuse coffee image input, fail-closed vision.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../ai/production/oracly_ai_providers.dart';
import '../../coffee/providers/coffee_providers.dart';
import '../../../core/reading_version/providers/reading_version_providers.dart';
import '../../reading_operation/providers/reading_live_provider.dart';
import '../controllers/palm_reading_controller.dart';
import '../data/palm_reading_store.dart';
import '../services/openai_palm_analysis.dart';
import '../services/palm_analysis_port.dart';
import '../services/palm_experience_service.dart';
import '../../../core/memory/oracly_memory.dart';
import '../../gems/providers/gem_providers.dart';

final palmReadingStoreProvider = Provider<PalmReadingStore>((ref) {
  return PalmReadingStore(
    ref.watch(localStorageProvider),
    memory: ref.watch(oraclyMemoryStoreProvider),
  );
});

final palmAnalysisProvider = Provider<PalmAnalysisPort>((ref) {
  // firstName only. Recurring discovery labels are not proven relevant
  // to this palm, so they are not sent. A future caller may still pass
  // relevantThemes on OpenAiPalmAnalysis when relevance is real.
  return OpenAiPalmAnalysis(
    ai: ref.watch(oraclyAiServiceProvider),
    firstName: () => ref.read(userProfileProvider).valueOrNull?.name,
    memorySummary: (themes) => ref
        .read(oraclyMemoryRetrieverProvider)
        .forInterpretation(
          query: themes.join(' '),
          currentType: OraclyReadingType.palm,
        ),
  );
});

final palmExperienceServiceProvider = Provider<PalmExperienceService>((ref) {
  return PalmExperienceService(
    analysis: ref.watch(palmAnalysisProvider),
    store: ref.watch(palmReadingStoreProvider),
    versions: ref.watch(readingVersionServiceProvider),
  );
});

/// Session controller must survive chamber camera push + long AI analyze.
/// autoDispose was dropping mid-flight success (phase never reached result).
final palmReadingControllerProvider =
    ChangeNotifierProvider<PalmReadingController>((ref) {
      final controller = PalmReadingController(
        experience: ref.watch(palmExperienceServiceProvider),
        images: ref.watch(coffeeImageInputProvider),
        live: ref.watch(readingFeatureRunnerProvider),
        pendingStore: ref.watch(readingPendingOperationStoreProvider),
        acceptAuthoritativeBalance: ref
            .read(gemWalletProvider)
            .acceptAuthoritativeBalance,
      );
      // BATCH 5F: recover any active operation on controller reconstruction
      // (fresh app process) — the wait/processing/ready/failed state must
      // survive an app kill even though this controller instance is new.
      controller.recoverActive();
      return controller;
    });
