import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_navigation.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/core/navigation/universe/oracly_tab_labels.dart';
import 'package:oracly_new/core/navigation/universe/oracly_universe_realm.dart';
import 'package:oracly_new/core/navigation/universe/universe_navigation_copy.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';

void main() {
  group('Universe navigation structure', () {
    test('tabs use universe space labels not generic app labels', () {
      expect(OraclyTab.home.universeLabel, UniverseNavigationCopy.tabUniverse);
      expect(OraclyTab.tarot.universeLabel, UniverseNavigationCopy.tabRitual);
      expect(OraclyTab.chat.universeLabel, UniverseNavigationCopy.tabReflect);
      expect(OraclyTab.profile.universeLabel, UniverseNavigationCopy.tabJourney);
    });

    test('every live module belongs to a universe realm', () {
      for (final module in OraclyFeatureRegistry.live) {
        expect(
          module.universeRealm,
          isNotNull,
          reason: '${module.id} should declare a realm',
        );
      }
    });

    test('reflect realm includes companion and insights', () {
      final reflect = OraclyFeatureRegistry.forRealm(OraclyUniverseRealm.reflect);
      expect(reflect.map((m) => m.id), contains(OraclyFeatureId.aiChat));
      expect(reflect.map((m) => m.id), contains(OraclyFeatureId.personalInsights));
    });

    test('feature navigation can open memory and insights', () {
      expect(OraclyFeatureNavigation.canOpen(OraclyFeatureId.memory), isTrue);
      expect(
        OraclyFeatureNavigation.canOpen(OraclyFeatureId.personalInsights),
        isTrue,
      );
    });
  });
}
