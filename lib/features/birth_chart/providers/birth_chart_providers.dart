/// Birth chart Riverpod providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../controllers/birth_chart_controller.dart';
import '../services/birth_chart_experience_service.dart';
import '../../discovery_journal/providers/discovery_journal_providers.dart';
import '../../personal_discovery/providers/personal_discovery_providers.dart';
import 'birth_information_provider.dart';

final birthChartExperienceServiceProvider =
    Provider<BirthChartExperienceService>((ref) {
  return BirthChartExperienceService(
    repository: ref.watch(birthChartRepositoryProvider),
  );
});

final birthChartControllerProvider =
    ChangeNotifierProvider.autoDispose<BirthChartController>((ref) {
  final controller = BirthChartController(
    ref.watch(birthChartExperienceServiceProvider),
  );
  void syncBirthInfo() {
    ref.invalidate(birthInformationProvider);
    ref.invalidate(personalDiscoveryProfileProvider);
    ref.invalidate(discoveryJournalEntriesProvider);
  }
  controller.addListener(syncBirthInfo);
  ref.onDispose(() => controller.removeListener(syncBirthInfo));
  controller.loadSaved();
  return controller;
});
