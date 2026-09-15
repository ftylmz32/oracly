/// Proves the app's typography resolves deterministically. `Inter` and
/// `Cormorant Garamond` are the DESIGNED identity (see app_typography.dart)
/// but neither is bundled as an app asset -- no pubspec `fonts:` entry, no
/// font file anywhere in the repo. A `fontFamily` string that never
/// resolves falls through Flutter's undocumented "unresolved family"
/// substitution; `null` falls through the well-defined "no family
/// requested" default (Flutter's own bundled Roboto, same on every
/// platform) instead. This file proves that path is what's actually wired,
/// and that real Turkish characters still render through it without error.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/design_system/app_typography.dart';
import 'package:oracly_new/core/theme/app_theme.dart';

void main() {
  group('font resolution is deterministic, not an unresolved-name fallback', () {
    test('AppTypography/AppTextStyles request no unbundled font family', () {
      expect(AppTypography.displayFontFamily, isNull);
      expect(AppTypography.bodyFontFamily, isNull);
      expect(AppTextStyles.displayFontFamily, isNull);
      expect(AppTextStyles.bodyFontFamily, isNull);
    });

    test('every built-in typography preset carries no dangling font family', () {
      final presets = <TextStyle>[
        AppTypography.displayXl,
        AppTypography.displayL,
        AppTypography.headingXl,
        AppTypography.headingL,
        AppTypography.headingM,
        AppTypography.title,
        AppTypography.body,
        AppTypography.caption,
        AppTypography.button,
      ];
      for (final style in presets) {
        expect(style.fontFamily, isNull);
      }
    });

    test(
      'the compiled ThemeData resolves to Roboto -- Flutter\'s own bundled '
      'Material default, engine-shipped on every platform -- never a '
      'dangling reference to an unbundled "Inter"/"Cormorant Garamond"',
      () {
        for (final theme in [AppTheme.dark, AppTheme.light]) {
          final resolved = [
            theme.textTheme.displayLarge,
            theme.textTheme.headlineLarge,
            theme.textTheme.headlineMedium,
            theme.textTheme.titleLarge,
            theme.textTheme.bodyLarge,
            theme.textTheme.bodyMedium,
            theme.textTheme.labelLarge,
          ];
          for (final style in resolved) {
            expect(style?.fontFamily, 'Roboto');
          }
        }
      },
    );

    testWidgets(
      'Turkish characters render through the real theme without error, at all 3 required widths',
      (tester) async {
        const turkish = 'Ğğ Şş İı Çç Öö Üü — Falın hazırlanıyor, lütfen bekleyin.';
        for (final size in [
          const Size(320, 568),
          const Size(360, 800),
          const Size(390, 844),
        ]) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark,
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: const Scaffold(
                  body: Center(
                    child: Text(turkish, style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text(turkish), findsOneWidget);
        }
        await tester.binding.setSurfaceSize(null);
      },
    );
  });
}
