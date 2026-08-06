/// SPRINT-002 — Birth chart Riverpod providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../ai/providers/ai_providers.dart';
import '../controllers/birth_chart_controller.dart';
import '../services/birth_chart_experience_service.dart';

final birthChartExperienceServiceProvider =
    Provider<BirthChartExperienceService>((ref) {
  return BirthChartExperienceService(
    repository: ref.watch(birthChartRepositoryProvider),
    aiRepository: ref.watch(astrologyAIRepositoryProvider),
  );
});

final birthChartControllerProvider =
    ChangeNotifierProvider.autoDispose<BirthChartController>((ref) {
  final controller = BirthChartController(
    ref.watch(birthChartExperienceServiceProvider),
  );
  controller.loadSaved();
  return controller;
});
