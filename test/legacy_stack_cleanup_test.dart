/// Legacy stack cleanup — unreachable shells stay out of live routes.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_screen.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_screen.dart';

void main() {
  test('deleted legacy screen files stay gone', () {
    const removed = [
      'lib/features/premium/presentation/screens/premium_screen.dart',
      'lib/screens/home/home_screen.dart',
      'lib/features/home/home_view.dart',
      'lib/screens/settings/settings_screen.dart',
      'lib/screens/history/history_screen.dart',
      'lib/features/astrology/presentation/screens/astrology_screen.dart',
      'lib/features/dream/presentation/screens/dream_screen.dart',
      'lib/features/star_map/presentation/screens/star_map_screen.dart',
      'lib/screens/profile/profile_screen.dart',
    ];
    for (final path in removed) {
      expect(File(path).existsSync(), isFalse, reason: path);
    }
  });

  test('live OR/Premium/Profile shells remain present', () {
    expect(
      File('lib/features/companion/presentation/reference/companion_reference_screen.dart')
          .existsSync(),
      isTrue,
    );
    expect(
      File('lib/features/premium/presentation/reference/premium_reference_screen.dart')
          .existsSync(),
      isTrue,
    );
    expect(
      File('lib/screens/profile/reference/profile_reference_screen.dart')
          .existsSync(),
      isTrue,
    );
    expect(CompanionReferenceScreen, CompanionReferenceScreen);
    expect(PremiumReferenceScreen, PremiumReferenceScreen);
    expect(ProfileReferenceScreen, ProfileReferenceScreen);
  });

  test('named chat and premium routes still generate', () {
    expect(
      OraclyRouteGenerator.onGenerateRoute(
        const RouteSettings(name: OraclyRoutes.chat),
      ),
      isNotNull,
    );
    expect(
      OraclyRouteGenerator.onGenerateRoute(
        const RouteSettings(name: OraclyRoutes.premium),
      ),
      isNotNull,
    );
    expect(
      OraclyRouteGenerator.onGenerateRoute(
        const RouteSettings(name: OraclyRoutes.profile),
      ),
      isNotNull,
    );
  });
}
