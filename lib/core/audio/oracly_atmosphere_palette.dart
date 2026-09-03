/// Symbolic burç atmospheres — procedural loops, not astrology claims.
library;

import '../../features/birth_chart/models/zodiac_sign_id.dart';

/// Soft frequency triads for [ZodiacSignId] ambient beds.
abstract final class OraclyAtmospherePalette {
  OraclyAtmospherePalette._();

  /// Player target after fade-in — quiet bed, never an intro sting.
  /// Kept high enough to be audible on phone speakers with [bedVolume].
  static const double volume = 0.28;

  /// Synth peak amplitude before player gain (PCM −1…1 scale).
  static const double bedVolume = 0.42;

  static List<double> frequencies(ZodiacSignId sign) => switch (sign) {
        // Koç — warm / energetic
        ZodiacSignId.aries => const [130.8, 164.8, 196.0],
        // Boğa — grounded / warm
        ZodiacSignId.taurus => const [87.3, 110.0, 146.8],
        // İkizler — light / airy
        ZodiacSignId.gemini => const [146.8, 220.0, 293.7],
        // Yengeç — moonlit / soft
        ZodiacSignId.cancer => const [98.0, 123.5, 174.6],
        // Aslan — majestic / golden
        ZodiacSignId.leo => const [110.0, 164.8, 220.0],
        // Başak — minimal / clean
        ZodiacSignId.virgo => const [123.5, 185.0],
        // Terazi — elegant / balanced
        ZodiacSignId.libra => const [130.8, 196.0, 261.6],
        // Akrep — deep / dark
        ZodiacSignId.scorpio => const [73.4, 98.0, 146.8],
        // Yay — spacious / adventurous
        ZodiacSignId.sagittarius => const [98.0, 146.8, 233.1],
        // Oğlak — restrained / grounded
        ZodiacSignId.capricorn => const [82.4, 110.0, 164.8],
        // Kova — ethereal / futuristic
        ZodiacSignId.aquarius => const [138.6, 207.7, 277.2],
        // Balık — dreamy / oceanic
        ZodiacSignId.pisces => const [92.5, 138.6, 185.0],
      };

  static ZodiacSignId parse(String? raw) {
    if (raw == null || raw.isEmpty) return ZodiacSignId.cancer;
    for (final sign in ZodiacSignId.values) {
      if (sign.name == raw) return sign;
    }
    return ZodiacSignId.cancer;
  }
}
