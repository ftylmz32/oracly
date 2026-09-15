/// Per-slot staging progress against the backend, once a submission has
/// become ACTIVE (an operation exists). Two states only — there is no
/// client-authoritative "confirmed staged forever" beyond this, because the
/// backend's per-slot staging is idempotent and remains the authority.
library;

enum CoffeeV2StageState { notStaged, staged }

String coffeeV2StageStateWire(CoffeeV2StageState state) => switch (state) {
      CoffeeV2StageState.notStaged => 'not_staged',
      CoffeeV2StageState.staged => 'staged',
    };

CoffeeV2StageState coffeeV2StageStateFromWire(String? value) => switch (value) {
      'staged' => CoffeeV2StageState.staged,
      _ => CoffeeV2StageState.notStaged,
    };
