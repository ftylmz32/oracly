import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/core/navigation/universe/oracly_universe_realm.dart';
import 'package:oracly_new/features/home/reference/home_reference_modules.dart';

void main() {
  test('feature availability truth for audited modules', () {
    final dream = OraclyFeatureRegistry.byId(OraclyFeatureId.dream)!;
    final astrology = OraclyFeatureRegistry.byId(OraclyFeatureId.astrology)!;
    final starMap = OraclyFeatureRegistry.byId(OraclyFeatureId.starMap)!;
    expect(dream.isLive, isTrue);
    expect(dream.isPreview, isFalse);
    expect(dream.subtitle!.toLowerCase(), isNot(contains('onizleme')));
    expect(astrology.isLive, isTrue);
    expect(astrology.isPreview, isFalse);
    expect(starMap.isLive, isTrue);
    expect(starMap.isPreview, isFalse);
    expect(astrology.subtitle!.toLowerCase(), isNot(contains('önizleme')));
    for (final spec in HomeReferenceModules.list()) {
      expect(
        OraclyFeatureRegistry.byId(spec.id)?.isPreview ?? false,
        OraclyFeatureRegistry.byId(spec.id)!.isPreview,
      );
    }
  });

  test('registry includes live and reserved future modules', () {
    expect(OraclyFeatureRegistry.byId(OraclyFeatureId.dream)?.isLive, isTrue);
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

  test('home understand band lists live and preview understand modules', () {
    final understand = OraclyFeatureRegistry.forHomeBand('understand');
    expect(understand.map((m) => m.id), contains(OraclyFeatureId.dream));
    expect(OraclyFeatureRegistry.byId(OraclyFeatureId.dream)?.isLive, isTrue);
    expect(understand.map((m) => m.id), contains(OraclyFeatureId.astrology));
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
