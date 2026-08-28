import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation_scope.dart';
import 'package:oracly_new/shared/navigation/oracly_shell_bridge.dart';
import 'package:oracly_new/shared/navigation/oracly_tab_navigator.dart';

void main() {
  group('OraclyShellBridge', () {
    test('requestTab returns false when no shell is bound', () {
      expect(OraclyShellBridge.requestTab(OraclyTab.profile), isFalse);
    });

    test('requestTab reaches the live shell switcher', () {
      OraclyTab? switched;
      void switcher(OraclyTab tab) => switched = tab;
      OraclyShellBridge.bind(switcher);
      addTearDown(() => OraclyShellBridge.unbind(switcher));
      expect(OraclyShellBridge.requestTab(OraclyTab.coffee), isTrue);
      expect(switched, OraclyTab.coffee);
    });

    test('unbind ignores a stale switcher identity', () {
      OraclyTab? switched;
      void live(OraclyTab tab) => switched = tab;
      void stale(OraclyTab tab) => switched = OraclyTab.home;
      OraclyShellBridge.bind(live);
      addTearDown(() => OraclyShellBridge.unbind(live));
      OraclyShellBridge.unbind(stale);
      expect(OraclyShellBridge.requestTab(OraclyTab.astrology), isTrue);
      expect(switched, OraclyTab.astrology);
    });
  });

  group('Tab navigator shell routes', () {
    test('shell roots stay blocked from nested tab stacks', () {
      expect(
        OraclyTabNavigator.blockedShellRoutes,
        containsAll(<String>{
          OraclyRoutes.home,
          OraclyRoutes.profile,
          OraclyRoutes.coffee,
          OraclyRoutes.astrology,
          OraclyRoutes.starMap,
          OraclyRoutes.onboarding,
        }),
      );
      expect(
        OraclyTabNavigator.blockedShellRoutes.contains(OraclyRoutes.chat),
        isFalse,
      );
      expect(
        OraclyTabNavigator.blockedShellRoutes.contains(OraclyRoutes.tarot),
        isFalse,
      );
      expect(
        OraclyTabNavigator.blockedShellRoutes.contains(OraclyRoutes.palm),
        isFalse,
      );
    });
  });
}
