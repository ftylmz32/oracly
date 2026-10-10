/// The four locked Coffee V3 photo slots. Strongly typed, additive and
/// separate from `CoffeeV2PhotoSlot` — V3 never reuses a V2 wire value. Only
/// [wireValue] touches JSON, and only with the exact four namespaced values
/// the backend's `COFFEE_V3_STAGED_SLOTS` recognizes.
library;

enum CoffeeV3PhotoSlot { cupHandleFar, cupTurnA, cupTurnB, saucer }

extension CoffeeV3PhotoSlotWire on CoffeeV3PhotoSlot {
  String get wireValue => switch (this) {
        CoffeeV3PhotoSlot.cupHandleFar => 'v3_cup_handle_far',
        CoffeeV3PhotoSlot.cupTurnA => 'v3_cup_turn_a',
        CoffeeV3PhotoSlot.cupTurnB => 'v3_cup_turn_b',
        CoffeeV3PhotoSlot.saucer => 'v3_saucer',
      };
}

CoffeeV3PhotoSlot? coffeeV3PhotoSlotFromWire(String? value) => switch (value) {
      'v3_cup_handle_far' => CoffeeV3PhotoSlot.cupHandleFar,
      'v3_cup_turn_a' => CoffeeV3PhotoSlot.cupTurnA,
      'v3_cup_turn_b' => CoffeeV3PhotoSlot.cupTurnB,
      'v3_saucer' => CoffeeV3PhotoSlot.saucer,
      _ => null,
    };

/// The single source of truth for canonical order everywhere staging /
/// iteration happens. Never storage order, never alphabetical.
const List<CoffeeV3PhotoSlot> coffeeV3CanonicalSlotOrder = [
  CoffeeV3PhotoSlot.cupHandleFar,
  CoffeeV3PhotoSlot.cupTurnA,
  CoffeeV3PhotoSlot.cupTurnB,
  CoffeeV3PhotoSlot.saucer,
];
