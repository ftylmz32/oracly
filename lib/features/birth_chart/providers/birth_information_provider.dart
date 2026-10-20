/// One birth-info read path — same store as Birth Chart persistence.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/data/repositories/local_birth_chart_repository.dart';
import '../../../core/domain/models/birth_chart_record.dart';
import '../astronomy/natal_chart_evidence.dart';
import '../data/birth_chart_record_mapper.dart';
import '../models/birth_profile.dart';
import '../models/zodiac_sign_id.dart';
import 'birth_chart_providers.dart';

/// Saved chart record; adopts birth answers onboarding could not save yet
/// because no owner existed, so the user is never asked twice.
Future<BirthChartRecord?> _latestRecord(Ref ref) async {
  final repo = ref.watch(birthChartRepositoryProvider);
  final record = await repo.getLatest();
  if (record != null) return record;
  final adopted =
      await ref.read(birthChartExperienceServiceProvider).adoptPendingProfile();
  return adopted ? repo.getLatest() : null;
}

/// Saved birth date / time / place, or null when none exists / owner unavailable.
final birthInformationProvider = FutureProvider<BirthProfile?>((ref) async {
  try {
    final record = await _latestRecord(ref);
    if (record == null) return null;
    return BirthChartRecordMapper.fromRecord(record).profile;
  } on BirthChartOwnerUnavailableException {
    return null;
  } catch (_) {
    return null;
  }
});

/// Tropical sun sign from the saved birth date — not a full natal.
final savedSunSignProvider = Provider<ZodiacSignId?>((ref) {
  final profile = ref.watch(birthInformationProvider).valueOrNull;
  if (profile == null) return null;
  return ZodiacSignId.fromDate(profile.birthDate);
});

/// Calculated natal evidence of the saved chart, or null when none exists.
final savedNatalEvidenceProvider =
    FutureProvider<NatalChartEvidence?>((ref) async {
  try {
    final record = await _latestRecord(ref);
    if (record == null) return null;
    return BirthChartRecordMapper.fromRecord(record).natalEvidence;
  } on BirthChartOwnerUnavailableException {
    return null;
  } catch (_) {
    return null;
  }
});
