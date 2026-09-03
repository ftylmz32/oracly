/// Settings load resolves to success or recoverable error - never endless.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/domain/repositories/settings_repository.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/services/settings_service.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_screen.dart';
import 'package:oracly_new/shared/widgets/oracly_error_state.dart';
import 'package:oracly_new/shared/widgets/oracly_skeleton_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';
import 'settings_test_fakes.dart';

class _FlakySettingsRepo implements SettingsRepository {
  _FlakySettingsRepo({this.shouldFail = false});

  bool shouldFail;
  int loads = 0;
  PersonalizationSettings saved = const PersonalizationSettings(language: 'tr');

  @override
  Future<PersonalizationSettings> load() async {
    loads++;
    if (shouldFail) {
      throw StateError('settings unavailable');
    }
    return saved;
  }

  @override
  Future<void> save(PersonalizationSettings settings) async {
    saved = settings;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  Future<void> pumpSettings(
    WidgetTester tester, {
    required LocalStorage storage,
    required SettingsService service,
    Size surface = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          settingsServiceProvider.overrideWithValue(service),
          oraclySoundServiceProvider.overrideWithValue(SilentSound()),
          oraclyTtsProvider.overrideWithValue(SilentTts()),
        ],
        child: const MaterialApp(home: SettingsReferenceScreen()),
      ),
    );
  }

  testWidgets('successful load leaves skeleton', (tester) async {
    SharedPreferences.setMockInitialValues(settingsTestLanguagePrefs);
    final storage = await LocalStorage.open();
    final repo = _FlakySettingsRepo();
    await pumpSettings(
      tester,
      storage: storage,
      service: SettingsService(repo),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byType(OraclySkeletonLoader), findsNothing);
    expect(find.byType(OraclyErrorState), findsNothing);
    expect(repo.loads, greaterThanOrEqualTo(1));
  });

  testWidgets('load failure shows retryable error not endless skeleton', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(settingsTestLanguagePrefs);
    final storage = await LocalStorage.open();
    final repo = _FlakySettingsRepo(shouldFail: true);
    await pumpSettings(
      tester,
      storage: storage,
      service: SettingsService(repo),
      surface: const Size(320, 568),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byType(OraclySkeletonLoader), findsNothing);
    expect(find.byType(OraclyErrorState), findsOneWidget);
    expect(find.text(ResilienceCopy.settingsLoadFailed), findsOneWidget);
    expect(find.text(ResilienceCopy.retryAction), findsOneWidget);
  });

  testWidgets('retry succeeds after prior failure', (tester) async {
    SharedPreferences.setMockInitialValues(settingsTestLanguagePrefs);
    final storage = await LocalStorage.open();
    final repo = _FlakySettingsRepo(shouldFail: true);
    await pumpSettings(
      tester,
      storage: storage,
      service: SettingsService(repo),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byType(OraclyErrorState), findsOneWidget);

    repo.shouldFail = false;
    await tester.tap(find.text(ResilienceCopy.retryAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byType(OraclyErrorState), findsNothing);
    expect(find.byType(OraclySkeletonLoader), findsNothing);
    expect(repo.loads, greaterThanOrEqualTo(2));
  });

  testWidgets('repeated retry taps create fresh load attempts', (tester) async {
    SharedPreferences.setMockInitialValues(settingsTestLanguagePrefs);
    final storage = await LocalStorage.open();
    final repo = _FlakySettingsRepo(shouldFail: true);
    await pumpSettings(
      tester,
      storage: storage,
      service: SettingsService(repo),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final before = repo.loads;
    await tester.tap(find.text(ResilienceCopy.retryAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.text(ResilienceCopy.retryAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(repo.loads, greaterThan(before));
    expect(find.byType(OraclyErrorState), findsOneWidget);
  });
}
