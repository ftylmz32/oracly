/// Yıldızname V1 — birth info source, honest labels, OR context, persist.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_birth_chart_repository.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/ai/oracle_conversation/services/oracle_followup_copy.dart';
import 'package:oracly_new/features/birth_chart/copy/birth_chart_copy.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_record_mapper.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/services/natal_chart_calculator.dart';
import 'package:oracly_new/features/star_map/copy/star_map_polish_copy.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_screen.dart';
import 'package:oracly_new/features/star_map/services/star_map_reading_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

BirthProfile get _profile => BirthProfile(
      birthDate: DateTime(1995, 8, 15),
      birthPlace: 'İstanbul',
      birthTime: DateTime(1995, 8, 15, 14, 30),
      birthTimeKnown: true,
      latitude: 41.01,
      longitude: 28.98,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first visit without birth info stays general', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: StarMapReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(StarMapPolishCopy.enterBirthInfo), findsOneWidget);
    expect(find.text(StarMapPolishCopy.viewChart), findsNothing);
    expect(find.text(StarMapPolishCopy.whatItIs), findsOneWidget);
    expect(find.text(StarMapPolishCopy.journeyEmpty), findsOneWidget);
    expect(find.text(StarMapPolishCopy.innerThemeTitle), findsNothing);
    expect(find.text('KARMİK ANALİZ'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved birth info reopens as ready and personalized',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final chart = const NatalChartCalculator().calculate(_profile);
    await storage.setString(
      'birth_chart_latest',
      jsonEncode(BirthChartRecordMapper.toRecord(chart).toJson()),
    );

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: StarMapReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(StarMapPolishCopy.chartReady), findsOneWidget);
    expect(find.text(StarMapPolishCopy.viewChart), findsOneWidget);
    expect(find.text(StarMapPolishCopy.enterBirthInfo), findsNothing);
    expect(find.text(StarMapPolishCopy.whatItIs), findsOneWidget);
    // Birth without discovery history → first-entry archive chapters.
    expect(find.text(StarMapPolishCopy.journeyEmpty), findsOneWidget);
    expect(find.text(StarMapPolishCopy.innerThemeTitle), findsNothing);
    expect(find.textContaining('Aslan'), findsWidgets);
    expect(find.text('İstanbul'), findsOneWidget);

    final repo = LocalBirthChartRepository(storage);
    final reopened = BirthChartRecordMapper.fromRecord(
      (await repo.getLatest())!,
    );
    expect(reopened.profile.birthPlace, 'İstanbul');
    expect(reopened.profile.hasKnownTime, isTrue);
    expect(reopened.sun.sign.labelTr, 'Aslan');
  });

  test('one store: birth_chart_latest is the only birth-info key', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    expect(storage.getString('birth_chart_latest'), isNull);

    await LocalBirthChartRepository(storage).save(
      BirthChartRecordMapper.toRecord(
        const NatalChartCalculator().calculate(_profile),
      ),
    );
    expect(storage.getString('birth_chart_latest'), isNotNull);
    expect(storage.getString('birth_information'), isNull);
    expect(storage.getString('yildizname_birth'), isNull);
  });

  test('OR context includes birth, section, interpretation and answers', () {
    final sun = NatalChartCalculator().calculate(_profile).sun.sign;
    final reading = StarMapReadingService.build(
      now: DateTime(2026, 8, 9),
      sunSign: sun,
    );
    final ctx = OracleReadingContextSources.starMap(
      sectionLabel: StarMapPolishCopy.skyMessageTitle,
      reading: reading,
      profile: _profile,
    );
    expect(ctx.sourceLabel, contains('Yıldızname'));
    expect(ctx.cardsSummary, contains('İstanbul'));
    expect(ctx.cardsSummary, contains('Aslan'));
    expect(ctx.interpretationSummary, isNotEmpty);
    expect(ctx.fullInterpretation, isNotEmpty);
    expect(ctx.fullInterpretation, isNot(contains('latitude')));

    final answer = OracleFollowupCopy.respond(
      context: ctx,
      question: 'Bugün neye dikkat etmeliyim?',
    );
    expect(answer.toLowerCase(), isNot(contains('kesinlikle')));
    expect(answer, contains(ctx.interpretationSummary.split('.').first));
  });

  test('birth chart copy keeps honest fidelity language', () {
    expect(BirthChartCopy.summaryTitle, 'Yorumun özeti');
    expect(BirthChartCopy.strongThemesTitle, 'Güçlü Temaların');
    expect(BirthChartCopy.notableThemesTitle, 'Dikkat Çeken Temalar');
    expect(BirthChartCopy.resultInterpretation, 'Yorum');
    expect(BirthChartCopy.ephemerisNote, contains('sembolik'));
    expect(BirthChartCopy.personalizeEmpty, contains('kişisel yorum'));
    expect(
      StarMapPolishCopy.personalizeEmpty,
      contains('kişisel yıldızname yolu'),
    );
    for (final line in [
      BirthChartCopy.personalizeEmpty,
      StarMapPolishCopy.personalizeEmpty,
    ]) {
      expect(line, contains('Güneş burcuna göre'));
      expect(line, contains('doğum tarihini ekle'));
    }
  });
}
