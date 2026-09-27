/// A catalogue image that is itself a feeling (`dream_fear`) is told when
/// the dreamer names that feeling in any form — "korkmadım", "not afraid",
/// "I was scared" — so a reading that honours a stated or negated feeling is
/// never mistaken for an invented image. Mirrored by the backend
/// `dream-client-parity.ts`.
library;

abstract final class DreamStatedFeeling {
  DreamStatedFeeling._();

  static final _fear = RegExp(
    r'(?<!\p{L})(?:kork|dehşet|panik|afraid|unafraid|fear|scared|scary|frighten|terrif|terror|panic|dread)',
    unicode: true,
  );

  static bool tells(String catalogueId, String told) =>
      catalogueId == 'dream_fear' && _fear.hasMatch(told.toLowerCase());
}
