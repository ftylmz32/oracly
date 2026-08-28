/// EPIC-015 — Ambient chambers for the living soundscape.
library;

enum OraclySoundChamber {
  home,
  tarot,
  reading,
  silence,
}

enum OraclySoundCue {
  /// Soft primary acknowledgement — never a UI click spam.
  softTap,
  /// Picker / tab / option change.
  selection,
  orbHum,
  /// Soft paper movement — shuffle, cut, draw rise.
  cardSlide,
  /// Card turn during reveal.
  cardFlip,
  /// Quiet single-tone bloom — never a fantasy chime.
  revealTone,
  /// Special ceremonial reveal peak.
  magicalReveal,
  /// Successful reading / analysis complete.
  journeyComplete,
  premiumPurchase,

  /// Legacy alias — same as [softTap].
  buttonTap,
}
