/// Tasks 50–55 — owner adopt / mismatch / unavailable / no wipe.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_birth_chart_repository.dart';
import 'package:oracly_new/core/domain/models/birth_chart_record.dart';
import 'package:oracly_new/features/birth_chart/services/birth_chart_experience_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_birth_owner.dart';

BirthChartRecord _record({String? ownerId}) => BirthChartRecord(
      id: 'chart_1',
      createdAt: DateTime(2020, 1, 1),
      ownerId: ownerId,
      payload: {
        'id': 'chart_1',
        'profile': {
          'birthDate': '1990-03-25T00:00:00.000',
          'birthPlace': 'Ankara',
          'birthTimeKnown': false,
        },
        'sun': {'id': 'sun', 'sign': 'aries', 'degree': 0, 'house': 0},
        'planets': [],
        'houses': [],
        'aspects': [],
        'elementBalance': {'fire': 1, 'earth': 0, 'air': 0, 'water': 0},
        'dominantEnergy': {
          'primaryElement': 'fire',
          'primaryModality': 'cardinal',
          'label': 'x',
          'summary': 'y',
        },
        'lifeThemes': [],
        'insights': [],
        'generatedAt': '2020-01-01T00:00:00.000',
        'precision': 'partialNoTime',
        'fidelity': 'tropicalSunSign',
      },
    );

Future<LocalStorage> _open() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStorage.open();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Task 50 adopts ownerless record to A once', () async {
    final storage = await _open();
    await storage.setString(
      LocalBirthChartRepository.storageKey,
      jsonEncode(_record().toJson()),
    );
    final got = await testBirthChartRepo(storage).getLatest();
    expect(got?.ownerId, kTestBirthOwnerA);
    expect(got?.payload['id'], 'chart_1');
    final again = await testBirthChartRepo(storage).getLatest();
    expect(again?.ownerId, kTestBirthOwnerA);
  });

  test('Task 51 unresolved owner does not adopt or wipe', () async {
    final storage = await _open();
    final raw = jsonEncode(_record().toJson());
    await storage.setString(LocalBirthChartRepository.storageKey, raw);
    final repo = LocalBirthChartRepository(storage, ownerId: null);
    expect(
      () => repo.getLatest(),
      throwsA(isA<BirthChartOwnerUnavailableException>()),
    );
    expect(storage.getString(LocalBirthChartRepository.storageKey), raw);
  });

  test('Task 52 A→B isolation: no leak, no wipe, no overwrite', () async {
    final storage = await _open();
    await testBirthChartRepo(storage).save(_record(ownerId: kTestBirthOwnerA));
    final raw = storage.getString(LocalBirthChartRepository.storageKey)!;
    final b = testBirthChartRepo(storage, ownerId: kTestBirthOwnerB);
    expect(await b.getLatest(), isNull);
    await b.save(_record(ownerId: kTestBirthOwnerB));
    await b.clearLatest();
    expect(storage.getString(LocalBirthChartRepository.storageKey), raw);
  });

  test('Task 53 account switch wipe then B starts clean', () async {
    final storage = await _open();
    await testBirthChartRepo(storage).save(_record(ownerId: kTestBirthOwnerA));
    await storage.remove(LocalBirthChartRepository.storageKey);
    await storage.setString(UserLocalDataIsolation.ownerKey, kTestBirthOwnerB);
    final b = testBirthChartRepo(storage, ownerId: kTestBirthOwnerB);
    expect(await b.getLatest(), isNull);
    await b.save(_record(ownerId: kTestBirthOwnerB));
    expect((await b.getLatest())?.ownerId, kTestBirthOwnerB);
  });

  test('Task 54 loadSaved ownerUnavailable leaves key intact', () async {
    final storage = await _open();
    final raw = jsonEncode(_record(ownerId: kTestBirthOwnerA).toJson());
    await storage.setString(LocalBirthChartRepository.storageKey, raw);
    final repo = LocalBirthChartRepository(storage, ownerId: null);
    final service = BirthChartExperienceService(repository: repo);
    final result = await service.loadSaved();
    expect(result.status, BirthChartLoadStatus.ownerUnavailable);
    expect(storage.getString(LocalBirthChartRepository.storageKey), raw);
  });

  test('Task 55 repo A instance cannot surface as B chart', () async {
    final storage = await _open();
    final a = testBirthChartRepo(storage);
    await a.save(_record(ownerId: kTestBirthOwnerA));
    final b = testBirthChartRepo(storage, ownerId: kTestBirthOwnerB);
    expect(await b.getLatest(), isNull);
    expect((await a.getLatest())?.ownerId, kTestBirthOwnerA);
  });
}
