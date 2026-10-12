/// V3N client integration — the versioned `v3_narrative_v1` result travels
/// wire → CoffeeReading → local store → restart → history reopen → version
/// payload → stable / experimental renderers through the SAME server-gated
/// path as `m2_public_v1`: shape-checked, `overall` kept VERBATIM (paragraph
/// breaks included), never the legacy parser / composer / scrub. Unknown
/// markers still fail closed. Zero provider calls.
///
/// The wire fixture has exactly the shape of the real successful V3N result
/// (`v3NarrativeV1Result`); the narrative text is SYNTHETIC.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/fortune_voice.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/chamber_narrative_block.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/reading_version/models/reading_version_kind.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_payload.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_service.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_store.dart';
import 'package:oracly_new/features/coffee/controllers/coffee_reading_controller.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/models/coffee_result_contract.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_insight_copy.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_result_sections.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_result_stable.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_result_view.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/coffee_fortune_narration.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_result_text.dart';
import 'package:oracly_new/features/coffee/services/openai_coffee_analysis.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/coffee_v3_test_support.dart';
import '../../support/fake_reading_operation_backend.dart';

class _NoImages implements CoffeeImageInputPort {
  @override
  bool get cameraAvailable => false;
  @override
  bool get galleryAvailable => false;
  @override
  Future<CoffeeImagePick?> pickFromCamera() async => null;
  @override
  Future<CoffeeImagePick?> pickFromGallery() async => null;
}

// SYNTHETIC two-paragraph life-meaning narrative (never product copy, never
// a real reading). Paragraph 1 carries a double space and a phrase the legacy
// FortuneVoice.scrub rewrites, so a verbatim path is provable.
const _p1 = 'Yakın zamanda önünde birden fazla seçeneğin belirdiğini '
    'hissedebilirsin;  bunlar ara ara netleşiyor gibi. Gündemindeki bir mesele '
    'yavaş yavaş durulurken içindeki bir istek ön plana çıkabilir.';
const _p2 = 'İçinde biriktirdiklerini paylaşma isteği uyanabilir; söze döktükçe '
    'hafiflediğini fark edebilirsin. Aynı günlerde planladığından biraz farklı '
    'bir yöne dönerken bulman da olası.';
const _narrative = '$_p1\n\n$_p2';

final _persistedAt = DateTime.utc(2026, 10, 11, 22, 40);

Map<String, dynamic> _wire({Map<String, dynamic> override = const {}}) =>
    {...v3NarrativeV1Result(_narrative), ...override};

CoffeeReading _v3n({String id = 'v3n-r1'}) => CoffeeReading(
      id: id,
      createdAt: _persistedAt,
      coffeeResultContract: coffeeV3NarrativeV1ResultContract,
      overall: _narrative,
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: '',
    );

void _expectV3NShape(CoffeeReading r) {
  expect(r.coffeeResultContract, coffeeV3NarrativeV1ResultContract);
  expect(r.isServerGatedV3, isTrue);
  expect(r.isM2PublicV1, isFalse);
  expect(r.overall, _narrative);
  expect(r.visualObservation, '');
  expect(r.love + r.career + r.money + r.nearFuture + r.takeaway, '');
  expect(r.symbols, isEmpty);
  expect(r.imagePath, isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    OraclyL10n.bind('tr');
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    FeatureFlagRuntime.refreshFromRemote(ProductFeatureFlags.defaults());
  });

  test('fixture has the real V3N result shape; legacy scrub WOULD rewrite it', () {
    expect(_wire().keys.toList(), [
      'coffeeResultContract', 'visualObservation', 'overall', 'love', 'career',
      'money', 'nearFuture', 'takeaway', 'symbols',
    ]);
    expect(_narrative.split('\n\n'), [_p1, _p2]);
    expect(FortuneVoice.scrub(_narrative) == _narrative, isFalse);
  });

  test('the contract is known and server-gated alongside m2_public_v1; others fail closed', () {
    expect(coffeeV3NarrativeV1ResultContract, 'v3_narrative_v1');
    expect(serverGatedCoffeeResultContracts,
        {coffeeM2PublicV1ResultContract, coffeeV3NarrativeV1ResultContract});
    expect(parseCoffeeResultContract('v3_narrative_v1'), 'v3_narrative_v1');
    expect(parseCoffeeResultContract(null), isNull);
    for (final unknown in <Object>['v3_narrative_v2', 'V3_NARRATIVE_V1', '', 3]) {
      expect(() => parseCoffeeResultContract(unknown), throwsFormatException,
          reason: '$unknown');
    }
  });

  group('wire restore (OpenAiCoffeeAnalysis.restoreCompleted)', () {
    test('restores verbatim (paragraphs kept), never scrubbed, no provider call', () {
      final ai = NoProviderAi();
      final r = OpenAiCoffeeAnalysis(ai: ai).restoreCompleted(
        resultId: 'v3n-r1',
        persistedAt: _persistedAt,
        result: _wire(),
      );
      _expectV3NShape(r);
      expect(r.id, 'v3n-r1');
      expect(r.createdAt, _persistedAt);
      expect(ai.calls, 0);
    });

    test('a malformed v3_narrative_v1 body fails closed (never reinterpreted as legacy)', () {
      final ai = NoProviderAi();
      final analysis = OpenAiCoffeeAnalysis(ai: ai);
      for (final override in <Map<String, dynamic>>[
        {'overall': '   '},
        {'overall': null},
        {'love': 'x'},
        {'takeaway': 'x'},
        {'symbols': <Object>['kuş']},
        {'coffeeResultContract': 'v3_narrative_v9'},
      ]) {
        expect(
          () => analysis.restoreCompleted(
            resultId: 'v3n-r1',
            persistedAt: _persistedAt,
            result: _wire(override: override),
          ),
          throwsA(isA<CoffeeAnalysisException>()),
          reason: '$override',
        );
      }
      expect(ai.calls, 0);
    });
  });

  group('local JSON and store', () {
    test('marker + exact overall round-trip through jsonEncode', () {
      final back = CoffeeReading.fromJson(
        jsonDecode(jsonEncode(_v3n().toJson())) as Map<String, dynamic>,
      );
      _expectV3NShape(back);
      expect(_v3n().copyWith(love: '').coffeeResultContract,
          coffeeV3NarrativeV1ResultContract);
    });

    test('store keeps the V3N row and skips an unknown-contract row', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);
      await storage.setStringList(CoffeeReadingStore.key, [
        jsonEncode(_v3n(id: 'future').toJson()..['coffeeResultContract'] = 'v3_narrative_v2'),
        jsonEncode(_v3n().toJson()),
      ]);
      final store = CoffeeReadingStore(storage);
      expect(store.byId('future'), isNull);
      _expectV3NShape(store.byId('v3n-r1')!);
      expect(store.all(), hasLength(1));
    });
  });

  group('completed-result flow (CoffeeExperienceService.restoreCompleted)', () {
    test('restore → save → restart → byId exact; a repeated restore never duplicates', () async {
      final ai = NoProviderAi();
      final prefs = await SharedPreferences.getInstance();
      final versions = ReadingVersionService(ReadingVersionStore(LocalStorage(prefs)));
      final service = CoffeeExperienceService(
        store: CoffeeReadingStore(LocalStorage(prefs)),
        analysis: OpenAiCoffeeAnalysis(ai: ai),
        versions: versions,
      );

      _expectV3NShape(await service.restoreCompleted(
          resultId: 'v3n-r1', persistedAt: _persistedAt, result: _wire()));
      // Recovery delivers the same completed result again (e.g. after restart).
      _expectV3NShape(await service.restoreCompleted(
          resultId: 'v3n-r1', persistedAt: _persistedAt, result: _wire()));

      final reloaded = CoffeeReadingStore(LocalStorage(await SharedPreferences.getInstance()));
      expect(reloaded.all(), hasLength(1));
      final saved = reloaded.byId('v3n-r1')!;
      expect(saved.createdAt, _persistedAt);
      _expectV3NShape(saved);

      final group = versions.groupFor('v3n-r1');
      expect(group?.kind, ReadingVersionKind.coffee);
      expect(group!.entries, hasLength(1));
      expect(group.entries.single.data['coffeeResultContract'], coffeeV3NarrativeV1ResultContract);
      expect(group.entries.single.data['overall'], _narrative);
      expect(ai.calls, 0);
    });

    test('a malformed V3N result is never saved', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = CoffeeReadingStore(LocalStorage(prefs));
      final service = CoffeeExperienceService(
        store: store,
        analysis: OpenAiCoffeeAnalysis(ai: NoProviderAi()),
      );
      await expectLater(
        service.restoreCompleted(
            resultId: 'bad', persistedAt: _persistedAt, result: _wire(override: {'career': 'x'})),
        throwsA(isA<CoffeeAnalysisException>()),
      );
      expect(store.all(), isEmpty);
    });

    test('history reopen (openSaved, no image) keeps the V3N contract and text', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = CoffeeReadingStore(LocalStorage(prefs));
      await store.save(_v3n());
      final controller = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: store,
          analysis: OpenAiCoffeeAnalysis(ai: NoProviderAi()),
        ),
        images: _NoImages(),
        live: fakeImmediateReadingFeatureRunner(),
      );
      addTearDown(controller.dispose);
      controller.openSaved(store.byId('v3n-r1')!);
      expect(controller.phase, CoffeePhase.result);
      _expectV3NShape(controller.reading!);
      expect(CoffeeResultText.overall(controller.reading!), _narrative);
    });
  });

  group('version payload / text helpers', () {
    test('coffee() carries the V3N marker; applyCoffee keeps it with exact overall', () {
      final payload = ReadingVersionPayload.coffee(_v3n());
      expect(payload['coffeeResultContract'], coffeeV3NarrativeV1ResultContract);
      expect(payload['overall'], _narrative);
      final applied = ReadingVersionPayload.applyCoffee(_v3n(id: 'base'), payload);
      expect(applied.coffeeResultContract, coffeeV3NarrativeV1ResultContract);
      expect(CoffeeResultText.overall(applied), _narrative);
    });

    test('helper, narration and insight copy keep the V3N wording', () {
      expect(CoffeeResultText.overall(_v3n()), _narrative);
      expect(CoffeeFortuneNarration.body(_v3n()), contains(_narrative));
      final copy = CoffeeInsightCopy.fromReading(_v3n());
      expect(copy, contains(CoffeeCopy.overallTitle));
      expect(copy, contains('ön plana çıkabilir.'));
      expect(copy, contains('bir yöne dönerken bulman da olası.'));
    });
  });

  group('result views', () {
    Future<void> pump(WidgetTester tester, {required bool experimental}) async {
      FeatureFlagRuntime.refreshFromRemote({ProductFeatureFlags.coffeeResult.key: experimental});
      await tester.binding.setSurfaceSize(const Size(390, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [localStorageProvider.overrideWithValue(LocalStorage(prefs))],
          child: MaterialApp(
            home: Scaffold(body: CoffeeResultView(reading: _v3n(), onNewCup: () {})),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
    }

    for (final experimental in [false, true]) {
      final label = experimental ? 'experimental' : 'stable';
      testWidgets('$label renderer shows the EXACT V3N narrative, both paragraphs', (tester) async {
        await pump(tester, experimental: experimental);
        expect(find.byType(experimental ? CoffeeResultSections : CoffeeResultStable), findsOneWidget);
        final hero = tester
            .widgetList<ChamberNarrativeBlock>(find.byType(ChamberNarrativeBlock))
            .firstWhere((b) => b.hero);
        expect(hero.body, _narrative);
        // Each server paragraph is shown whole, as its own paragraph.
        expect(find.text(_p1), findsOneWidget);
        expect(find.text(_p2), findsOneWidget);
        // No invented lanes; the contract never surfaces to the user.
        expect(find.text(CoffeeCopy.loveTitle), findsNothing);
        expect(find.text(CoffeeCopy.careerTitle), findsNothing);
        expect(find.textContaining('v3_narrative_v1'), findsNothing);
      });
    }
  });
}
