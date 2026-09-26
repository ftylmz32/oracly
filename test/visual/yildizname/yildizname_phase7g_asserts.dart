/// Phase 7G — structural golden assertions (test-only).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/favorite_moments/copy/favorite_moments_copy.dart';
import 'package:oracly_new/features/favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_fact_snapshot_plate.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_scope_note.dart';

void phase7gAssertNoRawIds(WidgetTester tester) {
  final blob = tester
      .getSemantics(find.byType(StarMapReferenceResultScreen))
      .toString();
  for (final bad in const [
    'yid_',
    'theme.',
    'yth_',
    'factRef',
    'semanticFingerprint',
    'evidenceFingerprint',
    'serializerVersion',
    'contentHash',
    'fullNatalEphemeris',
  ]) {
    expect(blob.contains(bad), isFalse, reason: bad);
  }
}

void phase7gAssertNarrativeSurface(
  WidgetTester tester, {
  required bool expectFacts,
  required bool expectFavorite,
}) {
  expect(find.byType(StarMapReferenceResultScreen), findsOneWidget);
  expect(find.byType(StarMapScopeNote), findsOneWidget);
  if (expectFacts) {
    expect(find.byType(StarMapFactSnapshotPlate), findsOneWidget);
  }
  expect(
    find.byType(SaveFavoriteMomentLink),
    expectFavorite ? findsOneWidget : findsNothing,
  );
  expect(find.text(FavoriteMomentsCopy.sourceUnavailable), findsNothing);
  phase7gAssertNoRawIds(tester);
  expect(tester.takeException(), isNull);
}
