import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/core/navigation/universe/oracly_universe_realm.dart';

void main() {
  test('registry includes live and reserved future modules', () {
    expect(OraclyFeatureRegistry.byId(OraclyFeatureId.tarot)?.isLive, isTrue);
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.numerology)?.isReserved,
      isTrue,
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.moonCalendar)?.isReserved,
      isTrue,
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.manifestation)?.isReserved,
      isTrue,
    );
  });

  test('reserved modules have route names pre-registered', () {
    expect(OraclyRoutes.numerology, '/numerology');
    expect(OraclyRoutes.moonCalendar, '/moon-calendar');
    expect(OraclyRoutes.manifestation, '/manifestation');
    expect(
      OraclyFeatureRegistry.byRoute(OraclyRoutes.numerology)?.id,
      OraclyFeatureId.numerology,
    );
  });

  test('home understand band lists preview modules only', () {
    final understand = OraclyFeatureRegistry.forHomeBand('understand');
    expect(understand.map((m) => m.id), contains(OraclyFeatureId.dream));
    expect(
      understand.map((m) => m.id),
      isNot(contains(OraclyFeatureId.numerology)),
    );
  });

  test('journey remember realm groups archive features', () {
    final remember = OraclyFeatureRegistry.forRealm(
      OraclyUniverseRealm.remember,
    );
    expect(remember.map((m) => m.id), contains(OraclyFeatureId.readingHistory));
    expect(remember.map((m) => m.id), contains(OraclyFeatureId.memory));
  });
}
