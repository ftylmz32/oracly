/// G0 — canonical route matrix: every named route opens its own feature.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/modules/oracly_feature_navigation.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_screen.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_entry_gate.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_screen.dart';
import 'package:oracly_new/features/daily_message/presentation/screens/daily_message_screen.dart';
import 'package:oracly_new/features/daily_rewards/presentation/reference/daily_rewards_reference_screen.dart';
import 'package:oracly_new/features/discovery_journal/presentation/screens/discovery_journal_screen.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_screen.dart';
import 'package:oracly_new/features/favorite_moments/presentation/screens/favorite_moments_screen.dart';
import 'package:oracly_new/features/gems/presentation/reference/gems_reference_screen.dart';
import 'package:oracly_new/features/help/presentation/help_screen.dart';
import 'package:oracly_new/features/insights/presentation/screens/personal_insights_screen.dart';
import 'package:oracly_new/features/my_story/presentation/screens/my_story_screen.dart';
import 'package:oracly_new/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:oracly_new/features/palm/presentation/palm_reference_screen.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_screen.dart';
import 'package:oracly_new/features/tarot/navigation/tarot_module_navigator.dart';
import 'package:oracly_new/features/tarot/presentation/screens/reading_history_screen.dart';
import 'package:oracly_new/screens/about/about_screen.dart';
import 'package:oracly_new/screens/privacy/privacy_screen.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_screen.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';

Widget _page(String? name, {Object? arguments}) {
  final route = OraclyRouteGenerator.onGenerateRoute(
    RouteSettings(name: name, arguments: arguments),
  );
  return (route! as PageRouteBuilder<dynamic>).pageBuilder(
    _UnusedContext(),
    const AlwaysStoppedAnimation<double>(1),
    const AlwaysStoppedAnimation<double>(1),
  );
}

const _validId = '0123456789abcdef0123456789abcdef';

final _matrix = <String, Type>{
  OraclyRoutes.onboarding: OnboardingScreen,
  OraclyRoutes.home: OraclyAppShell,
  OraclyRoutes.tarot: TarotModuleNavigator,
  OraclyRoutes.chat: CompanionReferenceScreen,
  OraclyRoutes.profile: OraclyAppShell,
  OraclyRoutes.settings: SettingsReferenceScreen,
  OraclyRoutes.premium: PremiumReferenceScreen,
  OraclyRoutes.gems: GemsReferenceScreen,
  OraclyRoutes.dailyRewards: DailyRewardsReferenceScreen,
  OraclyRoutes.dailyEnergy: OraclyAppShell,
  OraclyRoutes.dream: DreamReferenceScreen,
  OraclyRoutes.astrology: AstrologyReferenceScreen,
  OraclyRoutes.starMap: StarMapReferenceScreen,
  OraclyRoutes.coffee: CoffeeV2EntryGate,
  OraclyRoutes.palm: PalmReferenceScreen,
  OraclyRoutes.soulMate: SoulMateDrawScreen,
  OraclyRoutes.readingHistory: ReadingHistoryScreen,
  OraclyRoutes.discoveryJournal: DiscoveryJournalScreen,
  OraclyRoutes.myStory: MyStoryScreen,
  OraclyRoutes.favoriteMoments: FavoriteMomentsScreen,
  OraclyRoutes.personalInsights: PersonalInsightsScreen,
  OraclyRoutes.dailyMessage: DailyMessageScreen,
  OraclyRoutes.achievements: OraclyAppShell,
  OraclyRoutes.numerology: OraclyAppShell,
  OraclyRoutes.moonCalendar: OraclyAppShell,
  OraclyRoutes.manifestation: OraclyAppShell,
  OraclyRoutes.about: AboutScreen,
  OraclyRoutes.help: HelpScreen,
  OraclyRoutes.privacy: PrivacyScreen,
  OraclyRoutes.share: OraclyAppShell,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(AccountDeletionPendingState.markClear);

  test('every named route resolves to its canonical destination', () {
    for (final entry in _matrix.entries) {
      expect(_page(entry.key).runtimeType, entry.value, reason: entry.key);
    }
    final profile = _page(OraclyRoutes.profile) as OraclyAppShell;
    expect(profile.initialTab, OraclyTab.profile);
  });

  test('registry truth: 16 live, 4 reserved, 0 preview', () {
    final live = OraclyFeatureRegistry.live.map((m) => m.id.name).toSet();
    final reserved =
        OraclyFeatureRegistry.reserved.map((m) => m.id.name).toSet();
    expect(live, {
      'tarot', 'coffee', 'palm', 'soulMate', 'aiChat', 'dailyEnergy', //
      'dream', 'astrology', 'starMap', 'readingHistory', 'discoveryJournal',
      'dailyMessage', 'personalInsights', 'memory', 'premium', 'settings',
    });
    expect(reserved, {'achievements', 'numerology', 'moonCalendar', //
        'manifestation'});
    expect(OraclyFeatureRegistry.preview, isEmpty);
  });

  test('live registry routes never open another feature or the shell', () {
    for (final m in OraclyFeatureRegistry.live) {
      final route = m.routeName;
      if (route == null || route == OraclyRoutes.dailyEnergy) continue;
      expect(_matrix[route], isNot(OraclyAppShell), reason: m.id.name);
      expect(_page(route).runtimeType, _matrix[route], reason: m.id.name);
    }
    expect(_page(OraclyRoutes.coffee), isNot(isA<TarotModuleNavigator>()));
    expect(_page(OraclyRoutes.starMap), isNot(isA<AstrologyReferenceScreen>()));
  });

  test('reserved modules are not navigable and recover to the shell', () {
    for (final m in OraclyFeatureRegistry.reserved) {
      expect(OraclyFeatureNavigation.canOpen(m.id), isFalse, reason: m.id.name);
      expect(_page(m.routeName), isA<OraclyAppShell>(), reason: m.id.name);
    }
  });

  test('unknown / malformed names recover without throwing', () {
    for (final name in [
      null, '', '/', '/unknown', '/%%%', '/tarot/../premium', //
      '/${'x' * 4096}', '/share/not-a-token', '/s/', 'oracly://open/x',
    ]) {
      expect(_page(name), isA<OraclyAppShell>(), reason: '$name');
    }
  });

  group('reading operation ids on /coffee /palm /soul-mate', () {
    String? idOf(Widget w) => switch (w) {
          CoffeeV2EntryGate(:final operationId) => operationId,
          PalmReferenceScreen(:final operationId) => operationId,
          SoulMateDrawScreen(:final operationId) => operationId,
          _ => throw StateError('unexpected $w'),
        };
    const routes = [
      OraclyRoutes.coffee, OraclyRoutes.palm, OraclyRoutes.soulMate, //
    ];

    test('32-char lowercase hex accepted (trimmed)', () {
      for (final r in routes) {
        expect(idOf(_page(r, arguments: {'operationId': _validId})), _validId);
        expect(
          idOf(_page(r, arguments: {'operationId': '  $_validId\n'})),
          _validId,
        );
      }
    });

    test('invalid, wrong-type and oversized ids are ignored', () {
      final bad = <Object?>[
        null, _validId, {'operationId': _validId.toUpperCase()}, //
        {'operationId': _validId.substring(1)}, {'operationId': '${_validId}0'},
        {'operationId': 42}, {'operationId': [_validId]}, {'id': _validId},
        {'operationId': 'g' * 32}, {'operationId': _validId * 400},
        {'operationId': '$_validId;DROP'}, ['operationId', _validId],
      ];
      for (final r in routes) {
        for (final args in bad) {
          expect(idOf(_page(r, arguments: args)), isNull, reason: '$r $args');
        }
      }
    });
  });
}

class _UnusedContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
