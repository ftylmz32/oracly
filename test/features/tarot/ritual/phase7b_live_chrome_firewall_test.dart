/// Phase 7B — live Tarot chrome import firewall (source-level).
///
/// Proves the canonical home → table spine does not depend on dead chrome.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/theme/app_colors.dart';
import 'package:oracly_new/features/tarot/presentation/screens/tarot_home_screen.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_background.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_scene.dart';
import 'package:oracly_new/features/tarot/ritual/widgets/ritual_card_shell.dart';
import 'package:oracly_new/features/tarot/theme/tarot_tokens.dart';

String _read(String relative) =>
    File(relative.replaceAll('/', Platform.pathSeparator)).readAsStringSync();

void main() {
  group('Phase 7B live chrome ownership', () {
    test('TarotHomeScreen resolves to TarotTableScene only', () {
      final src = _read(
        'lib/features/tarot/presentation/screens/tarot_home_screen.dart',
      );
      expect(src, contains('TarotTableScene'));
      expect(src, isNot(contains('TarotBackground')));
      expect(src, isNot(contains('TarotScreenShell')));
      expect(src, isNot(contains('CardRevealScreen')));
      expect(src, isNot(contains('narrative/shadow')));
    });

    test('TarotTableScene owns TarotTableBackground, not dead chrome', () {
      final src = _read(
        'lib/features/tarot/ritual/table/tarot_table_scene.dart',
      );
      expect(src, contains('TarotTableBackground'));
      expect(src, contains('TarotTokens.tableVoid'));
      // Ban live imports of dead stacks (comments may name them).
      expect(src.contains('tarot_background.dart'), isFalse);
      expect(src.contains('tarot_screen_shell.dart'), isFalse);
      expect(src.contains('tarot_cinematic_background'), isFalse);
      expect(src.contains('tarot_glass_card'), isFalse);
      expect(src.contains('card_reveal_screen'), isFalse);
      expect(src.contains('narrative/shadow'), isFalse);
    });

    test('runtime types resolve for canonical chrome', () {
      expect(const TarotHomeScreen(), isA<TarotHomeScreen>());
      expect(const TarotTableScene(), isA<TarotTableScene>());
      expect(const TarotTableBackground(), isA<TarotTableBackground>());
    });

    test('ritual card physicality matches TarotTokens', () {
      expect(RitualCardMetrics.width, TarotTokens.ritualCardWidth);
      expect(RitualCardMetrics.height, TarotTokens.ritualCardHeight);
      expect(RitualCardMetrics.radius, TarotTokens.ritualCardRadius);
      expect(TarotTokens.ritualCardAspectRatio, closeTo(132 / 222, 0.0001));
      expect(TarotTokens.tableCandleWarm, AppColors.gold);
    });

    test('table background source stays static (no ambient loop)', () {
      final bg = _read(
        'lib/features/tarot/ritual/table/tarot_table_background.dart',
      );
      final layers = _read(
        'lib/features/tarot/ritual/table/tarot_table_background_layers.dart',
      );
      expect(bg + layers, isNot(contains('AnimationController')));
      expect(bg + layers, isNot(contains('TickerProvider')));
      expect(layers, contains('shouldRepaint'));
      expect(layers, contains('=> false'));
      expect(bg + layers, isNot(contains('BackdropFilter')));
      expect(bg + layers, isNot(contains('ImageFilter')));
    });
  });
}
