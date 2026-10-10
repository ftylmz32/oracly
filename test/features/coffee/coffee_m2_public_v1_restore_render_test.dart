/// Coffee Live Integration Slice 3 — client `m2_public_v1` restore + exact
/// authoritative rendering. The frozen M2 `overall` must survive wire →
/// CoffeeReading → local store → reopen → version payload → stable and
/// experimental renderers WITHOUT the legacy parser / composer / scrub,
/// while legacy Coffee keeps every existing rule.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/fortune_voice.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/chamber_narrative_block.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_rollback.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_surface.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/reading_version/models/reading_version_kind.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_payload.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_service.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_store.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_photo_slot.dart';
import 'package:oracly_new/features/coffee/controllers/coffee_reading_controller.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/models/coffee_result_contract.dart';
import 'package:oracly_new/features/coffee/models/coffee_symbol.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_insight_copy.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_result_observations.dart';
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

import '../../support/fake_reading_operation_backend.dart';

/// Any provider touch throws — restore must be zero-provider.
class _NoProviderAi implements OraclyAiService {
  int calls = 0;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('provider must not be touched: ${invocation.memberName}');
  }
}

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

// SYNTHETIC test phrase (never product copy): short (< 80), one sentence,
// with a double space and two phrases legacy FortuneVoice.scrub rewrites.
const _m2Exact =
    'Fincanda bir konu ön plana çıkabilir;  kesin olacak gibi değil.';
// Padded variant: proves restore/store/version never trim the original.
const _m2Padded = '  $_m2Exact\n';

final _persistedAt = DateTime.utc(2026, 10, 9, 12, 30);

Map<String, dynamic> _m2Wire({Map<String, dynamic> override = const {}}) => {
      'coffeeResultContract': coffeeM2PublicV1ResultContract,
      'visualObservation': '',
      'overall': _m2Padded,
      'love': '',
      'career': '',
      'money': '',
      'nearFuture': '',
      'takeaway': '',
      'symbols': <Object>[],
      ...override,
    };

CoffeeReading _m2Reading({String overall = _m2Exact, String id = 'm2-r1'}) =>
    CoffeeReading(
      id: id,
      createdAt: _persistedAt,
      coffeeResultContract: coffeeM2PublicV1ResultContract,
      overall: overall,
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: '',
    );

CoffeeReading _legacyReading({String overall = _m2Exact}) => CoffeeReading(
      id: 'legacy-r1',
      createdAt: _persistedAt,
      overall: overall,
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: '',
      visualObservation: 'Ağızda kuş, yanında açık bir çizgi.',
      symbols: const [
        CoffeeSymbol(name: 'kuş', meaning: '', interpretation: ''),
      ],
    );

void _expectM2Shape(CoffeeReading r, {String overall = _m2Padded}) {
  expect(r.coffeeResultContract, coffeeM2PublicV1ResultContract);
  expect(r.isM2PublicV1, isTrue);
  expect(r.overall, overall);
  expect(r.visualObservation, '');
  expect(r.love, '');
  expect(r.career, '');
  expect(r.money, '');
  expect(r.nearFuture, '');
  expect(r.takeaway, '');
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

  test('precondition: legacy scrub WOULD rewrite the synthetic phrase', () {
    expect(_m2Exact.length, lessThan(80));
    expect(FortuneVoice.scrub(_m2Exact), isNot(_m2Exact));
    expect(FortuneVoice.scrub(_m2Padded), isNot(_m2Padded));
  });

  group('wire restore (OpenAiCoffeeAnalysis.restoreCompleted)', () {
    late _NoProviderAi ai;
    late OpenAiCoffeeAnalysis analysis;
    setUp(() {
      ai = _NoProviderAi();
      analysis = OpenAiCoffeeAnalysis(ai: ai);
    });

    CoffeeReading restore(Map<String, dynamic> result) =>
        analysis.restoreCompleted(
          resultId: 'm2-r1',
          persistedAt: _persistedAt,
          result: result,
        );

    test('m2_public_v1: empty visual + short overall restore EXACT', () {
      final r = restore(_m2Wire());
      expect(r.id, 'm2-r1');
      expect(r.createdAt, _persistedAt);
      _expectM2Shape(r);
      expect(ai.calls, 0);
    });

    test('same short body WITHOUT marker stays on the legacy path (rejected)',
        () {
      final legacy = _m2Wire()..remove('coffeeResultContract');
      expect(() => restore(legacy), throwsA(isA<CoffeeAnalysisException>()));
      // Legacy: valid visual but overall < 80 → composer still rejects.
      final shortLegacy = {
        ...legacy,
        'visualObservation': 'Ağızda kuş, yanında açık bir çizgi.',
      };
      expect(
        () => restore(shortLegacy),
        throwsA(isA<CoffeeAnalysisException>()),
      );
    });

    final malformed = <String, Map<String, dynamic>>{
      'empty overall': {'overall': ''},
      'whitespace overall': {'overall': '   \n'},
      'non-string overall': {'overall': 42},
      'missing overall': {'overall': null},
      'non-empty visualObservation': {'visualObservation': 'Ağızda kuş izi.'},
      'non-empty love': {'love': 'x'},
      'non-empty career': {'career': 'x'},
      'non-empty money': {'money': 'x'},
      'non-empty nearFuture': {'nearFuture': 'x'},
      'non-empty takeaway': {'takeaway': 'x'},
      'missing lane': {'love': null},
      'non-empty symbols': {
        'symbols': [
          {'name': 'kuş', 'meaning': '', 'interpretation': ''},
        ],
      },
      'symbols non-list': {'symbols': 'kuş'},
      'unknown contract': {'coffeeResultContract': 'm3_public_v9'},
      'non-string contract': {'coffeeResultContract': 1},
    };
    for (final entry in malformed.entries) {
      test('malformed m2 fails closed: ${entry.key}', () {
        expect(
          () => restore(_m2Wire(override: entry.value)),
          throwsA(isA<CoffeeAnalysisException>()),
        );
        expect(ai.calls, 0);
      });
    }

    test('unknown contract over an otherwise legacy-valid body: no fallback',
        () {
      const longOverall =
          'Fincanda görünen izler, son zamanlarda ertelenen bir konunun yeniden '
          'konuşulacağına işaret ediyor; acele etmeden ilerlemek iyi gelebilir.';
      expect(
        () => restore({
          'coffeeResultContract': 'future_contract',
          'visualObservation': 'Ağızda kuş, yanında açık bir çizgi.',
          'overall': longOverall,
          'love': '',
          'career': '',
          'money': '',
          'nearFuture': '',
          'takeaway': '',
          'symbols': <Object>[],
        }),
        throwsA(isA<CoffeeAnalysisException>()),
      );
    });
  });

  group('CoffeeReading local JSON', () {
    test('A legacy JSON without marker parses with null', () {
      final legacy = _legacyReading().toJson()..remove('coffeeResultContract');
      expect(legacy.containsKey('coffeeResultContract'), isFalse);
      final r = CoffeeReading.fromJson(legacy);
      expect(r.coffeeResultContract, isNull);
      expect(r.isM2PublicV1, isFalse);
      expect(_legacyReading().toJson().containsKey('coffeeResultContract'),
          isFalse);
    });

    test('B/C m2 marker + exact overall round-trip through jsonEncode', () {
      final src = _m2Reading(overall: _m2Padded);
      final back = CoffeeReading.fromJson(
        jsonDecode(jsonEncode(src.toJson())) as Map<String, dynamic>,
      );
      _expectM2Shape(back);
    });

    test('D unknown non-null marker fails closed', () {
      final json = _m2Reading().toJson()..['coffeeResultContract'] = 'v9';
      expect(() => CoffeeReading.fromJson(json), throwsFormatException);
      final nonString = _m2Reading().toJson()..['coffeeResultContract'] = 3;
      expect(() => CoffeeReading.fromJson(nonString), throwsFormatException);
    });

    test('E copyWith preserves marker; explicit null clears it', () {
      final m2 = _m2Reading();
      expect(m2.copyWith(love: 'x').coffeeResultContract,
          coffeeM2PublicV1ResultContract);
      expect(m2.copyWith(coffeeResultContract: null).coffeeResultContract,
          isNull);
      expect(_legacyReading().copyWith(overall: 'y').coffeeResultContract,
          isNull);
    });

    test('store skips an unknown-contract row instead of misrendering it',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);
      final unknown = _m2Reading(id: 'future')
          .toJson()
        ..['coffeeResultContract'] = 'future_contract';
      await storage.setStringList(CoffeeReadingStore.key, [
        jsonEncode(unknown),
        jsonEncode(_m2Reading().toJson()),
      ]);
      final store = CoffeeReadingStore(storage);
      expect(store.byId('future'), isNull);
      expect(store.byId('m2-r1')?.isM2PublicV1, isTrue);
    });
  });

  group('completed-result flow (CoffeeExperienceService.restoreCompleted)', () {
    test('restore → save → restart store → byId keeps marker + exact text',
        () async {
      final ai = _NoProviderAi();
      final prefs = await SharedPreferences.getInstance();
      final versions =
          ReadingVersionService(ReadingVersionStore(LocalStorage(prefs)));
      final service = CoffeeExperienceService(
        store: CoffeeReadingStore(LocalStorage(prefs)),
        analysis: OpenAiCoffeeAnalysis(ai: ai),
        versions: versions,
      );

      final restored = await service.restoreCompleted(
        resultId: 'm2-r1',
        persistedAt: _persistedAt,
        result: _m2Wire(),
      );
      _expectM2Shape(restored);

      // "Restart": fresh LocalStorage + store instances over the same prefs.
      final reloaded = CoffeeReadingStore(
        LocalStorage(await SharedPreferences.getInstance()),
      ).byId('m2-r1');
      expect(reloaded, isNotNull);
      expect(reloaded!.id, 'm2-r1');
      expect(reloaded.createdAt, _persistedAt);
      _expectM2Shape(reloaded);

      // Version seed (post-commit enrichment) carries the contract too.
      final group = versions.groupFor('m2-r1');
      expect(group?.kind, ReadingVersionKind.coffee);
      expect(group!.entries.single.data['coffeeResultContract'],
          coffeeM2PublicV1ResultContract);
      expect(group.entries.single.data['overall'], _m2Padded);
      expect(ai.calls, 0);
    });

    test('malformed m2 is never saved', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = CoffeeReadingStore(LocalStorage(prefs));
      final service = CoffeeExperienceService(
        store: store,
        analysis: OpenAiCoffeeAnalysis(ai: _NoProviderAi()),
      );
      await expectLater(
        service.restoreCompleted(
          resultId: 'bad',
          persistedAt: _persistedAt,
          result: _m2Wire(override: {'takeaway': 'x'}),
        ),
        throwsA(isA<CoffeeAnalysisException>()),
      );
      expect(store.all(), isEmpty);
    });

    test('history reopen (openSaved, no image) keeps the m2 contract',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final store = CoffeeReadingStore(LocalStorage(prefs));
      await store.save(_m2Reading(overall: _m2Padded));
      final controller = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: store,
          analysis: OpenAiCoffeeAnalysis(ai: _NoProviderAi()),
        ),
        images: _NoImages(),
        live: fakeImmediateReadingFeatureRunner(),
      );
      addTearDown(controller.dispose);
      controller.openSaved(store.byId('m2-r1')!);
      expect(controller.phase, CoffeePhase.result);
      _expectM2Shape(controller.reading!);
      expect(CoffeeResultText.overall(controller.reading!), _m2Padded);
    });
  });

  group('ReadingVersionPayload', () {
    test('coffee() carries the m2 marker; legacy payload has none', () {
      final m2 = ReadingVersionPayload.coffee(_m2Reading(overall: _m2Padded));
      expect(m2['coffeeResultContract'], coffeeM2PublicV1ResultContract);
      expect(m2['overall'], _m2Padded);
      final legacy = ReadingVersionPayload.coffee(_legacyReading());
      expect(legacy.containsKey('coffeeResultContract'), isFalse);
    });

    test('applyCoffee: m2 version stays m2 with exact overall', () {
      final base = _legacyReading();
      final applied = ReadingVersionPayload.applyCoffee(
        base,
        ReadingVersionPayload.coffee(_m2Reading(overall: _m2Padded)),
      );
      expect(applied.coffeeResultContract, coffeeM2PublicV1ResultContract);
      expect(applied.overall, _m2Padded);
      expect(CoffeeResultText.overall(applied), _m2Padded);
    });

    test('applyCoffee: legacy version over an m2 base becomes legacy', () {
      final base = _m2Reading();
      final legacyVersion = ReadingVersionPayload.coffee(_legacyReading());
      final applied = ReadingVersionPayload.applyCoffee(base, legacyVersion);
      expect(applied.coffeeResultContract, isNull);
      expect(CoffeeResultText.overall(applied), FortuneVoice.scrub(_m2Exact));
    });

    test('applyCoffee: unsupported contract is not applied (fail closed)', () {
      final base = _m2Reading();
      final applied = ReadingVersionPayload.applyCoffee(base, {
        ...ReadingVersionPayload.coffee(_legacyReading()),
        'coffeeResultContract': 'future_contract',
        'overall': 'başka bir metin',
      });
      expect(identical(applied, base), isTrue);
    });
  });

  group('central text helper / narration / insight copy', () {
    test('helper: m2 exact (no trim, no scrub); legacy scrubbed', () {
      expect(CoffeeResultText.overall(_m2Reading(overall: _m2Padded)),
          _m2Padded);
      expect(CoffeeResultText.overall(_legacyReading()),
          FortuneVoice.scrub(_m2Exact));
    });

    test('narration: m2 exact; legacy keeps scrub', () {
      expect(CoffeeFortuneNarration.body(_m2Reading()), _m2Exact);
      expect(CoffeeFortuneNarration.body(_legacyReading()),
          FortuneVoice.scrub(_m2Exact));
    });

    test('insight copy: m2 wording never scrubbed/dropped; legacy unchanged',
        () {
      // The clipboard's own InsightCopyText.clean collapses whitespace runs
      // for every feature (its contract); M2 wording itself is untouched.
      final copy = CoffeeInsightCopy.fromReading(_m2Reading());
      expect(copy, contains(CoffeeCopy.overallTitle));
      expect(copy, contains('ön plana çıkabilir;'));
      expect(copy, contains('kesin olacak gibi değil.'));
      expect(copy, isNot(contains('yeniden görünür')));
      expect(copy, isNot(contains('olası duruyor')));
      // Legacy: a robotic overall is still dropped, as before.
      expect(
        CoffeeInsightCopy.fromReading(_legacyReading()),
        isNot(contains(CoffeeCopy.overallTitle)),
      );
    });
  });

  group('result views', () {
    Future<void> pump(WidgetTester tester, CoffeeReading reading,
        {required bool experimental}) async {
      FeatureFlagRuntime.refreshFromRemote({
        ProductFeatureFlags.coffeeResult.key: experimental,
      });
      expect(FeatureFlagRollback.useExperimental(FeatureFlagSurface.coffeeResult),
          experimental);
      await tester.binding.setSurfaceSize(const Size(390, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(LocalStorage(prefs)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CoffeeResultView(reading: reading, onNewCup: () {}),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
    }

    String heroBody(WidgetTester tester) => tester
        .widgetList<ChamberNarrativeBlock>(find.byType(ChamberNarrativeBlock))
        .firstWhere((b) => b.hero)
        .body;

    for (final experimental in [false, true]) {
      final label = experimental ? 'experimental' : 'stable';
      testWidgets('$label renderer shows the EXACT m2 overall', (tester) async {
        await pump(tester, _m2Reading(), experimental: experimental);
        expect(find.byType(experimental ? CoffeeResultSections : CoffeeResultStable),
            findsOneWidget);
        expect(heroBody(tester), _m2Exact);
        expect(find.text(_m2Exact), findsOneWidget);
        expect(find.textContaining('yeniden görünür'), findsNothing);
        expect(find.textContaining('olası duruyor'), findsNothing);
        // The body is the reading, never the legacy disclaimer fallback (the
        // normal footer disclaimer may still render below, as before).
        expect(heroBody(tester), isNot(CoffeeCopy.disclaimer));
        // No invented visual analysis / lanes.
        expect(find.byType(CoffeeResultObservations), findsOneWidget);
        expect(find.textContaining('kuş'), findsNothing);
        expect(find.text(CoffeeCopy.loveTitle), findsNothing);
        expect(find.text(CoffeeCopy.careerTitle), findsNothing);
        expect(find.text(CoffeeCopy.newsTitle), findsNothing);
        expect(find.text(CoffeeCopy.cautionTitle), findsNothing);
        // Contract never surfaces to the user.
        expect(find.textContaining('m2_public_v1'), findsNothing);
      });

      testWidgets('$label renderer: padded m2 body handed over untrimmed',
          (tester) async {
        await pump(tester, _m2Reading(overall: _m2Padded),
            experimental: experimental);
        expect(heroBody(tester), _m2Padded);
        expect(find.textContaining('yeniden görünür'), findsNothing);
      });

      testWidgets('$label renderer: legacy overall still scrubbed',
          (tester) async {
        await pump(tester, _legacyReading(), experimental: experimental);
        expect(heroBody(tester), FortuneVoice.scrub(_m2Exact));
        expect(find.textContaining('yeniden görünür olabilir'), findsOneWidget);
        expect(find.textContaining('ön plana çıkabilir'), findsNothing);
      });
    }
  });

  test('client does not enable V3 capture: V2 slots unchanged', () {
    expect(
      CoffeeV2PhotoSlot.values,
      [
        CoffeeV2PhotoSlot.cupPrimary,
        CoffeeV2PhotoSlot.cupSecondary,
        CoffeeV2PhotoSlot.saucer,
      ],
    );
  });
}
