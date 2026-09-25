/// One birth-info read path — same store as Birth Chart persistence.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/data/repositories/local_birth_chart_repository.dart';
import '../data/birth_chart_record_mapper.dart';
import '../models/birth_profile.dart';
import '../models/zodiac_sign_id.dart';

/// Saved birth date / time / place, or null when none exists / owner unavailable.
final birthInformationProvider = FutureProvider<BirthProfile?>((ref) async {
  try {
    final record = await ref.watch(birthChartRepositoryProvider).getLatest();
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
