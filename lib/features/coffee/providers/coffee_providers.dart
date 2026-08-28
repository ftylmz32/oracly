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

final coffeeReadingStoreProvider = Provider<CoffeeReadingStore>((ref) {
  return CoffeeReadingStore(ref.watch(localStorageProvider));
});

final coffeeImageInputProvider = Provider<CoffeeImageInputPort>((ref) {
  return ImagePickerCoffeeInput();
});

/// Always the real vision adapter. CTA stays tappable with a photo; failures
/// surface as error/retry — never a permanent UnavailableSoulMate-style lock.
final coffeeAnalysisProvider = Provider<CoffeeAnalysisPort>((ref) {
  return OpenAiCoffeeAnalysis(ai: ref.watch(oraclyAiServiceProvider));
});

final coffeeExperienceServiceProvider = Provider<CoffeeExperienceService>((ref) {
  return CoffeeExperienceService(
    store: ref.watch(coffeeReadingStoreProvider),
    analysis: ref.watch(coffeeAnalysisProvider),
    versions: ref.watch(readingVersionServiceProvider),
  );
});

final coffeeReadingControllerProvider =
    ChangeNotifierProvider<CoffeeReadingController>((ref) {
  final controller = CoffeeReadingController(
    experience: ref.watch(coffeeExperienceServiceProvider),
    images: ref.watch(coffeeImageInputProvider),
  );
  controller.loadHistory();
  return controller;
});
