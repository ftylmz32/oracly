import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_birth_chart_repository.dart';
import 'package:oracly_new/features/birth_chart/controllers/birth_chart_controller.dart';
import 'package:oracly_new/features/birth_chart/copy/birth_chart_copy.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_record_mapper.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/services/birth_chart_experience_service.dart';
import 'package:oracly_new/features/birth_chart/services/natal_chart_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<({LocalStorage storage, BirthChartExperienceService service})>
    _createService() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.open();
  final repository = LocalBirthChartRepository(storage);
  final service = BirthChartExperienceService(repository: repository);
  return (storage: storage, service: service);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BirthChartExperienceService persistence recovery', () {
    test('repairs saved charts missing insights', () async {
      final env = await _createService();
      final incomplete = const NatalChartCalculator().calculate(
        BirthProfile(
          birthDate: DateTime(1995, 8, 15),
          birthPlace: 'İstanbul',
          birthTimeKnown: false,
        ),
      );
      expect(incomplete.insights, isEmpty);

      final repository = LocalBirthChartRepository(env.storage);
      await repository.save(BirthChartRecordMapper.toRecord(incomplete));

      final result = await env.service.loadSaved();

      expect(result.status, BirthChartLoadStatus.loaded);
      expect(result.chart?.insights, isNotEmpty);
      expect(result.chart?.moon, isNull);
      expect(result.chart?.planets, isEmpty);
    });

    test('clears corrupt json and returns profile hint when possible', () async {
      final env = await _createService();
      await env.storage.setString(
        'birth_chart_latest',
        '{"id":"x","createdAt":"2020-01-01T00:00:00.000","payload":{}}',
      );

      final result = await env.service.loadSaved();

      expect(result.status, BirthChartLoadStatus.clearedCorrupt);
      expect(await env.service.loadSavedChart(), isNull);
    });

    test('clearSavedData removes persisted chart', () async {
      final env = await _createService();
      await env.service.generate(
        BirthProfile(
          birthDate: DateTime(1992, 11, 10),
          birthPlace: 'İzmir',
          birthTime: DateTime(1992, 11, 10, 8, 0),
          birthTimeKnown: true,
        ),
      );

      await env.service.clearSavedData();

      expect(await env.service.loadSavedChart(), isNull);
    });
  });

  group('BirthChartController', () {
    test('loadSaved repairs incomplete charts and enters journey', () async {
      final env = await _createService();
      final incomplete = const NatalChartCalculator().calculate(
        BirthProfile(
          birthDate: DateTime(1990, 3, 25),
          birthPlace: 'Ankara',
          birthTimeKnown: false,
        ),
      );
      final repository = LocalBirthChartRepository(env.storage);
      await repository.save(BirthChartRecordMapper.toRecord(incomplete));

      final controller = BirthChartController(env.service);
      await controller.loadSaved();

      expect(controller.isInitializing, isFalse);
      expect(controller.phase, BirthChartPhase.journey);
      expect(controller.hasRenderableJourney, isTrue);
    });

    test('restartOnboarding clears SharedPreferences trap', () async {
      final env = await _createService();
      final incomplete = const NatalChartCalculator().calculate(
        BirthProfile(
          birthDate: DateTime(1990, 3, 25),
          birthPlace: 'Ankara',
          birthTimeKnown: false,
        ),
      );
      final repository = LocalBirthChartRepository(env.storage);
      await repository.save(BirthChartRecordMapper.toRecord(incomplete));

      final controller = BirthChartController(env.service);
      await controller.loadSaved();
      expect(controller.phase, BirthChartPhase.journey);

      await controller.restartOnboarding();

      expect(controller.phase, BirthChartPhase.onboarding);
      expect(controller.statusMessage, BirthChartCopy.savedDataCleared);
      expect(await env.service.loadSavedChart(), isNull);
      expect(controller.onboardingProfileHint?.birthPlace, 'Ankara');
    });

    test('beginEdit keeps saved chart until a new generate', () async {
      final env = await _createService();
      final controller = BirthChartController(env.service);
      await controller.generate(
        BirthProfile(
          birthDate: DateTime(1992, 11, 10),
          birthPlace: 'İzmir',
          birthTime: DateTime(1992, 11, 10, 8, 0),
          birthTimeKnown: true,
        ),
      );
      expect(controller.phase, BirthChartPhase.journey);

      controller.beginEdit();
      expect(controller.phase, BirthChartPhase.onboarding);
      expect(controller.isEditing, isTrue);
      expect(await env.service.loadSavedChart(), isNotNull);

      controller.cancelEdit();
      expect(controller.phase, BirthChartPhase.journey);
      expect(controller.isEditing, isFalse);
    });

    test('generate completes journey with insights', () async {
      final env = await _createService();
      final controller = BirthChartController(env.service);

      final generateFuture = controller.generate(
        BirthProfile(
          birthDate: DateTime(1992, 11, 10),
          birthPlace: 'İzmir',
          birthTime: DateTime(1992, 11, 10, 8, 0),
          birthTimeKnown: true,
        ),
      );

      expect(controller.phase, BirthChartPhase.generating);

      await generateFuture;

      expect(controller.phase, BirthChartPhase.journey);
      expect(controller.hasRenderableJourney, isTrue);
      expect(controller.chart?.insights, isNotEmpty);
    });

    test('loadSaved does not overwrite active generation', () async {
      final env = await _createService();
      final controller = BirthChartController(env.service);
      final profile = BirthProfile(
        birthDate: DateTime(1992, 11, 10),
        birthPlace: 'İzmir',
        birthTime: DateTime(1992, 11, 10, 8, 0),
        birthTimeKnown: true,
      );

      final generateFuture = controller.generate(profile);
      expect(controller.phase, BirthChartPhase.generating);

      await controller.loadSaved();

      await generateFuture;

      expect(controller.phase, BirthChartPhase.journey);
      expect(controller.hasRenderableJourney, isTrue);
    });
  });
}
