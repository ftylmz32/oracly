/// OR-1170 — Central navigation API for the Tarot ritual experience.
library;

import 'package:flutter/material.dart';

import '../presentation/animations/tarot_transition.dart';
import '../presentation/destem/destem_screen.dart';
import '../presentation/screens/card_detail_screen.dart';
import '../presentation/screens/deck_selection_screen.dart';
import '../presentation/screens/premium_tarot_screen.dart';
import '../presentation/screens/reading_history_screen.dart';
import '../presentation/screens/reading_screen.dart';
import '../presentation/screens/shuffle_screen.dart';
import '../presentation/screens/tarot_home_screen.dart';
import '../ritual/screens/tarot_ritual_intention_screen.dart';
import '../ritual/screens/tarot_ritual_spread_screen.dart';
import '../shared/constants/tarot_routes.dart';

/// Central navigation API for the Tarot ritual experience.
abstract final class TarotNavigator {
  TarotNavigator._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case TarotRoutes.home:
        return tarotRitualRoute(page: const TarotHomeScreen(), settings: settings);
      case TarotRoutes.intention:
        return tarotRitualRoute(
          page: const TarotRitualIntentionScreen(),
          settings: settings,
        );
      case TarotRoutes.spreadSelection:
        return tarotRitualRoute(
          page: const TarotRitualSpreadScreen(),
          settings: settings,
        );
      case TarotRoutes.deckSelection:
        return tarotRitualRoute(page: const DeckSelectionScreen(), settings: settings);
      case TarotRoutes.shuffle:
        return tarotRitualRoute(page: const ShuffleScreen(), settings: settings);
      case TarotRoutes.drawMode:
        // Physical draw lives inside continuous ritual host.
        return tarotRitualRoute(page: const ShuffleScreen(), settings: settings);
      case TarotRoutes.cardSelection:
        return tarotRitualRoute(page: const ShuffleScreen(), settings: settings);
      case TarotRoutes.cardReveal:
        return tarotRitualRoute(page: const ShuffleScreen(), settings: settings);
      case TarotRoutes.reading:
        return readingRitualRoute(
          page: const ReadingScreen(),
          settings: settings,
        );
      case TarotRoutes.cardDetail:
        final cardId = settings.arguments is int
            ? settings.arguments! as int
            : 0;
        return cardDetailRoute<void>(cardId: cardId);
      case TarotRoutes.destem:
        return tarotRitualRoute(page: const DestemScreen(), settings: settings);
      case TarotRoutes.history:
        return tarotRitualRoute(page: const ReadingHistoryScreen(), settings: settings);
      case TarotRoutes.premium:
        return premiumScreenRoute(settings: settings);
      default:
        return tarotRitualRoute(page: const TarotHomeScreen(), settings: settings);
    }
  }

  static Future<T?> pushNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    final route = onGenerateRoute(
      RouteSettings(name: routeName, arguments: arguments),
    );
    return Navigator.of(context).push<T>(route as Route<T>);
  }

  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }
}
