/// Palm feature providers — reuse coffee image input, fail-closed vision.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../ai/production/oracly_ai_providers.dart';
import '../../coffee/providers/coffee_providers.dart';
import '../../../core/reading_version/providers/reading_version_providers.dart';
import '../controllers/palm_reading_controller.dart';
import '../data/palm_reading_store.dart';
import '../services/openai_palm_analysis.dart';
import '../services/palm_analysis_port.dart';
import '../services/palm_experience_service.dart';
import '../services/unavailable_palm_analysis.dart';

final palmReadingStoreProvider = Provider<PalmReadingStore>((ref) {
  return PalmReadingStore(ref.watch(localStorageProvider));
});

final palmAnalysisProvider = Provider<PalmAnalysisPort>((ref) {
  final ai = ref.watch(oraclyAiServiceProvider);
  if (ai.visionAvailable) return OpenAiPalmAnalysis(ai: ai);
  return const UnavailablePalmAnalysis();
});

final palmExperienceServiceProvider = Provider<PalmExperienceService>((ref) {
  return PalmExperienceService(
    analysis: ref.watch(palmAnalysisProvider),
    store: ref.watch(palmReadingStoreProvider),
    versions: ref.watch(readingVersionServiceProvider),
  );
});

final palmReadingControllerProvider =
    ChangeNotifierProvider.autoDispose<PalmReadingController>((ref) {
  return PalmReadingController(
    experience: ref.watch(palmExperienceServiceProvider),
    images: ref.watch(coffeeImageInputProvider),
  );
});
