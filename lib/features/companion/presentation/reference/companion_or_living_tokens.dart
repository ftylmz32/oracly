/// Living OR motion — slow, light, never cartoon.
library;

/// Single place for OR emblem timing. One ticker family — TECNO-safe.
abstract final class CompanionOrLivingTokens {
  CompanionOrLivingTokens._();

  static const Duration idleBreath = Duration(milliseconds: 7200);
  static const Duration speakingPulse = Duration(milliseconds: 2400);
  static const Duration thinkingOrbit = Duration(milliseconds: 4200);
  static const Duration atmosphereDrift = Duration(milliseconds: 9800);

  static const Duration entryEmblem = Duration(milliseconds: 480);
  static const Duration entryTextDelay = Duration(milliseconds: 160);
  static const Duration entryText = Duration(milliseconds: 420);

  /// Voice mode only — small presence, subtle rhythm. Never a stage light.
  static const double speakingGlowMin = 0.04;
  static const double speakingGlowSpan = 0.028;
  static const double thinkingGlowMin = 0.07;
  static const double thinkingGlowSpan = 0.04;
  static const double idleGlowMin = 0.03;
  static const double idleGlowSpan = 0.035;
}
