/// Face information density — full hero vs compact settled overview.
library;

/// Settled multi-card overview uses [compact]; flight / reveal / hero use [full].
enum TarotCardFaceDensity {
  /// 132×222-class: scene art + numeral/title plaques + full shell chrome.
  full,

  /// ~40–70px settled overview: scene art dominant; no internal title plaques.
  /// Outer spread-position label lives on the slot tile, not on the face.
  compact,
}
