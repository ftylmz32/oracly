/// Phase 2 — product distinction: Yıldızname ≠ Astrology ≠ daily horoscope.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';

import 'truth/yildizname_product_distinction.dart';

void main() {
  group('fact ownership', () {
    test('natal baseline belongs to Yıldızname', () {
      expect(
        YildiznameProductDistinction.ownerOf('natalBaseline'),
        ContractProductOwner.yildizname,
      );
      expect(
        YildiznameProductDistinction.ownerOf('birthChart'),
        ContractProductOwner.yildizname,
      );
    });

    test('transits belong to Astrology', () {
      expect(
        YildiznameProductDistinction.ownerOf('currentTransitSky'),
        ContractProductOwner.astrology,
      );
      expect(
        YildiznameProductDistinction.ownerOf('transitToNatal'),
        ContractProductOwner.astrology,
      );
    });

    test('generic daily horoscope as primary FAIL', () {
      expect(
        YildiznameProductDistinction.primaryYildiznameOutputOk(
          'genericDailyHoroscopePrimary',
        ),
        isFalse,
      );
      expect(
        YildiznameProductDistinction.ownerOf('genericDailyHoroscopePrimary'),
        ContractProductOwner.astrology,
      );
    });
  });

  group('registry', () {
    test('starMap route is /star-map and not premium', () {
      final mod = OraclyFeatureRegistry.byId(OraclyFeatureId.starMap);
      expect(mod, isNotNull);
      expect(mod!.routeName, OraclyRoutes.starMap);
      expect(OraclyRoutes.starMap, '/star-map');
      expect(mod.routeName, YildiznameProductDistinction.yildiznameRoute);
      expect(mod.requiresPremium, isFalse);
      expect(
        mod.requiresPremium,
        YildiznameProductDistinction.yildiznamePremium,
      );
      expect(mod.isLive, YildiznameProductDistinction.yildiznameLive);
      expect(mod.title, 'Yıldızname');
    });

    test('astrology is a separate feature id', () {
      expect(OraclyFeatureId.astrology, isNot(OraclyFeatureId.starMap));
      final astro = OraclyFeatureRegistry.byId(OraclyFeatureId.astrology);
      final stars = OraclyFeatureRegistry.byId(OraclyFeatureId.starMap);
      expect(astro, isNotNull);
      expect(stars, isNotNull);
      expect(astro!.id, isNot(stars!.id));
      expect(astro.routeName, OraclyRoutes.astrology);
      expect(YildiznameProductDistinction.astrologySeparate, isTrue);
    });
  });
}
