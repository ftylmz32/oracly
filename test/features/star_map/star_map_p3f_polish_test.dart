/// P3F — saved birth must not look missing while it is still loading.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_natal.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/providers/birth_information_provider.dart';
import 'package:oracly_new/features/star_map/copy/star_map_polish_copy.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a loading saved birth record is not treated as missing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final gate = Completer<BirthProfile?>();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          birthInformationProvider.overrideWith((ref) => gate.future),
        ],
        child: const MaterialApp(home: StarMapReferenceScreen()),
      ),
    );
    await tester.pump();

    expect(find.text(StarMapPolishCopy.whatItIs), findsOneWidget);
    expect(find.text(StarMapPolishCopy.enterBirthInfo), findsNothing);
    expect(find.text(StarMapPolishCopy.viewChart), findsNothing);
    expect(find.text(StarMapPolishCopy.chartReady), findsNothing);

    gate.complete(
      BirthProfile(birthDate: DateTime(1995, 8, 15), birthPlace: 'İstanbul'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(StarMapPolishCopy.viewChart), findsOneWidget);
    expect(find.text(StarMapPolishCopy.enterBirthInfo), findsNothing);
    expect(find.text('İstanbul'), findsOneWidget);
  });

  test('star-map birth handoff date follows the bound locale', () {
    final profile = BirthProfile(
      birthDate: DateTime(1990, 3, 25),
      birthPlace: 'Ankara',
    );
    OraclyL10n.bind('en');
    final en = OracleReadingContextNatal.birthLine(profile);
    expect(en, contains(OraclyFormat.dateCompact(profile.birthDate)));
    expect(en, isNot(contains('25.3.1990')));
    OraclyL10n.bind('tr');
    final tr = OracleReadingContextNatal.birthLine(profile);
    expect(tr, contains(OraclyFormat.dateCompact(profile.birthDate)));
    expect(tr, isNot(en));
  });
}
