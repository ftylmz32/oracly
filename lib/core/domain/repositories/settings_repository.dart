/// OR-1100 — Settings repository interface.
library;

import '../../../features/premium/models/personalization_models.dart';

abstract class SettingsRepository {
  Future<PersonalizationSettings> load();
  Future<void> save(PersonalizationSettings settings);
}
