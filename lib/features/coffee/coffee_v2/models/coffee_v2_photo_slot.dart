/// The three locked Coffee V2 photo slots. Strongly typed on purpose — a
/// slot is never represented as an arbitrary user-provided string anywhere
/// in the client; only [wireValue] ever touches JSON, and only with the
/// exact three values the backend's `COFFEE_V2_SLOTS` already recognizes.
library;

enum CoffeeV2PhotoSlot { cupPrimary, cupSecondary, saucer }

extension CoffeeV2PhotoSlotWire on CoffeeV2PhotoSlot {
  String get wireValue => switch (this) {
        CoffeeV2PhotoSlot.cupPrimary => 'cup_primary',
        CoffeeV2PhotoSlot.cupSecondary => 'cup_secondary',
        CoffeeV2PhotoSlot.saucer => 'saucer',
      };
}

CoffeeV2PhotoSlot? coffeeV2PhotoSlotFromWire(String? value) => switch (value) {
      'cup_primary' => CoffeeV2PhotoSlot.cupPrimary,
      'cup_secondary' => CoffeeV2PhotoSlot.cupSecondary,
      'saucer' => CoffeeV2PhotoSlot.saucer,
      _ => null,
    };

/// The single source of truth for canonical order — cup_primary before
/// cup_secondary before saucer, everywhere staging/iteration happens.
/// Never storage order, never alphabetical.
const List<CoffeeV2PhotoSlot> coffeeV2CanonicalSlotOrder = [
  CoffeeV2PhotoSlot.cupPrimary,
  CoffeeV2PhotoSlot.cupSecondary,
  CoffeeV2PhotoSlot.saucer,
];
