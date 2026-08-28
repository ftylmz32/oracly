/// Canonical SoulMate entry — cinematic gentle chamber enter.
library;

import 'package:flutter/material.dart';

import '../../../core/navigation/immersive/chamber_transition_personality.dart';
import '../../../core/navigation/oracly_page_transitions.dart';
import '../presentation/screens/soul_mate_draw_screen.dart';

abstract final class SoulMateNavigation {
  SoulMateNavigation._();

  /// Stack identity only — not a registered app route.
  static const _stackName = 'soulMateDraw';

  static void open(BuildContext context) {
    if (_isTop(context)) return;
    Navigator.of(context).push(
      OraclyPageTransitions.chamber<void>(
        personality: ChamberTransitionPersonality.soulMate,
        page: const SoulMateDrawScreen(),
        settings: const RouteSettings(name: _stackName),
      ),
    );
  }

  static bool _isTop(BuildContext context) {
    Route<dynamic>? top;
    Navigator.of(context).popUntil((route) {
      top = route;
      return true;
    });
    return top?.settings.name == _stackName;
  }
}
