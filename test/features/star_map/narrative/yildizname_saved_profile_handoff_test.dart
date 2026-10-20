/// Yıldızname uses what the person already gave at sign-up, asks only for
/// what is genuinely missing, and never carries one account into another.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_birth_chart_repository.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/birth_chart/astronomy/evidence_aware_natal_calculator.dart';
import 'package:oracly_new/features/birth_chart/data/pending_birth_profile_store.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_profile_gaps.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_timezone_status.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/models/chart_fidelity.dart';
import 'package:oracly_new/features/birth_chart/services/birth_chart_experience_service.dart';
import 'package:oracly_new/features/onboarding/services/onboarding_birth_profile.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan_builder.dart';

const _ownerA = 'owner-a';
const _ownerB = 'owner-b';

BirthChartExperienceService _service(LocalStorage storage) =>
    BirthChartExperienceService(
      repository: LocalBirthChartRepository.live(storage),
      pending: PendingBirthProfileStore(storage),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('onboarding answers become a real chart profile', () {
    test('a picked city keeps coordinates and timezone', () {
      final p = OnboardingBirthProfile.build(
        birthDate: DateTime(1992, 4, 5),
        birthPlace: 'İstanbul',
        birthTime: DateTime(1992, 4, 5, 14, 30),
        birthTimeKnown: true,
      );
      expect(p.birthPlaceId, 'istanbul');
      expect(p.latitude, isNotNull);
      expect(p.timezoneId, 'Europe/Istanbul');
      expect(p.timezoneResolutionStatus, BirthTimezoneStatus.resolved);
      expect(p.hasKnownTime, isTrue);
      expect(
        EvidenceAwareNatalChartCalculator().fidelityFor(p),
        ChartCalculationFidelity.fullNatalEphemeris,
      );
    });

    test('unknown birth time keeps the reduced chart, never a guessed hour',
        () {
      final p = OnboardingBirthProfile.build(
        birthDate: DateTime(1988, 4, 12),
        birthPlace: 'Ankara',
        birthTime: DateTime(1988, 4, 12, 9),
        birthTimeKnown: false,
      );
      expect(p.birthTime, isNull);
      expect(p.hasKnownTime, isFalse);
      expect(
        EvidenceAwareNatalChartCalculator().fidelityFor(p),
        ChartCalculationFidelity.reducedNatal,
      );
    });

    test('no city is an open question, not a fake place', () {
      final p = OnboardingBirthProfile.build(birthDate: DateTime(1990, 1, 1));
      expect(p.birthPlace, isEmpty);
      expect(p.birthPlaceUnknownConfirmed, isFalse);
      expect(BirthProfileGaps.needsPlace(p), isTrue);
    });
  });

  group('only genuinely missing information is asked for', () {
    test('complete profiles and explicit "no place" are never asked again',
        () {
      final full = OnboardingBirthProfile.build(
        birthDate: DateTime(1992, 4, 5),
        birthPlace: 'İstanbul',
      );
      expect(BirthProfileGaps.needsPlace(full), isFalse);
      final declined = BirthProfile(
        birthDate: DateTime(1990, 1, 1),
        birthPlace: '',
        birthPlaceUnknownConfirmed: true,
      );
      expect(BirthProfileGaps.needsPlace(declined), isFalse);
    });
  });

  group('the saved profile reaches the narrative engine', () {
    test('sign-up data opens a narrative plan without a second form', () {
      final profile = OnboardingBirthProfile.build(
        birthDate: DateTime(1988, 4, 12),
        birthPlace: 'Ankara',
      );
      final chart = EvidenceAwareNatalChartCalculator().calculate(profile);
      final plan = YildiznameLivePlanBuilder.build(
        featureEnabled: true,
        ownerId: _ownerA,
        chart: chart,
        languageCode: 'tr',
        addressName: 'Mehmet',
      );
      expect(plan.kind, YildiznameLivePlanKind.narrativeReduced);
      final request = plan.request!;
      expect(request.addressName, 'Mehmet');
      final sun = request.placements.firstWhere((p) => p.body == 'sun');
      expect(sun.sign, 'aries');
      // Without a birth time nothing time-dependent is sent.
      expect(request.angles, isEmpty);
      expect(request.houses, isEmpty);
    });
  });

  group('owner timing and pending adoption', () {
    test('a repository built before the first owner sees that owner', () async {
      final storage = LocalStorage.ephemeral();
      final repo = LocalBirthChartRepository.live(storage);
      await expectLater(
        repo.getLatest(),
        throwsA(isA<BirthChartOwnerUnavailableException>()),
      );
      // First owner commit on a fresh install: no epoch bump happens.
      await storage.setString(UserLocalDataIsolation.ownerKey, _ownerA);
      expect(await repo.getLatest(), isNull);
      final service = BirthChartExperienceService(repository: repo);
      await service.generate(OnboardingBirthProfile.build(
        birthDate: DateTime(1992, 4, 5),
        birthPlace: 'İstanbul',
      ));
      expect((await repo.getLatest())?.ownerId, _ownerA);
    });

    test('answers saved before any owner are adopted once, then cleared',
        () async {
      final storage = LocalStorage.ephemeral();
      final pending = PendingBirthProfileStore(storage);
      final profile = OnboardingBirthProfile.build(
        birthDate: DateTime(1992, 4, 5),
        birthPlace: 'İstanbul',
        birthTime: DateTime(1992, 4, 5, 14, 30),
        birthTimeKnown: true,
      );
      await pending.save(profile);

      final service = _service(storage);
      await expectLater(
        service.adoptPendingProfile(),
        throwsA(isA<BirthChartOwnerUnavailableException>()),
      );
      expect(pending.read(), isNotNull, reason: 'kept until an owner exists');

      await storage.setString(UserLocalDataIsolation.ownerKey, _ownerA);
      final loaded = await service.loadSaved();
      expect(loaded.status, BirthChartLoadStatus.loaded);
      expect(loaded.chart!.profile.birthPlaceId, 'istanbul');
      expect(loaded.chart!.profile.hasKnownTime, isTrue);
      expect(pending.read(), isNull);
      expect(await service.adoptPendingProfile(), isFalse);
    });

    test('an existing chart is never overwritten by stale pending answers',
        () async {
      final storage = LocalStorage.ephemeral();
      await storage.setString(UserLocalDataIsolation.ownerKey, _ownerA);
      final service = _service(storage);
      await service.generate(OnboardingBirthProfile.build(
        birthDate: DateTime(1995, 10, 20),
        birthPlace: 'İzmir',
      ));
      await PendingBirthProfileStore(storage).save(
        OnboardingBirthProfile.build(birthDate: DateTime(1980, 1, 1)),
      );
      expect(await service.adoptPendingProfile(), isFalse);
      final chart = await service.loadSavedChart();
      expect(chart!.profile.birthDate, DateTime(1995, 10, 20));
    });
  });

  group('account switch isolation', () {
    test('account B never reads account A birth data', () async {
      final storage = LocalStorage.ephemeral();
      await storage.setString(UserLocalDataIsolation.ownerKey, _ownerA);
      final repo = LocalBirthChartRepository.live(storage);
      await BirthChartExperienceService(repository: repo).generate(
        OnboardingBirthProfile.build(
          birthDate: DateTime(1992, 4, 5),
          birthPlace: 'İstanbul',
        ),
      );
      // The same live repository, after the owner marker moves to B.
      await storage.setString(UserLocalDataIsolation.ownerKey, _ownerB);
      expect(await repo.getLatest(), isNull);
    });

    test('the account wipe removes pending birth answers and the name',
        () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      await PendingBirthProfileStore(storage).save(
        OnboardingBirthProfile.build(birthDate: DateTime(1992, 4, 5)),
      );
      await storage.setString('profile_name', 'Ayşe');
      final result = await UserLocalDataWipe.run(
        storage,
        secureStorage: InMemorySecureStorage(),
      );
      // File-image steps need platform paths; only key steps matter here.
      expect(
        result.failedOperations,
        isNot(contains(PendingBirthProfileStore.storageKey)),
      );
      expect(storage.getString(PendingBirthProfileStore.storageKey), isNull);
      expect(storage.getString('profile_name'), isNull);
    });
  });
}
