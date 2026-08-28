/// Internal visual lifecycle of one persistent [CardFlightActor].
library;

enum CardFlightPhase {
  onDeck,
  dragging,
  committed,
  extracting,
  centering,
  flipping,
  revealed,
  placing,
  placed,
}
