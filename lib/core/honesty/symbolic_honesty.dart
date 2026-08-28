/// Observed / interpreted / possible / unknown — never mixed into certainty.
library;

import '../copy/fortune_voice.dart';
import '../personality/or_core.dart';

abstract final class SymbolicHonesty {
  SymbolicHonesty._();

  static const observed = 'gözlenen';
  static const interpreted = 'yorumlanan';
  static const possible = 'olası';
  static const unknown = 'bilinmeyen';

  /// Prompt overlay — mystical, not prophetic.
  static const prompt =
      'Katmanları karıştırma: gözlenen (fotoğraf, kart, çizgi), '
      'yorumlanan (geleneksel okuma), olası (böyle okunabilir), '
      'bilinmeyen (net değilse söyle). '
      'Önce gördüğünü söyle. Sonra "geleneksel yorumda". '
      '"Kesin haber alacaksın" ve "kesinlikle şu olacak" yok.';

  static String get core => OrCore.epistemic;

  static bool claimsFalseCertainty(String text) =>
      FortuneVoice.claimsCertainty(text);

  static bool isQuietHonesty(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('yasal') ||
        lower.contains('sorumluluk') ||
        lower.contains('garanti etmez') ||
        lower.contains('liability')) {
      return false;
    }
    return lower.contains('sembolik');
  }
}
