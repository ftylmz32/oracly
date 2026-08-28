/// Product Completion Depth Batch — Soulmate persistence, Premium value, Yildizname l10n.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_natal.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/data/soul_mate_result_store.dart';
import 'package:oracly_new/features/premium/models/soul_mate_saved_result.dart';
import 'package:oracly_new/features/premium/data/soul_mate_interpretation_catalogue.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_experiences_section.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_result_service.dart';
import 'package:oracly_new/features/star_map/data/star_map_copy.dart';
import 'package:oracly_new/features/star_map/services/star_map_reading_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Soulmate persistence', () {
    late LocalStorage storage;
    late SoulMateResultService service;
  late Directory docs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await LocalStorage.open();
      service = SoulMateResultService(storage);
      docs = await Directory.systemTemp.createTemp('oracly_soulmate_test');
    });

    tearDown(() async {
      await SoulMateResultStore.clear(storage);
      if (docs.existsSync()) await docs.delete(recursive: true);
    });

    final request = SoulMateDrawRequest(
      name: 'Ada',
      birthDate: DateTime(1994, 6, 12),
      gender: SoulMateGenderPref.feminine,
      intention: 'sakin',
    );

    test('successful result persists portrait and interpretation', () async {
      final bytes = List<int>.generate(32, (i) => i + 1);
      final saved = await SoulMateResultStore.save(
        storage: storage,
        record: SoulMateSavedResult(
          id: '1',
          createdAt: DateTime(2026, 1, 1),
          name: request.name,
          birthDate: request.birthDate,
          gender: request.gender,
          intention: request.intention,
          portraitPath: '',
          parts: const SoulMateReadingParts(
            energy: 'e',
            attraction: 'a',
            dynamics: 'd',
            feeling: 'f',
            yourSide: 'y',
          ),
        ),
        portraitBytes: bytes,
        documents: docs,
      );
      expect(saved, isNotNull);
      final loaded = await service.latestWithPortrait();
      expect(loaded, isNotNull);
      expect(loaded!.bytes, bytes);
      expect(loaded.meta.parts.energy, 'e');
      expect(File(loaded.meta.portraitPath).existsSync(), isTrue);
    });

    test('failed save does not destroy previous valid result', () async {
      final first = List<int>.generate(8, (i) => 10 + i);
      await service.saveSuccessfulDraw(
        request: request,
        imageBytes: first,
        documents: docs,
      );
      final empty = await service.saveSuccessfulDraw(
        request: request,
        imageBytes: const [],
        documents: docs,
      );
      expect(empty, isNull);
      final loaded = await service.latestWithPortrait();
      expect(loaded!.bytes, first);
    });

    test('OR handoff uses stable saved id', () {
      const parts = SoulMateReadingParts(
        energy: 'e',
        attraction: 'a',
        dynamics: 'd',
        feeling: 'f',
        yourSide: 'y',
      );
      final ctx = OracleReadingContextSources.soulMate(
        id: 'soulmate_42',
        interpretation: parts.joined,
        name: 'Ada',
      );
      expect(ctx.kind.name, 'soulMate');
      expect(ctx.sessionId, 'soulmate_42');
      expect(ctx.interpretationSummary, contains('e'));
    });
  });

  group('Premium concrete value', () {
    testWidgets('paywall shows Soulmate OR and Journey experiences', (tester) async {
      OraclyL10n.bind('tr');
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: const MaterialApp(home: PremiumReferenceScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(PremiumReferenceExperiencesSection), findsOneWidget);
      expect(find.text(PremiumCopy.experiencesSectionTitle), findsOneWidget);
      expect(find.text(PremiumCopy.benefitSoulmateTitle), findsWidgets);
      expect(find.text(PremiumCopy.benefitOrTitle), findsWidgets);
      expect(find.text(PremiumCopy.benefitJourneyTitle), findsWidgets);
      expect(find.text(PremiumCopy.benefitsSectionTitle), findsOneWidget);
    });

    test('concrete benefit copy TR EN RU', () {
      OraclyL10n.bind('tr');
      expect(PremiumCopy.benefitSoulmateBody, contains('kaydedilir'));
      OraclyL10n.bind('en');
      expect(PremiumCopy.benefitSoulmateBody.toLowerCase(), contains('saved'));
      OraclyL10n.bind('ru');
      expect(PremiumCopy.benefitSoulmateBody, isNot(contains('kaydedilir')));
    });
  });

  group('Yildizname localization', () {
    test('TR keeps Turkish planet labels', () {
      OraclyL10n.bind('tr');
      final planets = StarMapCopy.planets(0);
      expect(planets.first.nameTr, 'Güneş');
      expect(planets.first.polarityLabel, 'Dengeli');
    });

    test('EN has no leaked Turkish planet labels', () {
      OraclyL10n.bind('en');
      final reading = StarMapReadingService.build(
        now: DateTime(2026, 3, 15),
        sunSign: ZodiacSignId.leo,
      );
      final joined = [
        reading.sunLabel ?? '',
        for (final p in reading.planets) '${p.nameTr} ${p.influence}',
      ].join(' ');
      expect(joined, contains('Sun'));
      expect(joined, isNot(contains('Güneş')));
      expect(joined, isNot(contains('Kimlik ve')));
      expect(reading.planets.first.polarityLabel, 'Balanced');
    });

    test('RU has no leaked Turkish labels', () {
      OraclyL10n.bind('ru');
      final reading = StarMapReadingService.build(sunSign: ZodiacSignId.leo);
      expect(reading.sunLabel, isNot(contains('Aslan')));
      expect(reading.planets.first.nameTr, 'Солнце');
    });

    test('OR handoff localized for EN', () {
      OraclyL10n.bind('en');
      final reading = StarMapReadingService.build(sunSign: ZodiacSignId.leo);
      final ctx = OracleReadingContextNatal.starMap(
        sectionLabel: 'Overview',
        reading: reading,
        profile: BirthProfile(
          birthDate: DateTime(1990, 3, 25),
          birthPlace: 'Ankara',
          birthTimeKnown: false,
        ),
      );
      expect(ctx.sourceLabel, contains('Star map'));
      expect(ctx.fullInterpretation, isNot(contains('Kaynak: yerel')));
      expect(ctx.cardsSummary, isNot(contains('Güneş')));
    });

    test('unknown birth time honesty in handoff', () {
      OraclyL10n.bind('en');
      final line = OracleReadingContextNatal.birthLine(
        BirthProfile(
          birthDate: DateTime(1990, 3, 25),
          birthPlace: 'Ankara',
          birthTimeKnown: false,
        ),
      );
      expect(line, isNot(contains(':')));
    });
  });
}
