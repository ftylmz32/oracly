/// Per-slot staging progress once a V3 submission is ACTIVE. The backend's
/// per-slot staging is idempotent and remains the authority.
library;

enum CoffeeV3StageState { notStaged, staged }

String coffeeV3StageStateWire(CoffeeV3StageState state) => switch (state) {
      CoffeeV3StageState.notStaged => 'not_staged',
      CoffeeV3StageState.staged => 'staged',
    };

CoffeeV3StageState coffeeV3StageStateFromWire(String? value) => switch (value) {
      'staged' => CoffeeV3StageState.staged,
      _ => CoffeeV3StageState.notStaged,
    };
