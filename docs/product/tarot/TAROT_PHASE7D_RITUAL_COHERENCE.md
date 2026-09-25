# TAROT Phase 7D — Ritual / Table / Reveal Coherence + Performance

**Start HEAD:** `efa981a47c1a0a22a6c9dee63fddf56469df2919`

## Defects fixed

1. **Multi-card double representation** — `showFlight` stayed true in
   `TarotTablePhase.reading`, so the final settled card and CardFlightActor
   both showed the same face. Ownership is now
   `TarotTableActorOwnership.ownsActiveCard` (slots own all faces when
   `placedCount >= cardCount` for multi-card).

2. **Reduced-motion final divergence** — reduced path used
   `placeTarget ?? Offset(0, -120)`. Normal flight ends at
   `CardFlightMath.singleSettledOffset` `(0, -36)`. Reduced motion now uses
   `CardFlightMath.settledOffset` and sets `flight.value = 1` so the face shows.

3. **Deck atmosphere GPU** — removed 3× `ImageFiltered` blur passes from
   `TarotDeckTableAtmosphere`; replaced with RadialGradient + BoxShadow.

## Firewalls

7C / 7C.1 geometry frozen · Crossroads hidden · Phase 6 untouched · no 7E.
