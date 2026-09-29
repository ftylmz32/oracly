/// P4E.4 — live Wrap stays; forensic goldens keep the pre-P4C row.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/favorite_moments/copy/favorite_moments_copy.dart';
import 'package:oracly_new/features/favorite_moments/models/favorite_moment.dart';
import 'package:oracly_new/features/favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import 'package:oracly_new/features/favorite_moments/services/favorite_moment_factory.dart';
import 'package:oracly_new/shared/widgets/oracly_pressable.dart';

import '../../test_helpers/provider_scope_harness.dart';
import '../../visual/yildizname/yildizname_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  testWidgets('live default is wrap and keeps the 44px target', (tester) async {
    await _pumpLink(tester, forensicLegacyRow: false, width: 320, scale: 2);
    expect(_layout<Wrap>(tester), findsOneWidget);
    expect(_layout<Row>(tester), findsNothing);
    expect(
      tester.getSize(find.byType(OraclyPressable)).height,
      greaterThanOrEqualTo(44),
    );
    expect(find.bySemanticsLabel(FavoriteMomentsCopy.save), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('forensic legacy mode is the pre-P4C row', (tester) async {
    await _pumpLink(tester, forensicLegacyRow: true);
    final row = tester.widget<Row>(_layout<Row>(tester));
    expect(row.mainAxisSize, MainAxisSize.min);
    expect((row.children[1] as SizedBox).width, 6);
    expect(_layout<Wrap>(tester), findsNothing);
  });

  testWidgets('row and wrap share save then unsave', (tester) async {
    for (final forensic in [false, true]) {
      await _pumpLink(tester, forensicLegacyRow: forensic);
      await _toggle(
        tester,
        FavoriteMomentsCopy.save,
        FavoriteMomentsCopy.unsave,
      );
      await _toggle(
        tester,
        FavoriteMomentsCopy.unsave,
        FavoriteMomentsCopy.save,
      );
    }
  });
}

Finder _layout<T extends Widget>(WidgetTester tester) {
  return find.descendant(
    of: find.byType(SaveFavoriteMomentLink),
    matching: find.byType(T),
  );
}

Future<void> _toggle(WidgetTester tester, String from, String to) async {
  expect(find.text(from), findsOneWidget);
  await tester.tap(find.byType(SaveFavoriteMomentLink));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.text(to), findsOneWidget);
}

Future<void> _pumpLink(
  WidgetTester tester, {
  required bool forensicLegacyRow,
  double width = 390,
  double scale = 1,
}) async {
  final storage = await yildiznameVisualOpenStorage();
  await tester.pumpWidget(
    buildProviderScopeHarness(
      storage: storage,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 568),
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            body: SaveFavoriteMomentLink(
              draft: _moment(),
              forensicLegacyRow: forensicLegacyRow,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

FavoriteMoment _moment() {
  return FavoriteMomentFactory.starMapArtifact(
    artifactId: 'yid_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    at: DateTime.utc(2026, 1, 10),
    title: 'Gökyüzü',
    insight: 'Sakin bir iz.',
  );
}
