/// Generous abuse windows — block spam, never a normal reading.
library;

enum AiRequestKind {
  chat,
  oracle,
  dream,
  coffee,
  palm,
  tarot,
  soulmate,
  tts,
}

class AiAbuseLimits {
  const AiAbuseLimits({
    required this.duplicate,
    required this.burstMax,
    required this.burstWindow,
  });

  final Duration duplicate;
  final int burstMax;
  final Duration burstWindow;
}

abstract final class AiRequestAbusePolicy {
  AiRequestAbusePolicy._();

  static const chat = AiAbuseLimits(
    duplicate: Duration(milliseconds: 700),
    burstMax: 28,
    burstWindow: Duration(seconds: 60),
  );

  static const vision = AiAbuseLimits(
    duplicate: Duration(seconds: 4),
    burstMax: 6,
    burstWindow: Duration(seconds: 60),
  );

  static const ritual = AiAbuseLimits(
    duplicate: Duration(seconds: 3),
    burstMax: 8,
    burstWindow: Duration(seconds: 60),
  );

  static const soulmate = AiAbuseLimits(
    duplicate: Duration(seconds: 8),
    burstMax: 4,
    burstWindow: Duration(seconds: 60),
  );

  static const tts = AiAbuseLimits(
    duplicate: Duration(milliseconds: 1200),
    burstMax: 16,
    burstWindow: Duration(seconds: 60),
  );

  static AiAbuseLimits of(AiRequestKind kind) => switch (kind) {
        AiRequestKind.chat || AiRequestKind.oracle => chat,
        AiRequestKind.coffee || AiRequestKind.palm => vision,
        AiRequestKind.dream || AiRequestKind.tarot => ritual,
        AiRequestKind.soulmate => soulmate,
        AiRequestKind.tts => tts,
      };

  static bool isPaid(AiRequestKind kind) =>
      kind == AiRequestKind.soulmate ||
      kind == AiRequestKind.coffee ||
      kind == AiRequestKind.palm ||
      kind == AiRequestKind.tarot;
}
