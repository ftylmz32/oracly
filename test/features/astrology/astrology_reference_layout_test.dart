import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/astrology/copy/astrology_presentation_copy.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_detail_body.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_screen.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_stat_row.dart';
import 'package:oracly_new/features/astrology/services/astrology_daily_reading_service.dart';
import 'package:oracly_new/features/content/astrology/data/astrology_content_catalogue.dart';
import 'package:oracly_new/features/gems/data/gem_display.dart';
import 'package:oracly_new/features/personal_discovery/copy/personal_theme_copy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  const viewports = <Size>[
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(411, 901),
    Size(430, 932),
    Size(600, 960),
  ];

  group('Astrology reference — no overflow', () {
    for (final size in viewports) {
      testWidgets('full page at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        SharedPreferences.setMockInitialValues({});
        final storage = await LocalStorage.open();
        await tester.pumpWidget(
          buildProviderScopeHarness(
            storage: storage,
            child: const MaterialApp(home: AstrologyReferenceScreen()),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('ASTROLOJİ'), findsOneWidget);
        expect(find.text(GemDisplay.format(0)), findsOneWidget);
        expect(find.text('Koç'), findsWidgets);
        expect(find.text('Boğa'), findsOneWidget);
        expect(find.text('İkizler'), findsOneWidget);
        expect(find.text('Yengeç'), findsOneWidget);
        // Date range lives under the instrument caption + "SENİN GÖKYÜZÜN" — not on art.
        expect(find.text('21 Mart – 19 Nisan'), findsWidgets);
        expect(find.text('Aşk'), findsNothing);
        expect(find.text('Kariyer'), findsNothing);
        expect(find.text('Yakınlık'), findsNothing);
        expect(find.text('Yön'), findsNothing);
        expect(find.text(AstrologyPresentationCopy.journeyEmpty), findsNothing);
        expect(find.text(AstrologyReferenceStatRow.honestyNote), findsNothing);
        expect(find.textContaining('%'), findsNothing);
        expect(find.text(AstrologyPresentationCopy.todayTitle), findsNothing);
        expect(find.text(AstrologyPresentationCopy.loveTitle), findsNothing);
        expect(find.text(AstrologyPresentationCopy.careerTitle), findsNothing);
        expect(find.text(AstrologyPresentationCopy.todayAsk), findsOneWidget);
        // Supporting insight lanes are conditional on real personalization themes.
        // In an empty profile, only the inner lane may still produce an honest reflection.
        expect(find.text(AstrologyPresentationCopy.laneLove), findsNothing);
        expect(find.text(AstrologyPresentationCopy.laneWork), findsNothing);
        expect(find.text(AstrologyPresentationCopy.laneInner), findsWidgets);
        expect(find.text(AstrologyPresentationCopy.detailCta), findsOneWidget);
        expect(find.text('Rüya'), findsNothing);

        final detailCta = find.text(AstrologyPresentationCopy.detailCta);
        await tester.ensureVisible(detailCta);
        await tester.pump();
        await tester.tap(detailCta);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text(AstrologyPresentationCopy.todayTitle), findsNothing);
        expect(find.textContaining('%'), findsNothing);
        expect(find.text(AstrologyPresentationCopy.generalTitle), findsNothing);
        expect(find.text(AstrologyPresentationCopy.loveTitle), findsNothing);
        expect(find.text(AstrologyPresentationCopy.careerTitle), findsNothing);
        expect(find.text(AstrologyPresentationCopy.innerTitle), findsNothing);
        expect(find.text('Maddi Durum'), findsNothing);
        expect(find.text('Enerji / Sağlık'), findsNothing);
        expect(find.text('Haftalık Bakış'), findsNothing);
        expect(find.text(PersonalThemeCopy.insufficient), findsNothing);
      });
    }
  });

  testWidgets('detail is one narrative without love or career headings',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final sign = AstrologyContentCatalogue.signById('aries')!;
    final reading = AstrologyDailyReadingService.build(
      sign,
      now: DateTime(2026, 8, 13),
    );
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AstrologyReferenceDetailBody(
                sign: sign,
                reading: reading,
                themeLabels: const ['ilişki', 'kariyer'],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(AstrologyPresentationCopy.generalTitle), findsNothing);
    expect(find.text(AstrologyPresentationCopy.loveTitle), findsNothing);
    expect(find.text(AstrologyPresentationCopy.careerTitle), findsNothing);
    expect(find.text(AstrologyPresentationCopy.innerTitle), findsNothing);
    expect(find.textContaining(reading.overall.substring(0, 18)), findsWidgets);
    expect(find.textContaining('ay burcu'), findsNothing);
    expect(find.textContaining('yükselen'), findsNothing);
  });
}
