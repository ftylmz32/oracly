/// P0 — live Astrology must not show invented Aşk / Kariyer / Enerji %.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/astrology/copy/astrology_presentation_copy.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_screen.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_stat_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('honesty note has no invented 0–100 scores', () {
    expect(AstrologyReferenceStatRow.honestyNote, contains('yansıma'));
    expect(AstrologyReferenceStatRow.honestyNote, contains('skor'));
    expect(AstrologyReferenceStatRow.honestyNote.toLowerCase(), isNot(contains('katalog')));
    expect(AstrologyReferenceStatRow.honestyNote.contains('%'), isFalse);
    expect(RegExp(r'\d').hasMatch(AstrologyReferenceStatRow.honestyNote), isFalse);
  });

  testWidgets('live Astrology hub and detail hide fake percentages',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
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

    expect(find.text('ASTROLOJİ'), findsOneWidget);
    expect(find.text(AstrologyReferenceStatRow.honestyNote), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    expect(find.text(AstrologyPresentationCopy.todayTitle), findsNothing);
    expect(find.text(AstrologyPresentationCopy.detailCta), findsOneWidget);

    final detailCta = find.text(AstrologyPresentationCopy.detailCta);
    await tester.ensureVisible(detailCta);
    await tester.pump();
    await tester.tap(detailCta);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(AstrologyPresentationCopy.todayTitle), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    expect(find.text(AstrologyPresentationCopy.generalTitle), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    expect(find.text('Maddi Durum'), findsNothing);
    expect(find.text('Enerji / Sağlık'), findsNothing);
  });
}
