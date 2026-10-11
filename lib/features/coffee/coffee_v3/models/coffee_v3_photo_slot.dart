/// The three locked Coffee V3 photo slots: TWO genuine views of the cup
/// interior + ONE saucer view (never a fourth photo). Strongly typed,
/// additive and separate from `CoffeeV2PhotoSlot` — V3 never reuses a V2
/// wire value. Only [wireValue] touches JSON, and only with the exact three
/// namespaced values the backend's `COFFEE_V3_STAGED_SLOTS` recognizes.
library;

enum CoffeeV3PhotoSlot { cupViewA, cupViewB, saucer }

extension CoffeeV3PhotoSlotWire on CoffeeV3PhotoSlot {
  String get wireValue => switch (this) {
        CoffeeV3PhotoSlot.cupViewA => 'v3_cup_view_a',
        CoffeeV3PhotoSlot.cupViewB => 'v3_cup_view_b',
        CoffeeV3PhotoSlot.saucer => 'v3_saucer_view',
      };
}

CoffeeV3PhotoSlot? coffeeV3PhotoSlotFromWire(String? value) => switch (value) {
      'v3_cup_view_a' => CoffeeV3PhotoSlot.cupViewA,
      'v3_cup_view_b' => CoffeeV3PhotoSlot.cupViewB,
      'v3_saucer_view' => CoffeeV3PhotoSlot.saucer,
      _ => null,
    };

/// The single source of truth for canonical order everywhere staging /
/// iteration happens. Never storage order, never alphabetical.
const List<CoffeeV3PhotoSlot> coffeeV3CanonicalSlotOrder = [
  CoffeeV3PhotoSlot.cupViewA,
  CoffeeV3PhotoSlot.cupViewB,
  CoffeeV3PhotoSlot.saucer,
];
